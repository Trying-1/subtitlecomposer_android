import '../base/animated_text_state.dart';

AnimatedTextState evaluateThrowback(double t) {
  final scale = 1.0 + 3.0 * (1.0 - t);
  return AnimatedTextState(scale: scale, opacity: t);
}
