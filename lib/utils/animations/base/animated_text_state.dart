import 'dart:ui';

/// Holds the computed animation state for a single frame.
/// This is the shared data class used across all animation modules.
class AnimatedTextState {
  final double opacity;
  final double offsetX;
  final double offsetY;
  final double scale;
  final double scaleX;
  final double scaleY;
  final double rotation; // degrees
  final double rotationX; // degrees
  final double rotationY; // degrees
  final double typewriterProgress; // 0.0-1.0, chars visible

  const AnimatedTextState({
    this.opacity = 1.0,
    this.offsetX = 0.0,
    this.offsetY = 0.0,
    this.scale = 1.0,
    this.scaleX = 1.0,
    this.scaleY = 1.0,
    this.rotation = 0.0,
    this.rotationX = 0.0,
    this.rotationY = 0.0,
    this.typewriterProgress = 1.0,
  });
}
