import 'dart:math';
import '../../../models/editor_models.dart';
import 'layout_core.dart';

class ExplosionLayout implements KineticLayout {
  @override
  List<LayoutPos> calculate(int count, List<SubtitleClip> group, double aspectRatio, Random random) {
    if (count <= 1) return [const LayoutPos(0.5, 0.5)];
    return List.generate(count, (i) {
      if (i == 0) return const LayoutPos(0.5, 0.5); // Center origin
      final angle = (i / (count - 1)) * 2 * pi;
      final distance = 0.3; // exploded outward
      return LayoutPos(0.5 + cos(angle) * distance, 0.5 + sin(angle) * distance);
    });
  }
}
