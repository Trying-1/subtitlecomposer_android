import 'dart:math';
import '../../../models/editor_models.dart';
import 'layout_core.dart';

class ColumnLayout implements KineticLayout {
  @override
  List<LayoutPos> calculate(int count, List<SubtitleClip> group, double aspectRatio, Random random) {
    const gap = 0.12;
    final totalHeight = (count - 1) * gap;
    final startY = (1.0 - totalHeight) / 2;
    return List.generate(count, (i) => LayoutPos(0.5, startY + i * gap));
  }
}
