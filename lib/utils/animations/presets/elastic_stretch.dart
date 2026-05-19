import '../../../../models/editor_models.dart';
import 'animation_presets.dart';

const elasticStretchPreset = AnimationPreset(
  name: 'Motion Stretch',
  icon: '🧬',
  entrance: ClipAnimation(type: AnimationType.elasticStretch, durationMs: 700, easing: EasingType.linear),
  exit: ClipAnimation(type: AnimationType.scaleDown, durationMs: 300, easing: EasingType.easeIn),
);
