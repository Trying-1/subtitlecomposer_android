import '../../../models/editor_models.dart';
import 'animation_presets.dart';

const stagLeftPreset = AnimationPreset(
  name: 'Stag Left',
  icon: '⇇',
  entrance: ClipAnimation(type: AnimationType.staggeredSlideFromLeft, durationMs: 1000, easing: EasingType.easeOut),
  exit: ClipAnimation(type: AnimationType.staggeredSlideFromLeft, durationMs: 600, easing: EasingType.easeIn),
);
