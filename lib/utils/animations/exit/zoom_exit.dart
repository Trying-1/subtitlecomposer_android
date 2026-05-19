import '../base/animated_text_state.dart';

/// Zoom and flip exit animations.
AnimatedTextState evaluateZoomInExit(double t) {
  return AnimatedTextState(scale: t * t, opacity: t);
}

AnimatedTextState evaluateZoomOutExit(double t) {
  return AnimatedTextState(scale: 1.0 + (1.0 - t) * 2.0, opacity: t);
}

AnimatedTextState evaluateFlipXExit(double t) {
  return AnimatedTextState(scale: t, opacity: t);
}

AnimatedTextState evaluateFlipYExit(double t) {
  return AnimatedTextState(scale: t, opacity: t);
}
