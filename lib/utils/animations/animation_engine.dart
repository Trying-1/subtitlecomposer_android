import 'dart:math';
import '../../models/editor_models.dart';
import 'base/animated_text_state.dart';
import 'easing/easing_functions.dart';
import 'entrance/entrance_registry.dart';
import 'exit/exit_registry.dart';
import 'loop/loop_registry.dart';

/// Re-export AnimatedTextState so consumers of this file get it automatically.
export 'base/animated_text_state.dart';

/// The main animation orchestrator.
/// Slim coordinator that delegates type-specific logic to registries.
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
    double scaleX = 1.0;
    double scaleY = 1.0;
    double rotation = baseState.rotation;
    double rotationX = 0.0;
    double rotationY = 0.0;
    double typewriterProgress = 1.0;

    // === Entrance animation ===
    final entrance = clip.entranceAnimation;
    if (entrance.type != AnimationType.none && elapsed < entrance.durationMs) {
      final t = EasingFunctions.applyEasing(elapsed / entrance.durationMs, entrance.easing);
      final state = EntranceRegistry.evaluate(entrance.type, t);
      opacity *= state.opacity;
      offsetX += state.offsetX;
      offsetY += state.offsetY;
      scale *= state.scale;
      scaleX *= state.scaleX;
      scaleY *= state.scaleY;
      rotation += state.rotation;
      rotationX += state.rotationX;
      rotationY += state.rotationY;
      typewriterProgress = state.typewriterProgress;
    }

    // === Exit animation ===
    final exit = clip.exitAnimation;
    if (exit.type != AnimationType.none && remaining < exit.durationMs) {
      final t = EasingFunctions.applyEasing(remaining / exit.durationMs, exit.easing);
      final state = ExitRegistry.evaluate(exit.type, t);
      opacity *= state.opacity;
      offsetX += state.offsetX;
      offsetY += state.offsetY;
      scale *= state.scale;
      scaleX *= state.scaleX;
      scaleY *= state.scaleY;
      rotation += state.rotation;
      rotationX += state.rotationX;
      rotationY += state.rotationY;
    }

    // === Loop animation ===
    final loop = clip.loopAnimation;
    if (loop.type != AnimationType.none) {
      final state = LoopRegistry.evaluate(loop.type, currentTimeMs, loop.durationMs);
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
      scaleX: scaleX.clamp(0.01, 10.0),
      scaleY: scaleY.clamp(0.01, 10.0),
      rotation: rotation,
      rotationX: rotationX,
      rotationY: rotationY,
      typewriterProgress: typewriterProgress.clamp(0.0, 1.0),
    );
  }

  // ── Keyframe evaluation (kept here since it's orchestration logic) ──

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

    t = EasingFunctions.applyEasing(t, k1.easing, k1);

    return AnimatedTextState(
      opacity: _lerp(k1.opacity ?? clip.opacity, k2.opacity ?? clip.opacity, t),
      offsetX: _lerp(k1.x ?? clip.x, k2.x ?? clip.x, t) - clip.x,
      offsetY: _lerp(k1.y ?? clip.y, k2.y ?? clip.y, t) - clip.y,
      scale: _lerp(k1.scale ?? clip.scale, k2.scale ?? clip.scale, t),
      rotation: _lerp(k1.rotation ?? clip.rotation, k2.rotation ?? clip.rotation, t),
    );
  }

  static double _lerp(double a, double b, double t) => a + (b - a) * t;
}
