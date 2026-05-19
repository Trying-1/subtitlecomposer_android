import '../../../../models/editor_models.dart';
import 'animation_presets.dart';

const glitchPreset = AnimationPreset(
  name: 'Pendulum Swing',
  icon: '⚡',
  entrance: ClipAnimation(type: AnimationType.glitch, durationMs: 650, easing: EasingType.linear),
  exit: ClipAnimation(type: AnimationType.fadeOut, durationMs: 250, easing: EasingType.easeIn),
);
