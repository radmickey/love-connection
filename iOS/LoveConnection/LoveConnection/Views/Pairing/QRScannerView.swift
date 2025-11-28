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

enum SessionState {
    case idle
    case requestingPermission
    case configuring
    case ready
    case running
    case stopping
}

class QRScanner: NSObject, ObservableObject, AVCaptureMetadataOutputObjectsDelegate {
    @Published var scannedCode: String?

    var captureSession: AVCaptureSession?
    private let sessionQueue = DispatchQueue(label: "com.loveconnection.captureSession")
    private var sessionState: SessionState = .idle
    private var previewLayerDisconnectCallback: (() -> Void)?
    
    private var isSessionRunning: Bool {
        return sessionState == .running
    }
    
    func setPreviewLayerDisconnectCallback(_ callback: @escaping () -> Void) {
        previewLayerDisconnectCallback = callback
    }

    func startScanning() {
        print("📷 QRScanner: startScanning() called, current state: \(sessionState)")

        guard sessionState == .idle || sessionState == .ready else {
            if sessionState == .running {
                print("📷 QRScanner: Session already running")
            } else {
                print("⚠️ QRScanner: Session is in state \(sessionState), cannot start")
            }
            return
        }

        if let session = captureSession {
            if sessionState == .ready {
                print("📷 QRScanner: Starting existing session")
                sessionQueue.async { [weak self] in
                    guard let self = self, let session = self.captureSession else {
                        print("❌ QRScanner: Session is nil")
                        return
                    }
                    guard self.sessionState == .ready else {
                        print("⚠️ QRScanner: State changed to \(self.sessionState), aborting start")
                        return
                    }
                    print("📷 QRScanner: Starting session on background queue")
                    if !session.isRunning {
                        self.sessionState = .running
                        session.startRunning()
                        print("✅ QRScanner: Session started")
                    } else {
                        print("⚠️ QRScanner: Session already running")
                        self.sessionState = .running
                    }
                }
            }
            return
        }

        sessionState = .requestingPermission
        print("📷 QRScanner: Requesting camera access...")
        AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
            guard let self = self else { return }

            if granted {
                print("✅ QRScanner: Camera access granted")
            } else {
                print("❌ QRScanner: Camera access denied")
                self.sessionState = .idle
                return
            }

            self.sessionQueue.async {
                guard self.sessionState == .requestingPermission else {
                    print("⚠️ QRScanner: State changed during permission request")
                    return
                }
                print("📷 QRScanner: Setting up capture session on background queue")
                self.setupCaptureSession()
            }
        }
    }

    private func setupCaptureSession() {
        print("📷 QRScanner: setupCaptureSession() started")
        sessionState = .configuring

        guard let videoCaptureDevice = AVCaptureDevice.default(for: .video) else {
            print("❌ QRScanner: No video capture device available")
            sessionState = .idle
            return
        }
        print("✅ QRScanner: Video capture device found: \(videoCaptureDevice.localizedName)")

        let videoInput: AVCaptureDeviceInput

        do {
            videoInput = try AVCaptureDeviceInput(device: videoCaptureDevice)
            print("✅ QRScanner: Video input created")
        } catch {
            print("❌ QRScanner: Failed to create video input: \(error)")
            sessionState = .idle
            return
        }

        let captureSession = AVCaptureSession()
        print("📷 QRScanner: AVCaptureSession created")

        guard captureSession.canSetSessionPreset(.high) else {
            print("❌ QRScanner: Cannot set session preset to .high")
            sessionState = .idle
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
            sessionState = .idle
            return
        }
        captureSession.addInput(videoInput)
        print("✅ QRScanner: Video input added")

        let metadataOutput = AVCaptureMetadataOutput()

        guard captureSession.canAddOutput(metadataOutput) else {
            print("❌ QRScanner: Cannot add metadata output")
            captureSession.commitConfiguration()
            sessionState = .idle
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
        self.sessionState = .ready
        print("✅ QRScanner: Capture session stored, state: \(sessionState)")

        DispatchQueue.main.async { [weak self] in
            print("📷 QRScanner: Posting CaptureSessionReady notification")
            NotificationCenter.default.post(name: NSNotification.Name("CaptureSessionReady"), object: nil)
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
            guard let self = self, let session = self.captureSession else {
                print("❌ QRScanner: Session is nil when trying to start")
                return
            }
            guard self.sessionState == .ready else {
                print("⚠️ QRScanner: State is \(self.sessionState), not starting")
                return
            }
            print("📷 QRScanner: Starting session on background thread...")
            self.sessionQueue.async {
                guard self.sessionState == .ready else {
                    print("⚠️ QRScanner: State changed to \(self.sessionState) before start")
                    return
                }
                if !session.isRunning {
                    self.sessionState = .running
                    session.startRunning()
                    print("✅ QRScanner: Session started successfully, isRunning: \(session.isRunning)")
                } else {
                    print("⚠️ QRScanner: Session already running")
                    self.sessionState = .running
                }
            }
        }
    }

    func stopScanning() {
        print("📷 QRScanner: stopScanning() called, current state: \(sessionState)")

        guard sessionState == .running || sessionState == .ready else {
            print("⚠️ QRScanner: Session is in state \(sessionState), nothing to stop")
            if sessionState != .stopping {
                sessionState = .idle
            }
            return
        }

        guard let captureSession = captureSession else {
            print("⚠️ QRScanner: No capture session to stop")
            sessionState = .idle
            return
        }

        sessionState = .stopping
        
        let semaphore = DispatchSemaphore(value: 0)
        
        DispatchQueue.main.async { [weak self] in
            guard let self = self else {
                semaphore.signal()
                return
            }
            print("📷 QRScanner: Disconnecting preview layer synchronously on main thread")
            self.previewLayerDisconnectCallback?()
            NotificationCenter.default.post(name: NSNotification.Name("CaptureSessionStopping"), object: nil)
            semaphore.signal()
        }
        
        semaphore.wait()
        print("✅ QRScanner: Preview layer disconnected, proceeding to stop session")

        sessionQueue.async { [weak self] in
            guard let self = self else { return }
            guard self.sessionState == .stopping else {
                print("⚠️ QRScanner: State changed to \(self.sessionState) during stop")
                return
            }

            print("📷 QRScanner: Checking session state... isRunning: \(captureSession.isRunning)")

            if captureSession.isRunning {
                print("📷 QRScanner: Stopping session on background thread...")
                captureSession.stopRunning()

                var attempts = 0
                while captureSession.isRunning && attempts < 20 {
                    Thread.sleep(forTimeInterval: 0.05)
                    attempts += 1
                }

                print("✅ QRScanner: Session stopped, isRunning: \(captureSession.isRunning) after \(attempts) attempts")
            } else {
                print("⚠️ QRScanner: Session was not running")
            }

            DispatchQueue.main.async {
                self.sessionState = .idle
                print("✅ QRScanner: State reset to idle")
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

    func makeCoordinator() -> Coordinator {
        let coordinator = Coordinator(scanner: scanner)
        scanner.setPreviewLayerDisconnectCallback { [weak coordinator] in
            coordinator?.disconnectPreviewLayer()
        }
        return coordinator
    }

    func makeUIView(context: Context) -> PreviewView {
        let previewView = PreviewView()
        previewView.backgroundColor = .black
        previewView.previewLayer.videoGravity = .resizeAspectFill

        context.coordinator.previewView = previewView

        if let session = scanner.captureSession {
            previewView.setSession(session)
            print("✅ QRScannerPreview: Session set in makeUIView")
        } else {
            print("⚠️ QRScannerPreview: No session available in makeUIView")
        }

        return previewView
    }

    func updateUIView(_ uiView: PreviewView, context: Context) {
        if let session = scanner.captureSession {
            if uiView.previewLayer.session !== session {
                uiView.setSession(session)
                print("✅ QRScannerPreview: Session updated in updateUIView")
            }
        } else {
            if uiView.previewLayer.session != nil {
                print("📷 QRScannerPreview: Clearing session in updateUIView")
                uiView.setSession(nil)
            }
        }

        if uiView.previewLayer.frame != uiView.bounds && !uiView.bounds.isEmpty {
            uiView.previewLayer.frame = uiView.bounds
        }
    }

    static func dismantleUIView(_ uiView: PreviewView, coordinator: Coordinator) {
        print("📷 QRScannerPreview: dismantleUIView called")
        uiView.setSession(nil)
        coordinator.cleanup()
    }

    class Coordinator: NSObject {
        let scanner: QRScanner
        var previewView: PreviewView?
        private var readyObserver: NSObjectProtocol?
        private var stoppingObserver: NSObjectProtocol?

        init(scanner: QRScanner) {
            self.scanner = scanner
            super.init()
            setupObservers()
        }

        private func setupObservers() {
            readyObserver = NotificationCenter.default.addObserver(
                forName: NSNotification.Name("CaptureSessionReady"),
                object: nil,
                queue: .main
            ) { [weak self] _ in
                guard let self = self, let previewView = self.previewView else { return }
                if let session = self.scanner.captureSession {
                    previewView.setSession(session)
                    print("✅ QRScannerPreview Coordinator: Session set after ready notification")
                }
            }

            stoppingObserver = NotificationCenter.default.addObserver(
                forName: NSNotification.Name("CaptureSessionStopping"),
                object: nil,
                queue: .main
            ) { [weak self] _ in
                self?.disconnectPreviewLayer()
            }
        }
        
        func disconnectPreviewLayer() {
            guard let previewView = previewView else {
                print("⚠️ QRScannerPreview Coordinator: No preview view to disconnect")
                return
            }
            print("📷 QRScannerPreview Coordinator: Disconnecting preview layer synchronously")
            previewView.setSession(nil)
        }

        func cleanup() {
            if let observer = readyObserver {
                NotificationCenter.default.removeObserver(observer)
            }
            if let observer = stoppingObserver {
                NotificationCenter.default.removeObserver(observer)
            }
            disconnectPreviewLayer()
        }
    }
}

