import '../base/animated_text_state.dart';

AnimatedTextState evaluateFlipX(double t) {
  return AnimatedTextState(scale: t, opacity: t);
}
