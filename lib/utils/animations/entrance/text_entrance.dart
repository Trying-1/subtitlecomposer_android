import '../base/animated_text_state.dart';

/// Text-specific entrance animations: typewriter, smoothSlideUp, staggeredSlideUp.
/// These use typewriterProgress to communicate per-character reveal to the renderer.
AnimatedTextState evaluateTypewriterEntrance(double t) {
  return AnimatedTextState(typewriterProgress: t);
}

AnimatedTextState evaluateSmoothSlideUpEntrance(double t) {
  return AnimatedTextState(typewriterProgress: t);
}

AnimatedTextState evaluateStaggeredSlideUpEntrance(double t) {
  return AnimatedTextState(typewriterProgress: t);
}
