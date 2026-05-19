import '../../../../models/editor_models.dart';
import 'animation_presets.dart';

const bouncePreset = AnimationPreset(
  name: 'Bounce',
  icon: '⚡',
  entrance: ClipAnimation(type: AnimationType.bounceIn, durationMs: 500, easing: EasingType.bounceOut),
  exit: ClipAnimation(type: AnimationType.fadeOut, durationMs: 300, easing: EasingType.easeIn),
);
