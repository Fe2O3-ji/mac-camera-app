import SwiftUI
import AVFoundation

struct ContentView: View {
    @StateObject private var cameraManager = CameraManager()
    @StateObject private var photoManager = PhotoManager()
    @State private var showError = false
    @State private var captureFlash = false
    @State private var hoverCapture = false

    var body: some View {
        VStack(spacing: 0) {
            ZStack {
                if cameraManager.isSessionRunning {
                    CameraPreviewView(
                        captureSession: cameraManager.captureSession,
                        isMirrored: cameraManager.isUsingFrontCamera
                    )

                    // Center Stage 切换
                    if cameraManager.centerStageSupported {
                        VStack {
                            HStack {
                                Spacer()
                                EffectTag(
                                    icon: "person.crop.rectangle",
                                    label: "人物居中",
                                    active: cameraManager.isCenterStageEnabled,
                                    action: cameraManager.toggleCenterStage
                                )
                            }
                            Spacer()
                        }
                        .padding(12)
                    }
                } else {
                    Color.black
                    statusView
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            controlBar
        }
        .frame(minWidth: 800, minHeight: 600)
        .onAppear { checkAndSetupCamera() }
        .onDisappear { cameraManager.stopSession() }
        .onChange(of: cameraManager.lastCapturedPhoto) { image in
            if let image = image { photoManager.savePhoto(image) }
        }
        .onChange(of: cameraManager.errorMessage) { msg in
            showError = msg != nil
        }
        .alert("错误", isPresented: $showError) {
            Button("确定") { cameraManager.errorMessage = nil }
        } message: {
            Text(cameraManager.errorMessage ?? "")
        }
    }

    private var statusView: some View {
        VStack(spacing: 24) {
            Image(systemName: "camera.fill")
                .font(.system(size: 64, weight: .thin))
                .foregroundStyle(.secondary)

            if cameraManager.authorizationStatus == .denied {
                Text("需要摄像头权限")
                    .font(.title2.weight(.medium))
                Text("请在弹窗中允许，或在系统设置中手动授权")
                    .foregroundStyle(.secondary)
                HStack(spacing: 12) {
                    Button("重试授权") {
                        cameraManager.requestAuthorization()
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                    Button("系统设置") {
                        NSWorkspace.shared.open(URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Camera")!)
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.large)
                }
            } else if cameraManager.authorizationStatus == .notDetermined {
                Text("需要摄像头权限")
                    .font(.title2.weight(.medium))
                Button("授权摄像头") {
                    cameraManager.requestAuthorization()
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
            } else {
                ProgressView("正在启动摄像头…")
                    .foregroundColor(.white)
            }
        }
    }

    private func checkAndSetupCamera() {
        switch cameraManager.authorizationStatus {
        case .authorized: cameraManager.setupSession()
        default: cameraManager.requestAuthorization()
        }
    }

    // MARK: - Control Bar

    private var controlBar: some View {
        HStack {
            Spacer()
            captureButton
            Spacer()
        }
        .padding(.horizontal, 28)
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(.ultraThinMaterial)
                .shadow(color: .black.opacity(0.15), radius: 12, y: -2)
        )
        .padding(.horizontal, 12)
        .padding(.bottom, 8)
    }

    private var captureButton: some View {
        Button(action: onCapture) {
            ZStack {
                Circle()
                    .fill(.white)
                    .frame(width: 68, height: 68)
                    .shadow(color: .black.opacity(0.2), radius: 8, y: 2)

                Circle()
                    .stroke(captureFlash ? Color.gray : Color.white, lineWidth: 4)
                    .frame(width: captureFlash ? 72 : 64, height: captureFlash ? 72 : 64)
                    .animation(.easeInOut(duration: 0.15), value: captureFlash)
            }
            .scaleEffect(hoverCapture ? 1.05 : 1.0)
            .animation(.easeOut(duration: 0.15), value: hoverCapture)
        }
        .buttonStyle(.plain)
        .keyboardShortcut(.space, modifiers: [])
        .onHover { hoverCapture = $0 }
    }

    private func onCapture() {
        withAnimation(.easeInOut(duration: 0.1)) { captureFlash = true }
        cameraManager.capturePhoto()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
            withAnimation(.easeInOut(duration: 0.1)) { captureFlash = false }
        }
    }
}

struct EffectTag: View {
    let icon: String
    let label: String
    let active: Bool
    var action: (() -> Void)?

    var body: some View {
        if let action {
            Button(action: action) {
                tagContent
            }
            .buttonStyle(.plain)
        } else {
            tagContent
        }
    }

    private var tagContent: some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 12, weight: .medium))
            Text(label)
                .font(.caption2)
        }
        .foregroundColor(active ? .black : .white.opacity(0.8))
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(
            Capsule()
                .fill(active ? Color.white : Color.white.opacity(0.15))
        )
    }
}
