import 'dart:math';
import '../../../models/editor_models.dart';
import 'layout_core.dart';

class WaveLayout implements KineticLayout {
  @override
  List<LayoutPos> calculate(int count, List<SubtitleClip> group, double aspectRatio, Random random) {
    return List.generate(count, (i) {
      final t = i / (count > 1 ? count - 1 : 1);
      final px = 0.15 + t * 0.7;
      final py = 0.5 + sin(i * 0.8) * 0.2;
      return LayoutPos(px, py);
    });
  }
}
