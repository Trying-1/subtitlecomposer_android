import '../../../../models/editor_models.dart';
import 'animation_presets.dart';

const radialWipePreset = AnimationPreset(
  name: 'Radial',
  icon: '⭕',
  entrance: ClipAnimation(type: AnimationType.radialWipe, durationMs: 600, easing: EasingType.easeOut),
  exit: ClipAnimation(type: AnimationType.radialWipe, durationMs: 400, easing: EasingType.easeIn),
);
