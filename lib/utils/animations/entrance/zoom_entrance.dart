import '../base/animated_text_state.dart';

/// Zoom and flip entrance animations: zoomIn, zoomOut, flipX, flipY.
AnimatedTextState evaluateZoomInEntrance(double t) {
  return AnimatedTextState(scale: t * t, opacity: t);
}

AnimatedTextState evaluateZoomOutEntrance(double t) {
  return AnimatedTextState(scale: 1.0 + (1.0 - t) * 2.0, opacity: t);
}

AnimatedTextState evaluateFlipXEntrance(double t) {
  // flipX is handled via scaleX on native side; Dart side uses scale as proxy
  return AnimatedTextState(scale: t, opacity: t);
}

AnimatedTextState evaluateFlipYEntrance(double t) {
  // flipY is handled via scaleY on native side; Dart side uses scale as proxy
  return AnimatedTextState(scale: t, opacity: t);
}
