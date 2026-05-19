import '../../../../models/editor_models.dart';
import 'animation_presets.dart';

const stagTopPreset = AnimationPreset(
  name: 'Stag Top',
  icon: '⏬',
  entrance: ClipAnimation(type: AnimationType.staggeredSlideFromTop, durationMs: 1000, easing: EasingType.easeOut),
  exit: ClipAnimation(type: AnimationType.staggeredSlideFromTop, durationMs: 600, easing: EasingType.easeIn),
);
