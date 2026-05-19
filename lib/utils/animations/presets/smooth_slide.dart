import '../../../../models/editor_models.dart';
import 'animation_presets.dart';

const smoothSlidePreset = AnimationPreset(
  name: 'Smooth Slide',
  icon: '✨',
  entrance: ClipAnimation(type: AnimationType.smoothSlideUp, durationMs: 800, easing: EasingType.easeOut),
  exit: ClipAnimation(type: AnimationType.fadeOut, durationMs: 300, easing: EasingType.easeIn),
);
