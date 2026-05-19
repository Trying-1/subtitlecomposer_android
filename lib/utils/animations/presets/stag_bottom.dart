import '../../../../models/editor_models.dart';
import 'animation_presets.dart';

const stagBottomPreset = AnimationPreset(
  name: 'Stag Bottom',
  icon: '⏫',
  entrance: ClipAnimation(type: AnimationType.staggeredSlideFromBottom, durationMs: 1000, easing: EasingType.easeOut),
  exit: ClipAnimation(type: AnimationType.staggeredSlideFromBottom, durationMs: 600, easing: EasingType.easeIn),
);
