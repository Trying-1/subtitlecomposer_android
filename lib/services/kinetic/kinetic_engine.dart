import '../../models/editor_models.dart';
import 'kinetic_style.dart';
import 'style_assigner.dart';
import 'layout_solver.dart';
import 'animation_assigner.dart';

/// Main orchestrator for one-click kinetic typography automation.
///
/// Pipeline:
/// 1. StyleAssigner  → fonts, colors, sizes, scale, rotation, effects
/// 2. LayoutSolver   → collision-free (x, y) positions
/// 3. AnimationAssigner → entrance/exit animations
///
/// Note: Burst (word splitting) and Stack (time alignment) are handled
/// by the caller (EditorProvider) using existing methods before calling this engine.
class KineticEngine {
  /// Applies full kinetic typography styling to the given clips.
  ///
  /// [clips] — SubtitleClips that have already been burst/stacked if desired
  /// [style] — The KineticStyle configuration to apply
  /// [aspectRatio] — Canvas aspect ratio for layout calculations
  ///
  /// Returns the fully styled, positioned, and animated clips.
  static List<SubtitleClip> apply({
    required List<SubtitleClip> clips,
    required KineticStyle style,
    required double aspectRatio,
  }) {
    if (clips.isEmpty) return clips;

    // Sort by start time for consistent processing
    final sorted = List<SubtitleClip>.from(clips)
      ..sort((a, b) => a.startTime.compareTo(b.startTime));

    // Pipeline step 1: Assign visual styles
    final styleAssigner = StyleAssigner();
    var result = styleAssigner.assign(sorted, style);

    // Pipeline step 2: Solve collision-free positions
    final layoutSolver = LayoutSolver();
    result = layoutSolver.solve(result, style.layoutPreset, aspectRatio);

    // Pipeline step 3: Assign animations
    final animationAssigner = AnimationAssigner();
    result = animationAssigner.assign(result, style);

    return result;
  }
}
