import '../base/animated_text_state.dart';

AnimatedTextState evaluateStaggeredSlideUp(double t) {
  return AnimatedTextState(typewriterProgress: 1.0 - t);
}
