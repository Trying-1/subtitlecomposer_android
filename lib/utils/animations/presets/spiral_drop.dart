import '../../../../models/editor_models.dart';
import 'animation_presets.dart';

const spiralDropPreset = AnimationPreset(
  name: 'Spring Zoom',
  icon: '🌀',
  entrance: ClipAnimation(type: AnimationType.spiralDrop, durationMs: 800, easing: EasingType.linear),
  exit: ClipAnimation(type: AnimationType.scaleDown, durationMs: 400, easing: EasingType.easeIn),
);
