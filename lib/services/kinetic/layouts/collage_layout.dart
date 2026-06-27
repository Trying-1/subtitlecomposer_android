import 'dart:math';
import '../../../models/editor_models.dart';
import 'layout_core.dart';

class CollageLayout implements KineticLayout {
  @override
  List<LayoutPos> calculate(int count, List<SubtitleClip> group, double aspectRatio, Random random) {
    // Cluster in the center but very chaotic
    return List.generate(count, (i) {
      final r = random.nextDouble() * 0.25; // max radius from center
      final angle = random.nextDouble() * 2 * pi;
      return LayoutPos(0.5 + cos(angle) * r, 0.5 + sin(angle) * r);
    });
  }
}
