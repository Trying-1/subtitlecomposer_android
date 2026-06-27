import '../../../models/editor_models.dart';
import 'animation_presets.dart';

const edgeLeftPreset = AnimationPreset(
  name: 'Edge Left',
  icon: '⬅',
  entrance: ClipAnimation(type: AnimationType.slideFromLeft, durationMs: 700, easing: EasingType.easeOut),
  exit: ClipAnimation(type: AnimationType.slideFromLeft, durationMs: 500, easing: EasingType.easeIn),
);
