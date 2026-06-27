import 'dart:math';
import '../../../models/editor_models.dart';
import 'layout_core.dart';

class StairsLayout implements KineticLayout {
  @override
  List<LayoutPos> calculate(int count, List<SubtitleClip> group, double aspectRatio, Random random) {
    return List.generate(count, (i) {
      final step = i / (count > 1 ? count - 1 : 1);
      return LayoutPos(0.2 + step * 0.6, 0.2 + step * 0.6);
    });
  }
}
