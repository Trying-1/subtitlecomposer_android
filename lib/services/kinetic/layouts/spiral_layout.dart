import 'dart:math';
import '../../../models/editor_models.dart';
import 'layout_core.dart';

class SpiralLayout implements KineticLayout {
  @override
  List<LayoutPos> calculate(int count, List<SubtitleClip> group, double aspectRatio, Random random) {
    return List.generate(count, (i) {
      final r = 0.05 + (i * 0.3 / count);
      final angle = i * 0.9;
      return LayoutPos(0.5 + cos(angle) * r, 0.5 + sin(angle) * r);
    });
  }
}
