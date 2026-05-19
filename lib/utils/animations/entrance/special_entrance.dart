import '../base/animated_text_state.dart';

/// Special entrance animations: throwback, elasticDrop.
AnimatedTextState evaluateThrowbackEntrance(double t) {
  final scale = 4.0 - 3.0 * t;
  final opacity = t < 0.3 ? t / 0.3 : 1.0;
  return AnimatedTextState(scale: scale, opacity: opacity);
}

AnimatedTextState evaluateElasticDropEntrance(double t) {
  // Drop from off-screen top. Elastic easing is applied at the registry level.
  final dropOffset = -2.0 * (1.0 - t);
  final opacity = t < 0.1 ? t * 10.0 : 1.0;
  return AnimatedTextState(offsetY: dropOffset, opacity: opacity);
}
