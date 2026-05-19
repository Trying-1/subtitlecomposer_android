import '../../../../models/editor_models.dart';
import 'animation_presets.dart';

const spinInPreset = AnimationPreset(
  name: 'Spin In',
  icon: '🌀',
  entrance: ClipAnimation(type: AnimationType.rotateIn, durationMs: 600, easing: EasingType.easeOut),
  exit: ClipAnimation(type: AnimationType.fadeOut, durationMs: 300, easing: EasingType.easeIn),
);
