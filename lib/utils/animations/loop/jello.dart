import 'dart:math';
import '../base/animated_text_state.dart';

AnimatedTextState evaluateJello(double angle) {
  const intensity = 0.15;
  final s = sin(angle);
  return AnimatedTextState(scale: 1.0 + s * intensity);
}
