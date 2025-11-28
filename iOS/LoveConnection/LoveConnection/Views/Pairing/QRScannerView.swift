import SwiftUI
import AVFoundation
import Combine

struct QRScannerView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var appState: AppState
    @StateObject private var scanner = QRScanner()
    @State private var errorMessage: String?
    @State private var isActive = true

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
                isActive = true
                scanner.startScanning()
            }
            .onDisappear {
                isActive = false
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
    private var stopCompletion: (() -> Void)?

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
            NotificationCenter.default.post(name: NSNotification.Name("CaptureSessionReady"), object: nil)
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
            guard let self = self, let session = self.captureSession else {
                print("❌ QRScanner: Session is nil when trying to start")
                return
            }
            print("📷 QRScanner: Starting session on background thread...")
            self.sessionQueue.async {
                if !session.isRunning {
                    session.startRunning()
                    DispatchQueue.main.async {
                        self.isSessionRunning = true
                    }
                    print("✅ QRScanner: Session started successfully, isRunning: \(session.isRunning)")
                } else {
                    print("⚠️ QRScanner: Session already running")
                }
            }
        }
    }

    func stopScanning() {
        print("📷 QRScanner: stopScanning() called")

        guard let captureSession = captureSession else {
            print("⚠️ QRScanner: No capture session to stop")
            isSessionRunning = false
            return
        }

        sessionQueue.async { [weak self] in
            guard let self = self else {
                print("❌ QRScanner: Self is nil in stopScanning")
                return
            }

            print("📷 QRScanner: Checking session state... isRunning: \(captureSession.isRunning)")

            if captureSession.isRunning {
                print("📷 QRScanner: Stopping session on background thread...")
                captureSession.stopRunning()
                print("✅ QRScanner: Session stopped")
            } else {
                print("⚠️ QRScanner: Session was not running")
            }
            
            DispatchQueue.main.async {
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

class PreviewView: UIView {
    override class var layerClass: AnyClass {
        return AVCaptureVideoPreviewLayer.self
    }
    
    var previewLayer: AVCaptureVideoPreviewLayer {
        return layer as! AVCaptureVideoPreviewLayer
    }
    
    func setSession(_ session: AVCaptureSession?) {
        previewLayer.session = session
    }
}

struct QRScannerPreview: UIViewRepresentable {
    let scanner: QRScanner
    
    func makeUIView(context: Context) -> PreviewView {
        let previewView = PreviewView()
        previewView.backgroundColor = .black
        previewView.previewLayer.videoGravity = .resizeAspectFill
        
        if let session = scanner.captureSession {
            previewView.setSession(session)
            print("✅ QRScannerPreview: Session set in makeUIView")
        } else {
            print("⚠️ QRScannerPreview: No session available in makeUIView")
            NotificationCenter.default.addObserver(
                forName: NSNotification.Name("CaptureSessionReady"),
                object: nil,
                queue: .main
            ) { notification in
                if let session = scanner.captureSession {
                    previewView.setSession(session)
                    print("✅ QRScannerPreview: Session set after ready notification")
                }
            }
        }
        
        return previewView
    }
    
    func updateUIView(_ uiView: PreviewView, context: Context) {
        if let session = scanner.captureSession {
            if uiView.previewLayer.session !== session {
                uiView.setSession(session)
                print("✅ QRScannerPreview: Session updated in updateUIView")
            }
        }
        
        if uiView.previewLayer.frame != uiView.bounds && !uiView.bounds.isEmpty {
            uiView.previewLayer.frame = uiView.bounds
        }
    }
}

