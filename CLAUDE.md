# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Build & Run

```bash
# Build
swift build

# Run
swift run
```

## Project Overview

macOS self-camera app with native system video effects support (Center Stage, Portrait Effect, Studio Light, Reactions).

**Tech Stack:**
- Swift 5.9+ / SwiftUI
- AVFoundation for camera capture
- NSViewRepresentable to bridge AVCaptureVideoPreviewLayer
- macOS 13.0+ deployment target

## Architecture

- **CameraManager** (ObservableObject): Core AVFoundation logic - session management, device discovery, photo capture
- **CameraPreviewView** (NSViewRepresentable): Bridges AVCaptureVideoPreviewLayer to SwiftUI with mirror support
- **PhotoManager**: Handles photo persistence to ~/Pictures/Mac拍照软件/
- **ContentView**: Main UI with preview area and control panel
- **PhotoGalleryView**: Grid view for browsing saved photos with delete/export

## Key Constraints

- **Video effects**: Uses system UI (`showSystemUserInterface(.videoEffects)`) for Center Stage, Portrait Effect, Studio Light, Reactions
- **Camera permission**: NSCameraUsageDescription required in Info.plist
- **No code signing**: Local use only, no sandboxing or notarization needed
