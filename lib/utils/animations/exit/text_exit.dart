import '../base/animated_text_state.dart';

/// Text-specific exit animations: smoothSlideUp, staggeredSlideUp.
AnimatedTextState evaluateSmoothSlideUpExit(double t) {
  return AnimatedTextState(typewriterProgress: 1.0 - t);
}

AnimatedTextState evaluateStaggeredSlideUpExit(double t) {
  return AnimatedTextState(typewriterProgress: 1.0 - t);
}
