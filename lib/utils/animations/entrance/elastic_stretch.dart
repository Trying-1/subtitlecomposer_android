import 'dart:math';
import '../../base/animated_text_state.dart';
import '../../easing/easing_functions.dart';
import '../../../models/editor_models.dart';

AnimatedTextState evaluateElasticStretch(double t) {
  final easeT = EasingFunctions.applyEasing(t, EasingType.easeOut);
  final elasticT = EasingFunctions.applyEasing(t, EasingType.elasticOut);
  
  final offsetY = -0.3 * (1.0 - elasticT);
  final scaleX = 1.0 - 0.4 * (1.0 - easeT) * cos(t * pi);
  final scaleY = 1.0 + 0.6 * (1.0 - easeT) * cos(t * pi);
  
  return AnimatedTextState(
    opacity: t.clamp(0.0, 1.0),
    offsetY: offsetY,
    scaleX: scaleX,
    scaleY: scaleY,
  );
}
