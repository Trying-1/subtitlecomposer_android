import 'dart:math';
import '../base/animated_text_state.dart';

AnimatedTextState evaluateShake(double angle) {
  const freq = 15.0;
  const intensity = 0.01;
  return AnimatedTextState(
    offsetX: sin(angle * freq) * intensity,
  );
}
