import '../../../../models/editor_models.dart';
import 'animation_presets.dart';

const fadePreset = AnimationPreset(
  name: 'Fade',
  icon: '◐',
  entrance: ClipAnimation(type: AnimationType.fadeIn, durationMs: 400, easing: EasingType.easeOut),
  exit: ClipAnimation(type: AnimationType.fadeOut, durationMs: 400, easing: EasingType.easeIn),
);
