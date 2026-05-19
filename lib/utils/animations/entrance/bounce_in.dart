import '../base/animated_text_state.dart';

AnimatedTextState evaluateBounceIn(double t) {
  return AnimatedTextState(scale: t, offsetY: 0.2 * (1.0 - t));
}
