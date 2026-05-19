import '../../../../models/editor_models.dart';
import 'animation_presets.dart';

const slideLeftPreset = AnimationPreset(
  name: 'Slide Left',
  icon: '⬅',
  entrance: ClipAnimation(type: AnimationType.slideLeft, durationMs: 400, easing: EasingType.easeOut),
  exit: ClipAnimation(type: AnimationType.slideRight, durationMs: 300, easing: EasingType.easeIn),
);
