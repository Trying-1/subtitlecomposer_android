import '../base/animated_text_state.dart';

AnimatedTextState evaluateZoomIn(double t) {
  return AnimatedTextState(scale: t * t, opacity: t);
}
