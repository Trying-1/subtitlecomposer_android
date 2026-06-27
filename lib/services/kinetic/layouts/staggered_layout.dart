import 'dart:math';
import '../../../models/editor_models.dart';
import 'layout_core.dart';

class StaggeredLayout implements KineticLayout {
  @override
  List<LayoutPos> calculate(int count, List<SubtitleClip> group, double aspectRatio, Random random) {
    return List.generate(count, (i) {
      final offset = (i % 2 == 0) ? -0.18 : 0.18;
      return LayoutPos(0.5 + offset, 0.15 + (i * (0.7 / count)));
    });
  }
}
