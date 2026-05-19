import '../base/animated_text_state.dart';

AnimatedTextState evaluateScaleDown(double t) {
  return AnimatedTextState(scale: 2.0 - t, opacity: t);
}
