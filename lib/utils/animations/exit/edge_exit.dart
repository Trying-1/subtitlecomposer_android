import '../base/animated_text_state.dart';

/// Edge-based exit animations: slideFromTop, slideFromBottom, and their staggered variants.
AnimatedTextState evaluateSlideFromTopExit(double t) {
  return AnimatedTextState(offsetY: -1.0 * t);
}

AnimatedTextState evaluateSlideFromBottomExit(double t) {
  return AnimatedTextState(offsetY: 1.0 * t);
}

AnimatedTextState evaluateStaggeredSlideFromTopExit(double t) {
  return AnimatedTextState(typewriterProgress: 1.0 - t);
}

AnimatedTextState evaluateStaggeredSlideFromBottomExit(double t) {
  return AnimatedTextState(typewriterProgress: 1.0 - t);
}
