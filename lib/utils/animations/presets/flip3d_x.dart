import '../../../../models/editor_models.dart';
import 'animation_presets.dart';

const flip3D_XPreset = AnimationPreset(
  name: '3D Flip X',
  icon: '🔁',
  entrance: ClipAnimation(type: AnimationType.flip3D_X, durationMs: 750, easing: EasingType.easeOut),
  exit: ClipAnimation(type: AnimationType.fadeOut, durationMs: 250, easing: EasingType.easeIn),
);
