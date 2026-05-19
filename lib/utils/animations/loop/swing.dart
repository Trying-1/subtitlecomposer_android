import 'dart:math';
import '../base/animated_text_state.dart';

AnimatedTextState evaluateSwing(double angle) {
  return AnimatedTextState(rotation: 10.0 * sin(angle));
}
