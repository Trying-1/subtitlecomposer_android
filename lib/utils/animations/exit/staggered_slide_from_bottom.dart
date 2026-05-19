import '../base/animated_text_state.dart';

AnimatedTextState evaluateStaggeredSlideFromBottom(double t) {
  return AnimatedTextState(typewriterProgress: 1.0 - t);
}
