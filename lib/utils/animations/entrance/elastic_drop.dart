import '../base/animated_text_state.dart';

AnimatedTextState evaluateElasticDrop(double t) {
  final dropOffset = -2.0 * (1.0 - t);
  final opacity = t < 0.1 ? t * 10.0 : 1.0;
  return AnimatedTextState(offsetY: dropOffset, opacity: opacity);
}
