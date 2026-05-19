import '../../../../models/editor_models.dart';
import 'animation_presets.dart';

const gradientWipePreset = AnimationPreset(
  name: 'Grad Wipe',
  icon: '🌓',
  entrance: ClipAnimation(type: AnimationType.gradientWipe, durationMs: 700, easing: EasingType.easeInOut),
  exit: ClipAnimation(type: AnimationType.gradientWipe, durationMs: 500, easing: EasingType.easeIn),
);
