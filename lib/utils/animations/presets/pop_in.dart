import '../../../../models/editor_models.dart';
import 'animation_presets.dart';

const popInPreset = AnimationPreset(
  name: 'Pop In',
  icon: '💥',
  entrance: ClipAnimation(type: AnimationType.scaleUp, durationMs: 300, easing: EasingType.bounceOut),
  exit: ClipAnimation(type: AnimationType.scaleDown, durationMs: 200, easing: EasingType.easeIn),
);
