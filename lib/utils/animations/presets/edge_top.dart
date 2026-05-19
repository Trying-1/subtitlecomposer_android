import '../../../../models/editor_models.dart';
import 'animation_presets.dart';

const edgeTopPreset = AnimationPreset(
  name: 'Edge Top',
  icon: '⏬',
  entrance: ClipAnimation(type: AnimationType.slideFromTop, durationMs: 700, easing: EasingType.easeOut),
  exit: ClipAnimation(type: AnimationType.slideFromTop, durationMs: 500, easing: EasingType.easeIn),
);
