import '../../../../models/editor_models.dart';
import 'animation_presets.dart';

const wavyPreset = AnimationPreset(
  name: 'Wavy',
  icon: '🌊',
  entrance: ClipAnimation(type: AnimationType.wavyBend, durationMs: 800, easing: EasingType.easeOut),
  exit: ClipAnimation(type: AnimationType.wavyBend, durationMs: 500, easing: EasingType.easeIn),
);
