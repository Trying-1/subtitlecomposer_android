import '../base/animated_text_state.dart';

AnimatedTextState evaluateElasticDrop(double t) {
  final dropOffset = 2.0 * (1.0 - t);
  return AnimatedTextState(offsetY: dropOffset, opacity: t);
}
