import 'dart:math';
import '../models/editor_models.dart';

/// Holds the computed animation state for a single frame.
class AnimatedTextState {
  final double opacity;
  final double offsetX;
  final double offsetY;
  final double scale;
  final double rotation; // degrees
  final double typewriterProgress; // 0.0-1.0, chars visible

  const AnimatedTextState({
    this.opacity = 1.0,
    this.offsetX = 0.0,
    this.offsetY = 0.0,
    this.scale = 1.0,
    this.rotation = 0.0,
    this.typewriterProgress = 1.0,
  });
}

class AnimationEngine {
  /// Evaluate the animation state for a clip at a given time.
  static AnimatedTextState evaluate(SubtitleClip clip, int currentTimeMs) {
    final clipStart = clip.startTime.inMilliseconds;
    final clipEnd = clip.endTime.inMilliseconds;

    // Not visible
    if (currentTimeMs < clipStart || currentTimeMs > clipEnd) {
      return const AnimatedTextState(opacity: 0.0);
    }

    final elapsed = currentTimeMs - clipStart;
    final remaining = clipEnd - currentTimeMs;
    final clipDuration = clipEnd - clipStart;

    double opacity = clip.opacity;
    double offsetX = 0.0;
    double offsetY = 0.0;
    double scale = clip.scale;
    double rotation = clip.rotation;
    double typewriterProgress = 1.0;

    // === Entrance animation ===
    final entrance = clip.entranceAnimation;
    if (entrance.type != AnimationType.none && elapsed < entrance.durationMs) {
      final t = _applyEasing(elapsed / entrance.durationMs, entrance.easing);
      final state = _evaluateEntrance(entrance.type, t);
      opacity *= state.opacity;
      offsetX += state.offsetX;
      offsetY += state.offsetY;
      scale *= state.scale;
      rotation += state.rotation;
      typewriterProgress = state.typewriterProgress;
    }

    // === Exit animation ===
    final exit = clip.exitAnimation;
    if (exit.type != AnimationType.none && remaining < exit.durationMs) {
      final t = _applyEasing(remaining / exit.durationMs, exit.easing);
      final state = _evaluateExit(exit.type, t);
      opacity *= state.opacity;
      offsetX += state.offsetX;
      offsetY += state.offsetY;
      scale *= state.scale;
      rotation += state.rotation;
    }

    return AnimatedTextState(
      opacity: opacity.clamp(0.0, 1.0),
      offsetX: offsetX,
      offsetY: offsetY,
      scale: scale.clamp(0.01, 10.0),
      rotation: rotation,
      typewriterProgress: typewriterProgress.clamp(0.0, 1.0),
    );
  }

  /// Entrance: t goes from 0 (start) to 1 (fully entered).
  static AnimatedTextState _evaluateEntrance(AnimationType type, double t) {
    switch (type) {
      case AnimationType.fadeIn:
        return AnimatedTextState(opacity: t);
      case AnimationType.slideUp:
        return AnimatedTextState(offsetY: 0.3 * (1.0 - t));
      case AnimationType.slideDown:
        return AnimatedTextState(offsetY: -0.3 * (1.0 - t));
      case AnimationType.slideLeft:
        return AnimatedTextState(offsetX: 0.5 * (1.0 - t));
      case AnimationType.slideRight:
        return AnimatedTextState(offsetX: -0.5 * (1.0 - t));
      case AnimationType.scaleUp:
        return AnimatedTextState(scale: t, opacity: t);
      case AnimationType.scaleDown:
        return AnimatedTextState(scale: 2.0 - t, opacity: t);
      case AnimationType.typewriter:
        return AnimatedTextState(typewriterProgress: t);
      case AnimationType.bounceIn:
        return AnimatedTextState(scale: t, offsetY: 0.2 * (1.0 - t));
      case AnimationType.rotateIn:
        return AnimatedTextState(rotation: 360.0 * (1.0 - t), opacity: t, scale: t);
      default:
        return const AnimatedTextState();
    }
  }

  /// Exit: t goes from 1 (still visible) to 0 (gone).
  static AnimatedTextState _evaluateExit(AnimationType type, double t) {
    switch (type) {
      case AnimationType.fadeOut:
        return AnimatedTextState(opacity: t);
      case AnimationType.fadeIn:
        return AnimatedTextState(opacity: t);
      case AnimationType.slideUp:
        return AnimatedTextState(offsetY: -0.3 * (1.0 - t));
      case AnimationType.slideDown:
        return AnimatedTextState(offsetY: 0.3 * (1.0 - t));
      case AnimationType.slideLeft:
        return AnimatedTextState(offsetX: -0.5 * (1.0 - t));
      case AnimationType.slideRight:
        return AnimatedTextState(offsetX: 0.5 * (1.0 - t));
      case AnimationType.scaleUp:
        return AnimatedTextState(scale: t, opacity: t);
      case AnimationType.scaleDown:
        return AnimatedTextState(scale: 2.0 - t, opacity: t);
      case AnimationType.bounceIn:
        return AnimatedTextState(scale: t, offsetY: -0.2 * (1.0 - t));
      case AnimationType.rotateIn:
        return AnimatedTextState(rotation: -360.0 * (1.0 - t), opacity: t, scale: t);
      default:
        return const AnimatedTextState();
    }
  }

  /// Apply easing function to a linear progress value t (0..1).
  static double _applyEasing(double t, EasingType easing) {
    t = t.clamp(0.0, 1.0);
    switch (easing) {
      case EasingType.linear:
        return t;
      case EasingType.easeIn:
        return t * t * t;
      case EasingType.easeOut:
        return 1.0 - pow(1.0 - t, 3).toDouble();
      case EasingType.easeInOut:
        return t < 0.5
            ? 4 * t * t * t
            : 1.0 - pow(-2 * t + 2, 3).toDouble() / 2;
      case EasingType.bounceOut:
        return _bounceOut(t);
      case EasingType.elasticOut:
        return _elasticOut(t);
    }
  }

  static double _bounceOut(double t) {
    if (t < 1 / 2.75) {
      return 7.5625 * t * t;
    } else if (t < 2 / 2.75) {
      t -= 1.5 / 2.75;
      return 7.5625 * t * t + 0.75;
    } else if (t < 2.5 / 2.75) {
      t -= 2.25 / 2.75;
      return 7.5625 * t * t + 0.9375;
    } else {
      t -= 2.625 / 2.75;
      return 7.5625 * t * t + 0.984375;
    }
  }

  static double _elasticOut(double t) {
    if (t == 0.0 || t == 1.0) return t;
    return pow(2, -10 * t).toDouble() * sin((t - 0.075) * (2 * pi) / 0.3) + 1.0;
  }
}
