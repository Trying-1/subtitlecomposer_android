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
    final elapsedSec = elapsed / 1000.0;
    final remaining = clipEnd - currentTimeMs;

    // 1. Calculate Base State from Keyframes or Properties
    final baseState = _evaluateKeyframes(clip.keyframes, elapsedSec, clip);

    double opacity = baseState.opacity;
    double offsetX = baseState.offsetX;
    double offsetY = baseState.offsetY;
    double scale = baseState.scale;
    double rotation = baseState.rotation;
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

    // === Loop animation ===
    final loop = clip.loopAnimation;
    if (loop.type != AnimationType.none) {
      final state = _evaluateLoop(loop.type, currentTimeMs, loop.durationMs);
      offsetX += state.offsetX;
      offsetY += state.offsetY;
      rotation += state.rotation;
      scale *= state.scale;
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

  static AnimatedTextState _evaluateKeyframes(List<Keyframe> keyframes, double timeOffset, SubtitleClip clip) {
    if (keyframes.isEmpty) {
      return AnimatedTextState(
        opacity: clip.opacity,
        offsetX: 0.0,
        offsetY: 0.0,
        scale: clip.scale,
        rotation: clip.rotation,
      );
    }
    
    final sorted = List<Keyframe>.from(keyframes)..sort((a, b) => a.timeOffset.compareTo(b.timeOffset));
    
    final nextIndex = sorted.indexWhere((k) => k.timeOffset > timeOffset);
    
    if (nextIndex == 0) {
      final k = sorted.first;
      return AnimatedTextState(
        opacity: k.opacity ?? clip.opacity,
        offsetX: (k.x ?? clip.x) - clip.x,
        offsetY: (k.y ?? clip.y) - clip.y,
        scale: k.scale ?? clip.scale,
        rotation: k.rotation ?? clip.rotation,
      );
    }
    
    if (nextIndex == -1) {
      final k = sorted.last;
      return AnimatedTextState(
        opacity: k.opacity ?? clip.opacity,
        offsetX: (k.x ?? clip.x) - clip.x,
        offsetY: (k.y ?? clip.y) - clip.y,
        scale: k.scale ?? clip.scale,
        rotation: k.rotation ?? clip.rotation,
      );
    }

    final k1 = sorted[nextIndex - 1];
    final k2 = sorted[nextIndex];
    double t = (timeOffset - k1.timeOffset) / (k2.timeOffset - k1.timeOffset);

    t = _applyEasing(t, k1.easing, k1);

    return AnimatedTextState(
      opacity: _lerp(k1.opacity ?? clip.opacity, k2.opacity ?? clip.opacity, t),
      offsetX: _lerp(k1.x ?? clip.x, k2.x ?? clip.x, t) - clip.x,
      offsetY: _lerp(k1.y ?? clip.y, k2.y ?? clip.y, t) - clip.y,
      scale: _lerp(k1.scale ?? clip.scale, k2.scale ?? clip.scale, t),
      rotation: _lerp(k1.rotation ?? clip.rotation, k2.rotation ?? clip.rotation, t),
    );
  }

  static double _lerp(double a, double b, double t) => a + (b - a) * t;

  static AnimatedTextState _evaluateLoop(AnimationType type, int timeMs, int duration) {
    final t = (timeMs % duration) / duration;
    switch (type) {
      case AnimationType.pulse:
        return AnimatedTextState(scale: 1.0 + 0.1 * sin(2 * pi * t));
      case AnimationType.bounce:
        return AnimatedTextState(offsetY: -0.05 * (sin(pi * t)).abs());
      case AnimationType.shake:
        return AnimatedTextState(offsetX: 0.01 * sin(10 * 2 * pi * t));
      case AnimationType.wobble:
        return AnimatedTextState(rotation: 5.0 * sin(2 * pi * t));
      case AnimationType.swing:
        return AnimatedTextState(rotation: 10.0 * sin(2 * pi * t));
      case AnimationType.spin:
        return AnimatedTextState(rotation: 360.0 * t);
      default:
        return const AnimatedTextState();
    }
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


  static double _applyEasing(double t, EasingType easing, [Keyframe? keyframe]) {
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
      case EasingType.custom:
        return _solveCubicBezier(t, keyframe?.cp1x ?? 0.42, keyframe?.cp1y ?? 0.0, keyframe?.cp2x ?? 0.58, keyframe?.cp2y ?? 1.0);
      case EasingType.graph:
        return _solveGraph(t, keyframe?.customGraphPoints);
    }
  }

  static double _solveGraph(double t, List<double>? points) {
    if (points == null || points.isEmpty) return t;
    
    final nodes = <Offset>[const Offset(0, 0)];
    for (int i = 0; i < points.length; i += 2) {
      if (i + 1 < points.length) {
        nodes.add(Offset(points[i], points[i + 1]));
      }
    }
    nodes.add(const Offset(1, 1));
    nodes.sort((a, b) => a.dx.compareTo(b.dx));

    final n = nodes.length;
    if (n < 2) return t;

    // Compute slopes
    final ms = List.filled(n - 1, 0.0);
    for (int i = 0; i < n - 1; i++) {
        final dx = nodes[i+1].dx - nodes[i].dx;
        ms[i] = dx == 0 ? 0 : (nodes[i+1].dy - nodes[i].dy) / dx;
    }

    // Compute tangents (Monotone Cubic Hermite Spline)
    final ds = List.filled(n, 0.0);
    ds[0] = ms[0];
    ds[n - 1] = ms[n - 2];
    for (int i = 1; i < n - 1; i++) {
        if (ms[i-1] * ms[i] <= 0) {
            ds[i] = 0;
        } else {
            ds[i] = (ms[i-1] + ms[i]) / 2.0;
        }
    }

    // Find segment
    int idx = 0;
    while (idx < n - 2 && t > nodes[idx + 1].dx) idx++;

    final p1 = nodes[idx];
    final p2 = nodes[idx + 1];
    final h = p2.dx - p1.dx;
    if (h.abs() < 1e-6) return p2.dy;

    final lt = (t - p1.dx) / h;
    final lt2 = lt * lt;
    final lt3 = lt2 * lt;

    return (2 * lt3 - 3 * lt2 + 1) * p1.dy +
           (lt3 - 2 * lt2 + lt) * h * ds[idx] +
           (-2 * lt3 + 3 * lt2) * p2.dy +
           (lt3 - lt2) * h * ds[idx + 1];
  }

  static double _solveCubicBezier(double x, double x1, double y1, double x2, double y2) {
    if (x <= 0) return 0;
    if (x >= 1) return 1;

    // Numerical solution for t given x
    double t = x;
    for (int i = 0; i < 8; i++) {
      final currentX = _sampleBezier(t, x1, x2);
      final derivative = _sampleBezierDerivative(t, x1, x2);
      if (derivative.abs() < 1e-6) break;
      t -= (currentX - x) / derivative;
      t = t.clamp(0.0, 1.0);
    }

    return _sampleBezier(t, y1, y2);
  }

  static double _sampleBezier(double t, double p1, double p2) {
    return 3 * p1 * t * pow(1 - t, 2) + 3 * p2 * pow(t, 2) * (1 - t) + pow(t, 3);
  }

  static double _sampleBezierDerivative(double t, double p1, double p2) {
    return (3 * p1 * pow(1 - t, 2)) - (6 * p1 * t * (1 - t)) + (6 * p2 * t * (1 - t)) - (3 * p2 * pow(t, 2)) + (3 * pow(t, 2));
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
