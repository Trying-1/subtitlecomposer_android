import '../../../../models/editor_models.dart';
import 'animation_presets.dart';

const slideUpPreset = AnimationPreset(
  name: 'Slide Up',
  icon: '⬆',
  entrance: ClipAnimation(type: AnimationType.slideUp, durationMs: 400, easing: EasingType.easeOut),
  exit: ClipAnimation(type: AnimationType.slideDown, durationMs: 300, easing: EasingType.easeIn),
);
