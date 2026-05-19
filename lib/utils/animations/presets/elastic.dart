import '../../../../models/editor_models.dart';
import 'animation_presets.dart';

const elasticPreset = AnimationPreset(
  name: 'Elastic',
  icon: '🔮',
  entrance: ClipAnimation(type: AnimationType.scaleUp, durationMs: 600, easing: EasingType.elasticOut),
  exit: ClipAnimation(type: AnimationType.scaleDown, durationMs: 300, easing: EasingType.easeIn),
);
