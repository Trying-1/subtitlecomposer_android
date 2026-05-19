import '../base/animated_text_state.dart';

AnimatedTextState evaluateFlipY(double t) {
  return AnimatedTextState(scale: t, opacity: t);
}
