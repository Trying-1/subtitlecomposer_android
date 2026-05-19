import '../base/animated_text_state.dart';

AnimatedTextState evaluateSlideFromBottom(double t) {
  return AnimatedTextState(offsetY: 1.0 * t);
}
