import '../../../../models/editor_models.dart';
import 'animation_presets.dart';

const throwbackPreset = AnimationPreset(
  name: 'Throwback',
  icon: '🚀',
  entrance: ClipAnimation(type: AnimationType.throwback, durationMs: 600, easing: EasingType.easeOut),
  exit: ClipAnimation(type: AnimationType.throwback, durationMs: 400, easing: EasingType.easeIn),
);
