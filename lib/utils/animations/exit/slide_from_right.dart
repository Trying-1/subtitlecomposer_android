import '../base/animated_text_state.dart';

AnimatedTextState evaluateSlideFromRight(double t) {
  return AnimatedTextState(offsetX: 1.0 * t);
}
