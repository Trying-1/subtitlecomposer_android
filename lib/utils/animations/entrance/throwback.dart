import '../base/animated_text_state.dart';

AnimatedTextState evaluateThrowback(double t) {
  final scale = 4.0 - 3.0 * t;
  final opacity = t < 0.3 ? t / 0.3 : 1.0;
  return AnimatedTextState(scale: scale, opacity: opacity);
}
