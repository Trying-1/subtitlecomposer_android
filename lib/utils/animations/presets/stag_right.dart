import '../../../models/editor_models.dart';
import 'animation_presets.dart';

const stagRightPreset = AnimationPreset(
  name: 'Stag Right',
  icon: '⇉',
  entrance: ClipAnimation(type: AnimationType.staggeredSlideFromRight, durationMs: 1000, easing: EasingType.easeOut),
  exit: ClipAnimation(type: AnimationType.staggeredSlideFromRight, durationMs: 600, easing: EasingType.easeIn),
);
