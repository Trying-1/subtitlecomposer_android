import 'dart:math';
import 'package:flutter/material.dart';
import '../../models/editor_models.dart';
import 'layouts/layout_core.dart';
import 'layouts/column_layout.dart';
import 'layouts/row_layout.dart';
import 'layouts/grid_layout.dart';
import 'layouts/staggered_layout.dart';
import 'layouts/stairs_layout.dart';
import 'layouts/wave_layout.dart';
import 'layouts/circle_layout.dart';
import 'layouts/spiral_layout.dart';
import 'layouts/bento_layout.dart';
import 'layouts/random_layout.dart';
import 'layouts/masonry_layout.dart';
import 'layouts/collage_layout.dart';
import 'layouts/diagonal_layout.dart';
import 'layouts/target_layout.dart';
import 'layouts/explosion_layout.dart';
import 'layouts/perspective_layout.dart';
import 'layouts/hero_layout.dart';

/// Estimates text bounding boxes and solves collision-free positions
/// for co-visible subtitle clips in kinetic typography layouts.
class LayoutSolver {
  /// Safe margin from canvas edges (0.0 = left/top edge, 1.0 = right/bottom)
  static const double _margin = 0.08;
  static const double _safeMin = _margin;
  static const double _safeMax = 1.0 - _margin;

  late final Map<LayoutPreset, KineticLayout> _registry;

  LayoutSolver() {
    _registry = {
      LayoutPreset.column: ColumnLayout(),
      LayoutPreset.row: RowLayout(),
      LayoutPreset.grid: GridLayout(),
      LayoutPreset.staggered: StaggeredLayout(),
      LayoutPreset.stairs: StairsLayout(),
      LayoutPreset.wave: WaveLayout(),
      LayoutPreset.circle: CircleLayout(),
      LayoutPreset.spiral: SpiralLayout(),
      LayoutPreset.bento: BentoLayout(),
      LayoutPreset.random: RandomLayout(_safeMin, _safeMax),
      LayoutPreset.masonry: MasonryLayout(),
      LayoutPreset.collage: CollageLayout(),
      LayoutPreset.diagonal: DiagonalLayout(),
      LayoutPreset.target: TargetLayout(),
      LayoutPreset.explosion: ExplosionLayout(),
      LayoutPreset.perspective: PerspectiveLayout(),
      LayoutPreset.hero: HeroLayout(),
    };
  }

  /// Applies collision-free positioning to clips based on the layout preset.
  /// Groups clips by time overlap and resolves spatial collisions within each group.
  List<SubtitleClip> solve(List<SubtitleClip> clips, LayoutPreset preset, double aspectRatio) {
    if (clips.isEmpty) return clips;

    // 1. Group clips by time overlap
    final groups = _groupByTimeOverlap(clips);

    // 2. For each group, apply layout and resolve collisions
    final List<SubtitleClip> result = List.from(clips);

    for (final group in groups) {
      if (group.length <= 1) continue; // Single clips don't need layout

      final groupIndices = group.map((c) => clips.indexOf(c)).toList();
      final positioned = applyLayoutGroup(group, preset, aspectRatio);

      for (int i = 0; i < positioned.length; i++) {
        result[groupIndices[i]] = positioned[i];
      }
    }

    // 3. Clamp all positions to safe margins
    return result.map((c) => c.copyWith(
      x: c.x.clamp(_safeMin, _safeMax),
      y: c.y.clamp(_safeMin, _safeMax),
    )).toList();
  }

  /// Groups clips that overlap in time (co-visible clips)
  List<List<SubtitleClip>> _groupByTimeOverlap(List<SubtitleClip> clips) {
    final sorted = List<SubtitleClip>.from(clips)
      ..sort((a, b) => a.startTime.compareTo(b.startTime));

    final List<List<SubtitleClip>> groups = [];
    final Set<String> assigned = {};

    for (int i = 0; i < sorted.length; i++) {
      if (assigned.contains(sorted[i].id)) continue;

      final group = <SubtitleClip>[sorted[i]];
      assigned.add(sorted[i].id);

      for (int j = i + 1; j < sorted.length; j++) {
        if (assigned.contains(sorted[j].id)) continue;

        // Check if sorted[j] overlaps with ANY clip in the current group
        bool overlapsGroup = group.any((g) =>
            sorted[j].startTime < g.endTime && g.startTime < sorted[j].endTime);

        if (overlapsGroup) {
          group.add(sorted[j]);
          assigned.add(sorted[j].id);
        }
      }

      groups.add(group);
    }

    return groups;
  }

  /// Applies the layout preset to a group of co-visible clips
  List<SubtitleClip> applyLayoutGroup(List<SubtitleClip> group, LayoutPreset preset, double aspectRatio) {
    final int count = group.length;
    final random = Random(group.first.id.hashCode);

    // Special pre-processing for Hero Layout
    if (preset == LayoutPreset.hero) {
      for (int i = 0; i < count; i++) {
        if (i == 0) {
          group[i] = group[i].copyWith(scale: group[i].scale * 2.0);
        } else {
          group[i] = group[i].copyWith(scale: group[i].scale * 0.8);
        }
      }
    }

    // Get the strategy
    final layoutStrategy = _registry[preset] ?? ColumnLayout();
    
    // Calculate initial positions
    List<LayoutPos> positions = layoutStrategy.calculate(count, group, aspectRatio, random);

    // Resolve collisions — nudge overlapping bounding boxes apart (skip for dense layouts)
    if (preset != LayoutPreset.bento && preset != LayoutPreset.masonry && preset != LayoutPreset.row) {
      positions = _resolveCollisions(group, positions, aspectRatio);
    }

    // Apply positions to clips and constrain full bounding boxes inside screen
    var solvedGroup = List.generate(count, (i) {
      final bounds = estimateBounds(group[i], positions[i], aspectRatio);
      double cx = positions[i].x;
      double cy = positions[i].y;
      
      // Shift center if bounds leak off-screen
      if (bounds.left < _safeMin) cx += (_safeMin - bounds.left);
      if (bounds.right > _safeMax) cx -= (bounds.right - _safeMax);
      if (bounds.top < _safeMin) cy += (_safeMin - bounds.top);
      if (bounds.bottom > _safeMax) cy -= (bounds.bottom - _safeMax);
      
      return group[i].copyWith(
        x: cx.clamp(_safeMin, _safeMax),
        y: cy.clamp(_safeMin, _safeMax),
      );
    });

    // Final safety fallback: If there is literally not enough physical space on the screen,
    // they will still overlap. We must dynamically scale them down to guarantee 0% overlap.
    if (preset != LayoutPreset.bento && preset != LayoutPreset.masonry && preset != LayoutPreset.row) {
      bool overlapping = true;
      int shrinkIterations = 0;
      while (overlapping && shrinkIterations < 10) {
        overlapping = false;
        for (int i = 0; i < count; i++) {
          for (int j = i + 1; j < count; j++) {
            final rectA = estimateBounds(solvedGroup[i], LayoutPos(solvedGroup[i].x, solvedGroup[i].y), aspectRatio);
            final rectB = estimateBounds(solvedGroup[j], LayoutPos(solvedGroup[j].x, solvedGroup[j].y), aspectRatio);
            
            if (rectA.overlaps(rectB)) {
              overlapping = true;
              // Shrink both slightly
              solvedGroup[i] = solvedGroup[i].copyWith(scale: solvedGroup[i].scale * 0.9);
              solvedGroup[j] = solvedGroup[j].copyWith(scale: solvedGroup[j].scale * 0.9);
            }
          }
        }
        shrinkIterations++;
      }
    }

    return solvedGroup;
  }

  // --- Collision resolution ---

  List<LayoutPos> _resolveCollisions(List<SubtitleClip> clips, List<LayoutPos> positions, double aspectRatio) {
    final result = List<LayoutPos>.from(positions);
    const maxIterations = 30;

    for (int iter = 0; iter < maxIterations; iter++) {
      bool anyCollision = false;

      for (int i = 0; i < clips.length; i++) {
        for (int j = i + 1; j < clips.length; j++) {
          final rectA = estimateBounds(clips[i], result[i], aspectRatio);
          final rectB = estimateBounds(clips[j], result[j], aspectRatio);

          if (rectA.overlaps(rectB)) {
            anyCollision = true;
            
            final overlapX = (min(rectA.right, rectB.right) - max(rectA.left, rectB.left));
            final overlapY = (min(rectA.bottom, rectB.bottom) - max(rectA.top, rectB.top));

            const pad = 0.02; // Small padding to clear edges

            if (overlapX < overlapY) {
              // Push apart along X axis
              final shift = (overlapX / 2) + pad;
              if (result[i].x < result[j].x) {
                result[i] = LayoutPos((result[i].x - shift).clamp(_safeMin, _safeMax), result[i].y);
                result[j] = LayoutPos((result[j].x + shift).clamp(_safeMin, _safeMax), result[j].y);
              } else {
                result[i] = LayoutPos((result[i].x + shift).clamp(_safeMin, _safeMax), result[i].y);
                result[j] = LayoutPos((result[j].x - shift).clamp(_safeMin, _safeMax), result[j].y);
              }
            } else {
              // Push apart along Y axis
              final shift = (overlapY / 2) + pad;
              if (result[i].y < result[j].y) {
                result[i] = LayoutPos(result[i].x, (result[i].y - shift).clamp(_safeMin, _safeMax));
                result[j] = LayoutPos(result[j].x, (result[j].y + shift).clamp(_safeMin, _safeMax));
              } else {
                result[i] = LayoutPos(result[i].x, (result[i].y + shift).clamp(_safeMin, _safeMax));
                result[j] = LayoutPos(result[j].x, (result[j].y - shift).clamp(_safeMin, _safeMax));
              }
            }
          }
        }
      }

      if (!anyCollision) break;
    }

    return result;
  }
}
