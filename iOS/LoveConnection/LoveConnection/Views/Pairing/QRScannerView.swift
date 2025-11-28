import SwiftUI
import AVFoundation
import Combine

struct QRScannerView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var appState: AppState
    @StateObject private var scanner = QRScanner()
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            ZStack {
                QRScannerPreview(scanner: scanner)
                    .ignoresSafeArea()

                VStack {
                    Spacer()

                    VStack(spacing: 16) {
                        Text("Position QR code within the frame")
                            .foregroundColor(.white)
                            .padding()
                            .background(.ultraThinMaterial)
                            .cornerRadius(12)

                        if let errorMessage = errorMessage {
                            Text(errorMessage)
                                .foregroundColor(.red)
                                .padding()
                                .background(.ultraThinMaterial)
                                .cornerRadius(12)
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("Scan QR Code")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .onAppear {
                scanner.startScanning()
            }
            .onDisappear {
                scanner.stopScanning()
            }
            .onChange(of: scanner.scannedCode) { code in
                if let code = code {
                    handleScannedCode(code)
                }
            }
        }
    }

    private func handleScannedCode(_ code: String) {
        Task {
            do {
                _ = try await APIService.shared.createPairRequest(qrCode: code)
                errorMessage = nil
                dismiss()
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }
}

class QRScanner: NSObject, ObservableObject, AVCaptureMetadataOutputObjectsDelegate {
    @Published var scannedCode: String?

    var captureSession: AVCaptureSession?
    private let sessionQueue = DispatchQueue(label: "com.loveconnection.captureSession")
    private var isSessionRunning = false

    func startScanning() {
        guard captureSession == nil else {
            if !isSessionRunning {
                sessionQueue.async { [weak self] in
                    self?.captureSession?.startRunning()
                    self?.isSessionRunning = true
                }
            }
            return
        }

        AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
            guard granted else {
                DispatchQueue.main.async {
                    print("Camera access denied")
                }
                return
            }

            self?.sessionQueue.async {
                self?.setupCaptureSession()
            }
        }
    }

    private func setupCaptureSession() {
        guard let videoCaptureDevice = AVCaptureDevice.default(for: .video) else {
            print("No video capture device available")
            return
        }

        let videoInput: AVCaptureDeviceInput

        do {
            videoInput = try AVCaptureDeviceInput(device: videoCaptureDevice)
        } catch {
            print("Failed to create video input: \(error)")
            return
        }

        let captureSession = AVCaptureSession()
        captureSession.beginConfiguration()
        captureSession.sessionPreset = .high

        if captureSession.canAddInput(videoInput) {
            captureSession.addInput(videoInput)
        } else {
            print("Cannot add video input")
            captureSession.commitConfiguration()
            return
        }

        let metadataOutput = AVCaptureMetadataOutput()

        if captureSession.canAddOutput(metadataOutput) {
            captureSession.addOutput(metadataOutput)

            metadataOutput.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
            metadataOutput.metadataObjectTypes = [.qr]
        } else {
            print("Cannot add metadata output")
            captureSession.commitConfiguration()
            return
        }

        captureSession.commitConfiguration()

        DispatchQueue.main.async { [weak self] in
            self?.captureSession = captureSession
        }

        captureSession.startRunning()
        isSessionRunning = true
    }

    func stopScanning() {
        sessionQueue.async { [weak self] in
            guard let captureSession = self?.captureSession else { return }
            if captureSession.isRunning {
                captureSession.stopRunning()
                self?.isSessionRunning = false
            }
        }
    }

    func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
        if let metadataObject = metadataObjects.first {
            guard let readableObject = metadataObject as? AVMetadataMachineReadableCodeObject,
                  let stringValue = readableObject.stringValue else { return }

            scannedCode = stringValue
        }
    }
}

struct QRScannerPreview: UIViewControllerRepresentable {
    let scanner: QRScanner

    func makeUIViewController(context: Context) -> PreviewViewController {
        let viewController = PreviewViewController()
        viewController.scanner = scanner
        return viewController
    }

    func updateUIViewController(_ uiViewController: PreviewViewController, context: Context) {
        uiViewController.updatePreviewLayer()
    }
}

class PreviewViewController: UIViewController {
    var scanner: QRScanner?
    private var previewLayer: AVCaptureVideoPreviewLayer?

    override func viewDidLoad() {
        super.viewDidLoad()
        setupPreviewLayer()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        previewLayer?.frame = view.bounds
    }

    private func setupPreviewLayer() {
        guard previewLayer == nil else { return }

        let layer = AVCaptureVideoPreviewLayer()
        layer.videoGravity = .resizeAspectFill
        view.layer.addSublayer(layer)
        previewLayer = layer

        updatePreviewLayer()
    }

    func updatePreviewLayer() {
        guard let previewLayer = previewLayer else { return }

        if let captureSession = scanner?.captureSession {
            if previewLayer.session == nil {
                previewLayer.session = captureSession
            } else if previewLayer.session !== captureSession {
                previewLayer.session = captureSession
            }
        }

        if previewLayer.frame != view.bounds {
            previewLayer.frame = view.bounds
        }
    }
}

