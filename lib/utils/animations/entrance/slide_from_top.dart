import '../base/animated_text_state.dart';

AnimatedTextState evaluateSlideFromTop(double t) {
  return AnimatedTextState(offsetY: -1.0 * (1.0 - t));
}
