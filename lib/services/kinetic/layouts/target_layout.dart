import 'dart:math';
import '../../../models/editor_models.dart';
import 'layout_core.dart';

class TargetLayout implements KineticLayout {
  @override
  List<LayoutPos> calculate(int count, List<SubtitleClip> group, double aspectRatio, Random random) {
    if (count <= 1) return [const LayoutPos(0.5, 0.5)];
    return List.generate(count, (i) {
      if (i == 0) return const LayoutPos(0.5, 0.5); // Center
      final ring = ((i - 1) ~/ 4) + 1; // 4 items per ring
      final itemsInRing = min(4, count - 1 - ((ring - 1) * 4));
      final idxInRing = (i - 1) % 4;
      final radius = 0.15 * ring;
      final angle = (idxInRing / itemsInRing) * 2 * pi + (ring * 0.5);
      return LayoutPos(0.5 + cos(angle) * radius, 0.5 + sin(angle) * radius);
    });
  }
}
