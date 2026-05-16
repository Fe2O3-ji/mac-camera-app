import AVFoundation
import SwiftUI

class CameraManager: NSObject, ObservableObject {
    @Published var isSessionRunning = false
    @Published var isUsingFrontCamera = true
    @Published var lastCapturedPhoto: NSImage?
    @Published var authorizationStatus: AVAuthorizationStatus = .notDetermined
    @Published var errorMessage: String?

    @Published var isCenterStageEnabled = false
    @Published var centerStageSupported = false

    let captureSession = AVCaptureSession()
    private var photoOutput = AVCapturePhotoOutput()
    private var currentDevice: AVCaptureDevice?
    private let sessionQueue = DispatchQueue(label: "camera.session.queue")

    override init() {
        super.init()
        checkAuthorization()
    }

    func checkAuthorization() {
        let status = AVCaptureDevice.authorizationStatus(for: .video)
        DispatchQueue.main.async {
            self.authorizationStatus = status
        }
    }

    func requestAuthorization() {
        AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
            DispatchQueue.main.async {
                self?.authorizationStatus = granted ? .authorized : .denied
                if granted {
                    self?.setupSession()
                }
            }
        }
    }

    func setupSession() {
        sessionQueue.async { [weak self] in
            guard let self = self else { return }

            self.captureSession.beginConfiguration()

            for input in self.captureSession.inputs {
                self.captureSession.removeInput(input)
            }

            let discoverySession = AVCaptureDevice.DiscoverySession(
                deviceTypes: [.builtInWideAngleCamera],
                mediaType: .video,
                position: .front
            )

            guard let device = discoverySession.devices.first else {
                DispatchQueue.main.async {
                    self.errorMessage = "未找到摄像头"
                }
                return
            }

            self.currentDevice = device

            do {
                let input = try AVCaptureDeviceInput(device: device)
                if self.captureSession.canAddInput(input) {
                    self.captureSession.addInput(input)
                }
            } catch {
                DispatchQueue.main.async {
                    self.errorMessage = "无法访问摄像头: \(error.localizedDescription)"
                }
                return
            }

            if self.captureSession.canAddOutput(self.photoOutput) {
                self.captureSession.addOutput(self.photoOutput)
            }

            self.captureSession.commitConfiguration()
            self.captureSession.startRunning()

            DispatchQueue.main.async {
                self.isSessionRunning = true
                self.refreshCenterStageStatus()
            }
        }
    }

    func stopSession() {
        sessionQueue.async { [weak self] in
            self?.captureSession.stopRunning()
            DispatchQueue.main.async {
                self?.isSessionRunning = false
            }
        }
    }

    func capturePhoto() {
        let settings = AVCapturePhotoSettings()
        photoOutput.capturePhoto(with: settings, delegate: self)
    }

    // MARK: - Center Stage

    func toggleCenterStage() {
        guard let device = currentDevice, device.activeFormat.isCenterStageSupported else { return }

        AVCaptureDevice.centerStageControlMode = .cooperative
        AVCaptureDevice.isCenterStageEnabled.toggle()
        isCenterStageEnabled = AVCaptureDevice.isCenterStageEnabled
    }

    private func refreshCenterStageStatus() {
        guard let device = currentDevice else { return }
        centerStageSupported = device.activeFormat.isCenterStageSupported
        isCenterStageEnabled = AVCaptureDevice.isCenterStageEnabled
    }
}

// MARK: - AVCapturePhotoCaptureDelegate

extension CameraManager: AVCapturePhotoCaptureDelegate {
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        if let error = error {
            DispatchQueue.main.async {
                self.errorMessage = "拍照失败: \(error.localizedDescription)"
            }
            return
        }

        guard let imageData = photo.fileDataRepresentation(),
              let image = NSImage(data: imageData) else {
            return
        }

        DispatchQueue.main.async {
            self.lastCapturedPhoto = image
        }
    }
}
