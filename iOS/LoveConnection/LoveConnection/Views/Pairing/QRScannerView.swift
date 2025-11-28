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
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    scanner.stopScanning()
                }
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
        print("📷 QRScanner: startScanning() called")

        guard captureSession == nil else {
            print("📷 QRScanner: Session already exists, checking if running...")
            if !isSessionRunning {
                print("📷 QRScanner: Starting existing session")
                sessionQueue.async { [weak self] in
                    guard let self = self, let session = self.captureSession else {
                        print("❌ QRScanner: Session is nil")
                        return
                    }
                    print("📷 QRScanner: Starting session on background queue")
                    if !session.isRunning {
                        session.startRunning()
                        self.isSessionRunning = true
                        print("✅ QRScanner: Session started")
                    } else {
                        print("⚠️ QRScanner: Session already running")
                    }
                }
            } else {
                print("📷 QRScanner: Session already running")
            }
            return
        }

        print("📷 QRScanner: Requesting camera access...")
        AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
            if granted {
                print("✅ QRScanner: Camera access granted")
            } else {
                print("❌ QRScanner: Camera access denied")
            }

            guard granted else {
                DispatchQueue.main.async {
                    print("❌ QRScanner: Camera access denied")
                }
                return
            }

            self?.sessionQueue.async {
                print("📷 QRScanner: Setting up capture session on background queue")
                self?.setupCaptureSession()
            }
        }
    }

    private func setupCaptureSession() {
        print("📷 QRScanner: setupCaptureSession() started")

        guard let videoCaptureDevice = AVCaptureDevice.default(for: .video) else {
            print("❌ QRScanner: No video capture device available")
            return
        }
        print("✅ QRScanner: Video capture device found: \(videoCaptureDevice.localizedName)")

        let videoInput: AVCaptureDeviceInput

        do {
            videoInput = try AVCaptureDeviceInput(device: videoCaptureDevice)
            print("✅ QRScanner: Video input created")
        } catch {
            print("❌ QRScanner: Failed to create video input: \(error)")
            return
        }

        let captureSession = AVCaptureSession()
        print("📷 QRScanner: AVCaptureSession created")

        guard captureSession.canSetSessionPreset(.high) else {
            print("❌ QRScanner: Cannot set session preset to .high")
            return
        }
        print("✅ QRScanner: Can set session preset to .high")

        print("📷 QRScanner: Beginning configuration...")
        captureSession.beginConfiguration()
        captureSession.sessionPreset = .high
        print("✅ QRScanner: Session preset set to .high")

        guard captureSession.canAddInput(videoInput) else {
            print("❌ QRScanner: Cannot add video input")
            captureSession.commitConfiguration()
            return
        }
        captureSession.addInput(videoInput)
        print("✅ QRScanner: Video input added")

        let metadataOutput = AVCaptureMetadataOutput()

        guard captureSession.canAddOutput(metadataOutput) else {
            print("❌ QRScanner: Cannot add metadata output")
            captureSession.commitConfiguration()
            return
        }
        captureSession.addOutput(metadataOutput)
        print("✅ QRScanner: Metadata output added")

        print("📷 QRScanner: Committing configuration...")
        captureSession.commitConfiguration()
        print("✅ QRScanner: Configuration committed")

        metadataOutput.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
        metadataOutput.metadataObjectTypes = [.qr]
        print("✅ QRScanner: Metadata output configured for QR codes")

        self.captureSession = captureSession
        print("✅ QRScanner: Capture session stored")

        DispatchQueue.main.async { [weak self] in
            print("📷 QRScanner: Posting CaptureSessionReady notification")
            NotificationCenter.default.post(name: NSNotification.Name("CaptureSessionReady"), object: self?.captureSession)
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
            guard let self = self, let session = self.captureSession else {
                print("❌ QRScanner: Session is nil when trying to start")
                return
            }
            print("📷 QRScanner: Starting session after delay...")
            self.sessionQueue.async {
                if !session.isRunning {
                    print("📷 QRScanner: Calling startRunning() on background queue")
                    session.startRunning()
                    self.isSessionRunning = true
                    print("✅ QRScanner: Session started successfully, isRunning: \(session.isRunning)")
                } else {
                    print("⚠️ QRScanner: Session already running")
                }
            }
        }
    }

    func stopScanning() {
        print("📷 QRScanner: stopScanning() called")
        
        DispatchQueue.main.async { [weak self] in
            print("📷 QRScanner: Posting CaptureSessionStopping notification")
            NotificationCenter.default.post(name: NSNotification.Name("CaptureSessionStopping"), object: nil)
        }
        
        sessionQueue.async { [weak self] in
            guard let self = self else {
                print("❌ QRScanner: Self is nil in stopScanning")
                return
            }

            guard let captureSession = self.captureSession else {
                print("⚠️ QRScanner: No capture session to stop")
                return
            }

            print("📷 QRScanner: Checking session state... isRunning: \(captureSession.isRunning)")

            if captureSession.isRunning {
                print("📷 QRScanner: Stopping session...")
                captureSession.stopRunning()
                self.isSessionRunning = false
                print("✅ QRScanner: Session stop requested")
            } else {
                print("⚠️ QRScanner: Session was not running")
                self.isSessionRunning = false
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
    private var readyObserver: NSObjectProtocol?
    private var stoppingObserver: NSObjectProtocol?
    private var isDisconnected = false

    override func viewDidLoad() {
        super.viewDidLoad()
        setupPreviewLayer()
        setupObservers()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        isDisconnected = false
        updatePreviewLayer()
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        disconnectPreviewLayer()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        previewLayer?.frame = view.bounds
    }

    deinit {
        if let observer = readyObserver {
            NotificationCenter.default.removeObserver(observer)
        }
        if let observer = stoppingObserver {
            NotificationCenter.default.removeObserver(observer)
        }
        disconnectPreviewLayer()
    }

    private func setupObservers() {
        readyObserver = NotificationCenter.default.addObserver(
            forName: NSNotification.Name("CaptureSessionReady"),
            object: nil,
            queue: .main
        ) { [weak self] notification in
            self?.updatePreviewLayer()
        }

        stoppingObserver = NotificationCenter.default.addObserver(
            forName: NSNotification.Name("CaptureSessionStopping"),
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.disconnectPreviewLayer()
        }
    }

    private func disconnectPreviewLayer() {
        guard !isDisconnected, let previewLayer = previewLayer else { return }
        print("📷 PreviewViewController: Disconnecting preview layer from session")
        previewLayer.session = nil
        isDisconnected = true
    }

    private func setupPreviewLayer() {
        guard previewLayer == nil else { return }

        let layer = AVCaptureVideoPreviewLayer()
        layer.videoGravity = .resizeAspectFill
        view.backgroundColor = .black
        view.layer.addSublayer(layer)
        previewLayer = layer

        updatePreviewLayer()
    }

    func updatePreviewLayer() {
        guard let previewLayer = previewLayer else {
            print("⚠️ PreviewViewController: No preview layer")
            return
        }

        if let captureSession = scanner?.captureSession {
            if previewLayer.session == nil && !isDisconnected {
                print("📷 PreviewViewController: Setting session (was nil)")
                if captureSession.inputs.count > 0 && captureSession.outputs.count > 0 {
                    previewLayer.session = captureSession
                    print("✅ PreviewViewController: Session connected successfully")
                } else {
                    print("⚠️ PreviewViewController: Session not ready yet (inputs: \(captureSession.inputs.count), outputs: \(captureSession.outputs.count))")
                }
            } else if previewLayer.session !== captureSession && !isDisconnected {
                print("📷 PreviewViewController: Replacing session")
                previewLayer.session = captureSession
            } else if previewLayer.session === captureSession {
                print("✅ PreviewViewController: Session already set correctly")
            }
        } else {
            print("⚠️ PreviewViewController: No capture session available")
        }

        let bounds = view.bounds
        if previewLayer.frame != bounds && !bounds.isEmpty {
            print("📷 PreviewViewController: Updating frame to \(bounds)")
            previewLayer.frame = bounds
        }
    }
}

