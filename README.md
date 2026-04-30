# Kinetic Typography Editor (Android)

A professional-grade, multi-track subtitle and kinetic typography editor for Android. Built with Flutter for a high-fidelity UI and a native Kotlin/OpenGL core for high-performance rendering and video export.

## 🚀 Key Features

*   **🎬 Multi-Track Timeline**: Professional non-linear editing interface with drag-and-drop support, segment trimming, and collision resolution.
*   **✨ Kinetic Animations**: Advanced animation engine supporting Fade, Slide, Scale, Rotate, Bounce, and more with specialized easing functions.
*   **📐 Project Settings**:
    *   **Dynamic Aspect Ratios**: High-precision support for 16:9 (Landscape), 9:16 (Vertical), and 1:1 (Square).
    *   **Custom Backgrounds**: Fluid canvas background color selection with real-time preview and export.
*   **🎨 Advanced Typography**:
    *   Dual-pass Stroke rendering.
    *   Drop Shadow effects with blur and offset controls.
    *   Custom font support via dynamic asset loading.
    *   Letter spacing and vertical alignment.
*   **📦 High-Quality Export**: Native MP4 export engine supporting 1080p standards (1920x1080, 1080x1920).
*   **🛠️ Interactive Preview**: Direct text selection and drag-to-transform directly on the video canvas.

## 🏗️ Technical Architecture

### Flutter (UI & State)
*   **Provider**: Centralized state management for the timeline, selections, and project settings.
*   **Custom UI Layer**: High-precision timeline widgets built with raw `Listener` components to bypass gesture arena limitations.
*   **Native Bridge**: Robust `MethodChannel` interface with safe `Number` casting for seamless Flutter-to-Kotlin synchronization.

### Kotlin (Rendering Engine)
*   **OpenGL ES 2.0**: High-performance surface rendering for real-time preview.
*   **EGL Surface Management**: Dynamic buffer resizing and DP-aware viewport synchronization.
*   **Custom Shaders**: High-fidelity fragment shaders with `alpha discard` for pixel-perfect transparency.
*   **MediaCodec Integration**: Direct hardware-accelerated video encoding for MP4 export.

## 🛠️ Development

### Prerequisites
*   Flutter SDK (Latest stable)
*   Android Studio / NDK

### Setup
1. Clone the repository.
2. Run `flutter pub get`.
3. Add font assets to `assets/fonts/` (ignored by git).
4. Run on a physical Android device for best OpenGL performance.

## 📝 Roadmap
*   [ ] FFmpeg integration for high-fidelity audio/video merging.
*   [ ] Multi-layer video support.
*   [ ] Advanced particle effects.

---
Built with ❤️ for high-performance mobile video editing.
