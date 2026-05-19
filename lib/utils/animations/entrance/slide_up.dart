import '../base/animated_text_state.dart';

AnimatedTextState evaluateSlideUp(double t) {
  return AnimatedTextState(offsetY: 0.3 * (1.0 - t));
}
