import '../../../../models/editor_models.dart';
import 'animation_presets.dart';

const spin3DPreset = AnimationPreset(
  name: '3D Spin Zoom',
  icon: '🛸',
  entrance: ClipAnimation(type: AnimationType.spin3D, durationMs: 800, easing: EasingType.elasticOut),
  exit: ClipAnimation(type: AnimationType.scaleDown, durationMs: 300, easing: EasingType.easeIn),
);
