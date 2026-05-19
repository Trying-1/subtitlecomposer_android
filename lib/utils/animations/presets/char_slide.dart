import '../../../../models/editor_models.dart';
import 'animation_presets.dart';

const charSlidePreset = AnimationPreset(
  name: 'Char Slide',
  icon: '📏',
  entrance: ClipAnimation(type: AnimationType.staggeredSlideUp, durationMs: 800, easing: EasingType.easeOut),
  exit: ClipAnimation(type: AnimationType.fadeOut, durationMs: 300, easing: EasingType.easeIn),
);
