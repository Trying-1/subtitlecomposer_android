import '../../../../models/editor_models.dart';
import 'animation_presets.dart';

const ripplePreset = AnimationPreset(
  name: 'Ripple',
  icon: '💧',
  entrance: ClipAnimation(type: AnimationType.ripple, durationMs: 800, easing: EasingType.easeOut),
  exit: ClipAnimation(type: AnimationType.ripple, durationMs: 500, easing: EasingType.easeIn),
);
