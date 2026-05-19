import '../../../../models/editor_models.dart';
import 'animation_presets.dart';

const cinematicPreset = AnimationPreset(
  name: 'Cinematic',
  icon: '🎬',
  entrance: ClipAnimation(type: AnimationType.fadeIn, durationMs: 800, easing: EasingType.easeInOut),
  exit: ClipAnimation(type: AnimationType.fadeOut, durationMs: 800, easing: EasingType.easeInOut),
);
