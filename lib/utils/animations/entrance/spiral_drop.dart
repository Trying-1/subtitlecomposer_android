import '../base/animated_text_state.dart';
import '../easing/easing_functions.dart';
import '../../../models/editor_models.dart';

AnimatedTextState evaluateSpiralDrop(double t) {
  final elasticT = EasingFunctions.applyEasing(t, EasingType.elasticOut);
  
  final scale = 0.2 + 0.8 * elasticT;
  final rotation = -8.0 * (1.0 - elasticT); // Elegant micro-twist
  
  return AnimatedTextState(
    opacity: (t * 4.0).clamp(0.0, 1.0),
    scale: scale,
    rotation: rotation,
  );
}
