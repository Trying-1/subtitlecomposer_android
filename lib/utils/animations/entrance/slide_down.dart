import '../base/animated_text_state.dart';

AnimatedTextState evaluateSlideDown(double t) {
  return AnimatedTextState(offsetY: -0.3 * (1.0 - t));
}
