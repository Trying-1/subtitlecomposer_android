import '../../../models/editor_models.dart';
import 'animation_presets.dart';

const edgeRightPreset = AnimationPreset(
  name: 'Edge Right',
  icon: '➡',
  entrance: ClipAnimation(type: AnimationType.slideFromRight, durationMs: 700, easing: EasingType.easeOut),
  exit: ClipAnimation(type: AnimationType.slideFromRight, durationMs: 500, easing: EasingType.easeIn),
);
