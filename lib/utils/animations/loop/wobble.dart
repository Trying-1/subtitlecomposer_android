import 'dart:math';
import '../base/animated_text_state.dart';

AnimatedTextState evaluateWobble(double angle) {
  return AnimatedTextState(rotation: 5.0 * sin(angle));
}
