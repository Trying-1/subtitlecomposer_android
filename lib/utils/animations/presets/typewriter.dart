import '../../../../models/editor_models.dart';
import 'animation_presets.dart';

const typewriterPreset = AnimationPreset(
  name: 'Typewriter',
  icon: '⌨',
  entrance: ClipAnimation(type: AnimationType.typewriter, durationMs: 800, easing: EasingType.linear),
  exit: ClipAnimation(type: AnimationType.fadeOut, durationMs: 300, easing: EasingType.easeIn),
);
