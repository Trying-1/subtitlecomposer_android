import 'dart:math';
import '../../models/editor_models.dart';
import 'kinetic_style.dart';

/// Assigns entrance and exit animations to subtitle clips
/// based on the kinetic style configuration.
class AnimationAssigner {
  final Random _random;

  AnimationAssigner({int? seed}) : _random = Random(seed ?? DateTime.now().millisecondsSinceEpoch);

  /// Assigns entrance and exit animations to each clip.
  /// Ensures no two adjacent clips use the same entrance animation.
  List<SubtitleClip> assign(List<SubtitleClip> clips, KineticStyle style) {
    if (clips.isEmpty) return clips;

    final List<SubtitleClip> result = [];
    int lastEntranceIndex = -1;

    for (int i = 0; i < clips.length; i++) {
      final clip = clips[i];

      // --- Entrance animation: random from pool, avoid adjacent repeats ---
      int entranceIndex = _random.nextInt(style.entrancePool.length);
      if (style.entrancePool.length > 1) {
        while (entranceIndex == lastEntranceIndex) {
          entranceIndex = _random.nextInt(style.entrancePool.length);
        }
      }
      lastEntranceIndex = entranceIndex;
      final entranceType = style.entrancePool[entranceIndex];

      // --- Exit animation: pick complementary or random from pool ---
      final exitType = _getComplementaryExit(entranceType, style.exitPool);

      // --- Duration: scale with clip length, but cap at style default ---
      final clipDurationMs = clip.duration.inMilliseconds;
      final animDuration = min(style.animationDurationMs, (clipDurationMs * 0.3).round());
      final effectiveDuration = max(animDuration, 150); // Minimum 150ms

      result.add(clip.copyWith(
        entranceAnimation: style.enableEntranceAnimation
            ? ClipAnimation(
                type: entranceType,
                easing: EasingType.easeOut,
                durationMs: effectiveDuration,
                intensity: 1.0,
              )
            : const ClipAnimation(),
        exitAnimation: style.enableExitAnimation
            ? ClipAnimation(
                type: exitType,
                easing: EasingType.easeIn,
                durationMs: effectiveDuration,
                intensity: 1.0,
              )
            : const ClipAnimation(),
      ));
    }

    return result;
  }

  /// Gets a complementary exit animation for the given entrance type.
  /// Falls back to random from the exit pool if no complement exists.
  AnimationType _getComplementaryExit(AnimationType entrance, List<AnimationType> exitPool) {
    // Define natural complements
    final complements = <AnimationType, AnimationType>{
      AnimationType.slideUp: AnimationType.slideDown,
      AnimationType.slideDown: AnimationType.slideUp,
      AnimationType.slideLeft: AnimationType.slideRight,
      AnimationType.slideRight: AnimationType.slideLeft,
      AnimationType.scaleUp: AnimationType.scaleDown,
      AnimationType.scaleDown: AnimationType.scaleUp,
      AnimationType.zoomIn: AnimationType.zoomOut,
      AnimationType.zoomOut: AnimationType.zoomIn,
      AnimationType.fadeIn: AnimationType.fadeOut,
      AnimationType.smoothSlideUp: AnimationType.slideDown,
      AnimationType.slideFromTop: AnimationType.slideDown,
      AnimationType.slideFromBottom: AnimationType.slideUp,
      AnimationType.slideFromLeft: AnimationType.slideRight,
      AnimationType.slideFromRight: AnimationType.slideLeft,
      AnimationType.staggeredSlideUp: AnimationType.slideDown,
      AnimationType.staggeredSlideFromTop: AnimationType.slideDown,
      AnimationType.staggeredSlideFromBottom: AnimationType.slideUp,
      AnimationType.staggeredSlideFromLeft: AnimationType.slideRight,
      AnimationType.staggeredSlideFromRight: AnimationType.slideLeft,
      AnimationType.rotateIn: AnimationType.fadeOut,
      AnimationType.flipX: AnimationType.fadeOut,
      AnimationType.flipY: AnimationType.fadeOut,
      AnimationType.gradientWipe: AnimationType.fadeOut,
      AnimationType.radialWipe: AnimationType.fadeOut,
      AnimationType.wavyBend: AnimationType.fadeOut,
      AnimationType.ripple: AnimationType.fadeOut,
      AnimationType.elasticStretch: AnimationType.scaleDown,
      AnimationType.spiralDrop: AnimationType.zoomOut,
      AnimationType.glitch: AnimationType.fadeOut,
      AnimationType.typewriter: AnimationType.fadeOut,
      AnimationType.throwback: AnimationType.zoomOut,
      AnimationType.spin3D: AnimationType.zoomOut,
      AnimationType.flip3D_X: AnimationType.fadeOut,
      AnimationType.flip3D_Y: AnimationType.fadeOut,
    };

    // Try complement first
    final complement = complements[entrance];
    if (complement != null && exitPool.contains(complement)) {
      return complement;
    }

    // Fallback: random from exit pool
    return exitPool[_random.nextInt(exitPool.length)];
  }
}
