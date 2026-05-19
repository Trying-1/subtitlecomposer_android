import 'dart:math';
import '../base/animated_text_state.dart';

/// Motion-based loop animations: shake, bounce, wobble, swing.
AnimatedTextState evaluateShakeLoop(double angle) {
  final freq = 15.0;
  final intensity = 0.01;
  return AnimatedTextState(
    offsetX: sin(angle * freq) * intensity,
  );
}

AnimatedTextState evaluateBounceLoop(double angle) {
  return AnimatedTextState(offsetY: -0.05 * (sin(pi * ((angle / (2 * pi)) % 1.0))).abs());
}

AnimatedTextState evaluateWobbleLoop(double angle) {
  return AnimatedTextState(rotation: 5.0 * sin(angle));
}

AnimatedTextState evaluateSwingLoop(double angle) {
  return AnimatedTextState(rotation: 10.0 * sin(angle));
}
