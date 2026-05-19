import '../base/animated_text_state.dart';

AnimatedTextState evaluateZoomOut(double t) {
  return AnimatedTextState(scale: 1.0 + (1.0 - t) * 2.0, opacity: t);
}
