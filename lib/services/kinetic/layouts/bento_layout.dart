import 'dart:math';
import '../../../models/editor_models.dart';
import 'layout_core.dart';

/// High-end compact Bento Grid layout solver.
/// Packs co-visible items with exact mathematical touch, sharing bounding box edges.
class BentoLayout implements KineticLayout {
  @override
  List<LayoutPos> calculate(int count, List<SubtitleClip> group, double aspectRatio, Random random) {
    if (count <= 1) return [const LayoutPos(0.5, 0.5)];

    // 1. Estimate sizes for each item using pixel-perfect estimateBounds
    final List<double> ws = [];
    final List<double> hs = [];
    for (int i = 0; i < count; i++) {
      final bounds = estimateBounds(group[i], const LayoutPos(0.5, 0.5), aspectRatio);
      ws.add(bounds.width);
      hs.add(bounds.height);
    }

    // 2. Define rows. Each row is a list of clip indices.
    final List<List<int>> rows = [];
    if (count == 2) {
      rows.add([0]);
      rows.add([1]);
    } else if (count == 3) {
      rows.add([0, 1]);
      rows.add([2]);
    } else if (count == 4) {
      rows.add([0, 1]);
      rows.add([2, 3]);
    } else if (count == 5) {
      rows.add([0, 1]);
      rows.add([2]);
      rows.add([3, 4]);
    } else {
      // General case: pack in rows of 2
      for (int i = 0; i < count; i += 2) {
        if (i + 1 < count) {
          rows.add([i, i + 1]);
        } else {
          rows.add([i]);
        }
      }
    }

    // 3. Calculate heights of each row
    final List<double> rowHeights = [];
    for (final row in rows) {
      double maxH = 0.0;
      for (final idx in row) {
        maxH = max(maxH, hs[idx]);
      }
      rowHeights.add(maxH);
    }

    // Total height of the entire block: sum of row heights.
    double totalBlockHeight = 0.0;
    for (final h in rowHeights) {
      totalBlockHeight += h;
    }

    // Y center is 0.5. So top of block is:
    double currentY = 0.5 - (totalBlockHeight / 2);

    // Solve Y positions and Row X positions
    final List<double> solvedY = List.filled(count, 0.5);
    final List<double> solvedX = List.filled(count, 0.5);

    for (int r = 0; r < rows.length; r++) {
      final row = rows[r];
      final rowH = rowHeights[r];
      final rowCenterY = currentY + (rowH / 2);

      // Width of the row is the sum of item widths in the row.
      double totalRowWidth = 0.0;
      for (final idx in row) {
        totalRowWidth += ws[idx];
      }

      // X center is 0.5. So left of row is:
      double currentX = 0.5 - (totalRowWidth / 2);

      for (final idx in row) {
        final itemW = ws[idx];
        solvedX[idx] = currentX + (itemW / 2);
        solvedY[idx] = rowCenterY;
        currentX += itemW; // Perfect horizontal touching (shares edge!)
      }

      currentY += rowH; // Perfect vertical touching (shares edge!)
    }

    return List.generate(count, (i) => LayoutPos(solvedX[i], solvedY[i]));
  }
}
