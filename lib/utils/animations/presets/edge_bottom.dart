import '../../../../models/editor_models.dart';
import 'animation_presets.dart';

const edgeBottomPreset = AnimationPreset(
  name: 'Edge Bottom',
  icon: '⏫',
  entrance: ClipAnimation(type: AnimationType.slideFromBottom, durationMs: 700, easing: EasingType.easeOut),
  exit: ClipAnimation(type: AnimationType.slideFromBottom, durationMs: 500, easing: EasingType.easeIn),
);
