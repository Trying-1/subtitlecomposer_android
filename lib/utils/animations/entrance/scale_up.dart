import '../base/animated_text_state.dart';

AnimatedTextState evaluateScaleUp(double t) {
  return AnimatedTextState(scale: t, opacity: t);
}
