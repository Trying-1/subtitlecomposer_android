import '../base/animated_text_state.dart';

/// Edge-based entrance animations: slideFromTop, slideFromBottom, and their staggered variants.
AnimatedTextState evaluateSlideFromTopEntrance(double t) {
  return AnimatedTextState(offsetY: -1.0 * (1.0 - t));
}

AnimatedTextState evaluateSlideFromBottomEntrance(double t) {
  return AnimatedTextState(offsetY: 1.0 * (1.0 - t));
}

/// Staggered variants use typewriterProgress for per-word reveal.
AnimatedTextState evaluateStaggeredSlideFromTopEntrance(double t) {
  return AnimatedTextState(typewriterProgress: t);
}

AnimatedTextState evaluateStaggeredSlideFromBottomEntrance(double t) {
  return AnimatedTextState(typewriterProgress: t);
}

AnimatedTextState evaluateSlideFromLeftEntrance(double t) {
  return AnimatedTextState(offsetX: -1.0 * (1.0 - t));
}

AnimatedTextState evaluateSlideFromRightEntrance(double t) {
  return AnimatedTextState(offsetX: 1.0 * (1.0 - t));
}

AnimatedTextState evaluateStaggeredSlideFromLeftEntrance(double t) {
  return AnimatedTextState(typewriterProgress: t);
}

AnimatedTextState evaluateStaggeredSlideFromRightEntrance(double t) {
  return AnimatedTextState(typewriterProgress: t);
}
