import '../base/animated_text_state.dart';

/// Special exit animations: throwback, elasticDrop.
AnimatedTextState evaluateThrowbackExit(double t) {
  final scale = 1.0 + 3.0 * (1.0 - t);
  return AnimatedTextState(scale: scale, opacity: t);
}

AnimatedTextState evaluateElasticDropExit(double t) {
  final dropOffset = 2.0 * (1.0 - t);
  return AnimatedTextState(offsetY: dropOffset, opacity: t);
}
