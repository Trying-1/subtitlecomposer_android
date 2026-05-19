import 'dart:math';
import '../base/animated_text_state.dart';

AnimatedTextState evaluatePulse(double angle) {
  return AnimatedTextState(scale: 1.0 + 0.1 * sin(angle));
}
