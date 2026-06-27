import 'dart:math';
import '../../../models/editor_models.dart';
import 'layout_core.dart';

/// Masonry Brick Wall layout solver.
class MasonryLayout implements KineticLayout {
  @override
  List<LayoutPos> calculate(int count, List<SubtitleClip> group, double aspectRatio, Random random) {
    if (count <= 1) return [const LayoutPos(0.5, 0.5)];

    final List<double> ws = [];
    final List<double> hs = [];
    for (int i = 0; i < count; i++) {
      final bounds = estimateBounds(group[i], const LayoutPos(0.5, 0.5), aspectRatio);
      ws.add(bounds.width);
      hs.add(bounds.height);
    }

    final List<List<int>> rows = [];
    int itemsPerRow = count <= 4 ? 2 : 3;
    for (int i = 0; i < count; i += itemsPerRow) {
      rows.add(List.generate(min(itemsPerRow, count - i), (index) => i + index));
    }

    final List<double> rowHeights = [];
    for (final row in rows) {
      double maxH = 0.0;
      for (final idx in row) maxH = max(maxH, hs[idx]);
      rowHeights.add(maxH);
    }

    double totalBlockHeight = 0.0;
    for (final h in rowHeights) totalBlockHeight += h;

    double currentY = 0.5 - (totalBlockHeight / 2);
    final List<double> solvedY = List.filled(count, 0.5);
    final List<double> solvedX = List.filled(count, 0.5);

    for (int r = 0; r < rows.length; r++) {
      final row = rows[r];
      final rowH = rowHeights[r];
      final rowCenterY = currentY + (rowH / 2);

      double totalRowWidth = 0.0;
      for (final idx in row) totalRowWidth += ws[idx];

      // Masonry offset: alternate row starts slightly
      double offsetX = (r % 2 == 1) ? 0.05 : -0.05;
      double currentX = 0.5 - (totalRowWidth / 2) + offsetX;

      for (final idx in row) {
        final itemW = ws[idx];
        solvedX[idx] = currentX + (itemW / 2);
        solvedY[idx] = rowCenterY;
        currentX += itemW; 
      }
      currentY += rowH; 
    }

    return List.generate(count, (i) => LayoutPos(solvedX[i], solvedY[i]));
  }
}
