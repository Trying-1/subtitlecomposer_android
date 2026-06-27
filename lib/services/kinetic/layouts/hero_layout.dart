import 'dart:math';
import '../../../models/editor_models.dart';
import 'layout_core.dart';

/// Hero layout: index 0 in center, remaining placed dynamically in the 4 surrounding quadrants
class HeroLayout implements KineticLayout {
  @override
  List<LayoutPos> calculate(int count, List<SubtitleClip> group, double aspectRatio, Random random) {
    if (count <= 1) return [const LayoutPos(0.5, 0.5)];
    
    final List<LayoutPos> positions = List.filled(count, const LayoutPos(0.5, 0.5));
    
    // Estimate bounds of the massive center hero
    final heroBounds = estimateBounds(group[0], const LayoutPos(0.5, 0.5), aspectRatio);
    
    for (int i = 1; i < count; i++) {
      final int posType = (i - 1) % 4;
      final int ringOffset = (i - 1) ~/ 4;
      
      // Calculate the geometric centers of the 4 empty quadrants around the hero text
      final double topLeftX = heroBounds.left / 2;
      final double topLeftY = heroBounds.top / 2;
      
      final double bottomRightX = heroBounds.right + (1.0 - heroBounds.right) / 2;
      final double bottomRightY = heroBounds.bottom + (1.0 - heroBounds.bottom) / 2;
      
      final double topRightX = heroBounds.right + (1.0 - heroBounds.right) / 2;
      final double topRightY = heroBounds.top / 2;
      
      final double bottomLeftX = heroBounds.left / 2;
      final double bottomLeftY = heroBounds.bottom + (1.0 - heroBounds.bottom) / 2;
      
      // Expand outward if many clips (distribute radially within quadrant)
      final double ringExpX = ringOffset * 0.05;
      final double ringExpY = ringOffset * 0.05;
      
      if (posType == 0) {
        positions[i] = LayoutPos(topLeftX - ringExpX, topLeftY - ringExpY);
      } else if (posType == 1) {
        positions[i] = LayoutPos(bottomRightX + ringExpX, bottomRightY + ringExpY);
      } else if (posType == 2) {
        positions[i] = LayoutPos(topRightX + ringExpX, topRightY - ringExpY);
      } else if (posType == 3) {
        positions[i] = LayoutPos(bottomLeftX - ringExpX, bottomLeftY + ringExpY);
      }
    }
    
    return positions;
  }
}
