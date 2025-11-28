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
                        scanner.stopScanning()
                        dismiss()
                    }
                }
            }
            .task {
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
                scanner.stopScanning()
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
    weak var previewCoordinator: QRScannerPreview.Coordinator?
    private var runtimeErrorObserver: NSObjectProtocol?
    private var sessionInterruptionObserver: NSObjectProtocol?
    private var interruptionEndedObserver: NSObjectProtocol?

    private var isSessionRunning: Bool {
        return sessionState == .running
    }

    override init() {
        super.init()
        setupSessionObservers()
    }

    deinit {
        removeSessionObservers()
    }

    private func setupSessionObservers() {
        // Обработка ошибок выполнения сессии
        runtimeErrorObserver = NotificationCenter.default.addObserver(
            forName: .AVCaptureSessionRuntimeError,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            guard let self = self else { return }
            self.handleSessionRuntimeError(notification)
        }

        // Обработка прерываний сессии
        sessionInterruptionObserver = NotificationCenter.default.addObserver(
            forName: .AVCaptureSessionWasInterrupted,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            guard let self = self else { return }
            self.handleSessionInterruption(notification)
        }

        // Обработка возобновления сессии после прерывания
        interruptionEndedObserver = NotificationCenter.default.addObserver(
            forName: .AVCaptureSessionInterruptionEnded,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            guard let self = self else { return }
            print("✅ QRScanner: Session interruption ended")
            // Если сессия была запущена до прерывания, перезапускаем её
            if self.sessionState == .ready {
                self.startScanning()
            }
        }
    }

    private func removeSessionObservers() {
        if let observer = runtimeErrorObserver {
            NotificationCenter.default.removeObserver(observer)
        }
        if let observer = sessionInterruptionObserver {
            NotificationCenter.default.removeObserver(observer)
        }
        if let observer = interruptionEndedObserver {
            NotificationCenter.default.removeObserver(observer)
        }
    }

    private func handleSessionRuntimeError(_ notification: Notification) {
        guard let session = captureSession else { return }

        if let error = notification.userInfo?[AVCaptureSessionErrorKey] as? AVError {
            print("❌ QRScanner: Session runtime error: \(error.localizedDescription), code: \(error.code.rawValue)")

            // Если ошибка -12710 (AVErrorMediaServicesWereReset), восстанавливаем сессию
            if error.code == .mediaServicesWereReset {
                print("🔄 QRScanner: Media services were reset, attempting to recover...")
                sessionQueue.async { [weak self] in
                    guard let self = self else { return }
                    if session.isRunning {
                        session.stopRunning()
                    }
                    self.recoverSession()
                }
            } else {
                // Для других ошибок также пытаемся восстановить
                print("🔄 QRScanner: Attempting to recover from error...")
                sessionQueue.async { [weak self] in
                    guard let self = self else { return }
                    if session.isRunning {
                        session.stopRunning()
                    }
                    self.recoverSession()
                }
            }
        }
    }

    private func handleSessionInterruption(_ notification: Notification) {
        guard let session = captureSession else { return }

        if let reason = notification.userInfo?[AVCaptureSessionInterruptionReasonKey] as? AVCaptureSession.InterruptionReason {
            print("⚠️ QRScanner: Session interrupted, reason: \(reason.rawValue)")

            if reason == .audioDeviceInUseByAnotherClient || reason == .videoDeviceInUseByAnotherClient {
                // Устройство используется другим приложением
                print("📷 QRScanner: Device in use by another client")
            }
        }
    }

    private func recoverSession() {
        print("🔄 QRScanner: Recovering session...")

        guard let session = captureSession else {
            print("❌ QRScanner: No session to recover")
            sessionState = .idle
            return
        }

        // Сбрасываем состояние
        sessionState = .idle

        // Очищаем текущую сессию
        DispatchQueue.main.async { [weak self] in
            self?.previewCoordinator?.disconnectPreviewLayer()
        }

        // Пересоздаем сессию
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            guard let self = self else { return }
            self.captureSession = nil
            self.startScanning()
        }
    }

    func startScanning() {
        print("📷 QRScanner: startScanning() called, current state: \(sessionState)")

        // Не запускаем, если сессия уже запущена или в процессе настройки
        guard sessionState == .idle || sessionState == .ready else {
            if sessionState == .running {
                print("📷 QRScanner: Session already running")
            } else if sessionState == .configuring {
                print("⚠️ QRScanner: Session is being configured, please wait")
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

        // Проверяем, что мы не в процессе конфигурации
        guard sessionState != .configuring else {
            print("⚠️ QRScanner: Already configuring, skipping")
            return
        }

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

        // Очищаем предыдущую сессию, если она существует
        if let oldSession = captureSession {
            print("📷 QRScanner: Cleaning up old session")
            if oldSession.isRunning {
                oldSession.stopRunning()
            }
            captureSession = nil
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

        // КРИТИЧЕСКИ ВАЖНО: commitConfiguration() должен полностью завершиться
        // перед любыми другими операциями с сессией. commitConfiguration() является синхронным,
        // поэтому после этой строки конфигурация гарантированно завершена.

        // Настраиваем metadata output ДО сохранения сессии
        metadataOutput.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
        metadataOutput.metadataObjectTypes = [.qr]
        print("✅ QRScanner: Metadata output configured for QR codes")

        // Сохраняем сессию и меняем состояние
        self.captureSession = captureSession
        self.sessionState = .ready
        print("✅ QRScanner: Capture session stored, state: \(sessionState)")

        // Уведомляем о готовности сессии на главном потоке
        DispatchQueue.main.async { [weak self] in
            print("📷 QRScanner: Posting CaptureSessionReady notification")
            NotificationCenter.default.post(name: NSNotification.Name("CaptureSessionReady"), object: nil)
        }

        // ВАЖНО: Запускаем сессию на том же потоке (sessionQueue), где была выполнена конфигурация
        // Поскольку setupCaptureSession() вызывается из sessionQueue.async в startScanning(),
        // мы уже находимся на sessionQueue. commitConfiguration() синхронный и уже завершен,
        // поэтому мы можем безопасно вызвать startRunning() сразу, без дополнительных async вызовов.
        // Но для безопасности используем async, чтобы гарантировать, что все предыдущие операции завершены.
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.sessionQueue.async { [weak self] in
                guard let self = self, let session = self.captureSession else {
                    print("❌ QRScanner: Session is nil when trying to start")
                    return
                }
                guard self.sessionState == .ready else {
                    print("⚠️ QRScanner: State is \(self.sessionState), not starting")
                    return
                }

                // Дополнительная проверка: убеждаемся, что сессия не запущена
                if session.isRunning {
                    print("⚠️ QRScanner: Session already running, skipping start")
                    self.sessionState = .running
                    return
                }

                print("📷 QRScanner: Starting session on background thread...")

                // ВАЖНО: startRunning() должен вызываться ТОЛЬКО после полного завершения commitConfiguration()
                // и на том же потоке, где выполнялась конфигурация (sessionQueue)
                // Поскольку commitConfiguration() синхронный и мы на sessionQueue, это безопасно
                self.sessionState = .running
                session.startRunning()

                // Проверяем, что сессия действительно запустилась
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
                    guard let self = self else { return }
                    if let session = self.captureSession, !session.isRunning && self.sessionState == .running {
                        print("⚠️ QRScanner: Session failed to start, attempting recovery...")
                        self.sessionState = .idle
                        self.recoverSession()
                    } else {
                        print("✅ QRScanner: Session started successfully, isRunning: \(session.isRunning ?? false)")
                    }
                }
            }
        }
    }

    func stopScanning() {
        print("📷 QRScanner: stopScanning() called, current state: \(sessionState)")

        guard sessionState == .running || sessionState == .ready || sessionState == .configuring else {
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

        // КРИТИЧЕСКИ ВАЖНО: Сначала отключаем preview layer СИНХРОННО на главном потоке
        // Это гарантирует, что preview layer отключен ДО остановки сессии
        // Использование sync предотвращает гонку условий и ошибку -17281
        let semaphore = DispatchSemaphore(value: 0)
        DispatchQueue.main.async { [weak self] in
            print("📷 QRScanner: Disconnecting preview layer on main thread")
            self?.previewCoordinator?.disconnectPreviewLayer()
            semaphore.signal()
        }
        semaphore.wait()
        print("✅ QRScanner: Preview layer disconnected, proceeding to stop session")

        // Останавливаем сессию на фоновом потоке ПОСЛЕ отключения preview layer
        sessionQueue.async { [weak self] in
            guard let self = self else { return }
            guard self.sessionState == .stopping else {
                print("⚠️ QRScanner: State changed to \(self.sessionState) during stop")
                return
            }

            print("📷 QRScanner: Checking session state... isRunning: \(captureSession.isRunning)")

            if captureSession.isRunning {
                print("📷 QRScanner: Stopping session on background thread...")

                // ВАЖНО: Убеждаемся, что preview layer отключен перед остановкой
                // Это предотвращает ошибку -17281 (AVErrorSessionNotRunning)
                // Preview layer уже отключен синхронно выше, поэтому это безопасно

                captureSession.stopRunning()

                // Ждем, пока сессия полностью остановится
                var attempts = 0
                while captureSession.isRunning && attempts < 10 {
                    Thread.sleep(forTimeInterval: 0.1)
                    attempts += 1
                }

                if captureSession.isRunning {
                    print("⚠️ QRScanner: Session still running after stop attempt")
                } else {
                    print("✅ QRScanner: Session stopped successfully")
                }
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
        scanner.previewCoordinator = coordinator
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
        print("📷 QRScannerPreview: dismantleUIView called - system will handle preview layer cleanup")
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
            // ВАЖНО: Отключаем сессию от preview layer на главном потоке
            // Это должно быть выполнено ДО остановки сессии, чтобы избежать ошибки -17281
            if previewView.previewLayer.session != nil {
                print("📷 QRScannerPreview Coordinator: Disconnecting preview layer")
                // Устанавливаем session в nil, чтобы отключить preview layer от сессии
                previewView.setSession(nil)
            } else {
                print("📷 QRScannerPreview Coordinator: Preview layer already disconnected")
            }
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

