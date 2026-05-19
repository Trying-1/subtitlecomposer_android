import '../base/animated_text_state.dart';

/// Fade exit animations.
AnimatedTextState evaluateFadeOutExit(double t) {
  return AnimatedTextState(opacity: t);
}

/// fadeIn used as exit (opacity ramp down).
AnimatedTextState evaluateFadeInExit(double t) {
  return AnimatedTextState(opacity: t);
}
