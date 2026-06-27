import 'dart:math';
import '../../../models/editor_models.dart';
import 'layout_core.dart';

class CircleLayout implements KineticLayout {
  @override
  List<LayoutPos> calculate(int count, List<SubtitleClip> group, double aspectRatio, Random random) {
    const radius = 0.25;
    return List.generate(count, (i) {
      final angle = (i / count) * 2.0 * pi;
      return LayoutPos(0.5 + cos(angle) * radius, 0.5 + sin(angle) * radius);
    });
  }
}
