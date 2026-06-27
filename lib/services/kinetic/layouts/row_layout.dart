import 'dart:math';
import '../../../models/editor_models.dart';
import 'layout_core.dart';

class RowLayout implements KineticLayout {
  @override
  List<LayoutPos> calculate(int count, List<SubtitleClip> group, double aspectRatio, Random random) {
    if (count == 0) return [];
    
    // 1. Calculate actual normalized widths of all words
    final widths = <double>[];
    for (var clip in group) {
      final rect = estimateBounds(clip, const LayoutPos(0.5, 0.5), aspectRatio);
      widths.add(rect.width);
    }
    
    // 2. Define a small uniform gap between words (approx space character)
    const spaceGap = 0.02; 
    
    // 3. Calculate total width of the entire sentence block
    final totalWidth = widths.fold(0.0, (sum, w) => sum + w) + (count - 1) * spaceGap;
    
    // 4. Position them side by side from left to right, centered as a block
    final positions = <LayoutPos>[];
    double currentLeftEdge = (1.0 - totalWidth) / 2;
    
    for (int i = 0; i < count; i++) {
      // The center of the word is its left edge + half its width
      final centerX = currentLeftEdge + (widths[i] / 2);
      positions.add(LayoutPos(centerX, 0.5));
      // Advance to the start of the next word
      currentLeftEdge += widths[i] + spaceGap;
    }
    
    return positions;
  }
}
