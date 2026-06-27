import 'dart:math';
import '../../../models/editor_models.dart';
import 'layout_core.dart';

class GridLayout implements KineticLayout {
  @override
  List<LayoutPos> calculate(int count, List<SubtitleClip> group, double aspectRatio, Random random) {
    final cols = count <= 4 ? 2 : (count <= 9 ? 3 : 4);
    final rows = (count / cols).ceil();
    final cellW = 0.7 / cols;
    final cellH = 0.6 / rows;
    return List.generate(count, (i) {
      final r = i ~/ cols;
      final c = i % cols;
      return LayoutPos(0.15 + (c + 0.5) * cellW, 0.2 + (r + 0.5) * cellH);
    });
  }
}
