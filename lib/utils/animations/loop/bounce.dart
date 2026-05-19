import 'dart:math';
import '../base/animated_text_state.dart';

AnimatedTextState evaluateBounce(double angle) {
  return AnimatedTextState(offsetY: -0.05 * (sin(pi * ((angle / (2 * pi)) % 1.0))).abs());
}
