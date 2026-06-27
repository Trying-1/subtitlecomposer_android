import 'dart:math';
import '../../../models/editor_models.dart';
import 'layout_core.dart';

class RandomLayout implements KineticLayout {
  final double safeMin;
  final double safeMax;

  RandomLayout(this.safeMin, this.safeMax);

  @override
  List<LayoutPos> calculate(int count, List<SubtitleClip> group, double aspectRatio, Random random) {
    return List.generate(count, (_) {
      final x = safeMin + random.nextDouble() * (safeMax - safeMin);
      final y = safeMin + random.nextDouble() * (safeMax - safeMin);
      return LayoutPos(x, y);
    });
  }
}
