import '../base/animated_text_state.dart';

AnimatedTextState evaluateRotateIn(double t) {
  return AnimatedTextState(rotation: -360.0 * (1.0 - t), opacity: t, scale: t);
}
