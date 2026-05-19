import 'dart:math';
import '../../models/editor_models.dart';
import '../base/animated_text_state.dart';
import 'shake.dart';
import 'wobble.dart';
import 'bounce.dart';
import 'swing.dart';
import 'pulse.dart';
import 'heartbeat.dart';
import 'jello.dart';
import 'spin.dart';
import 'wavy_bend.dart';
import 'ripple.dart';

/// Loop animation registry.
/// Dispatches to the individual animation files.
class LoopRegistry {
  static AnimatedTextState evaluate(AnimationType type, int timeMs, int durationMs) {
    final safeD = durationMs > 0 ? durationMs : 100;
    final speedFactor = 1000.0 / safeD.toDouble();
    final angle = (timeMs / 1000.0) * 2.0 * pi * speedFactor;

    return switch (type) {
      AnimationType.shake => evaluateShake(angle),
      AnimationType.wobble => evaluateWobble(angle),
      AnimationType.bounce => evaluateBounce(angle),
      AnimationType.swing => evaluateSwing(angle),
      AnimationType.pulse => evaluatePulse(angle),
      AnimationType.heartbeat => evaluateHeartbeat(timeMs / 1000.0, speedFactor),
      AnimationType.jello => evaluateJello(angle),
      AnimationType.spin => evaluateSpin(timeMs, durationMs),
      AnimationType.wavyBend => evaluateWavyBend(timeMs, durationMs),
      AnimationType.ripple => evaluateRipple(timeMs, durationMs),
      _ => const AnimatedTextState(),
    };
  }
}
