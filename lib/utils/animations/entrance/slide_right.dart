import '../base/animated_text_state.dart';

AnimatedTextState evaluateSlideRight(double t) {
  return AnimatedTextState(offsetX: -0.5 * (1.0 - t));
}
