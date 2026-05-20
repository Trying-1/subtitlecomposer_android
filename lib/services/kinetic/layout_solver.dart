import 'dart:math';
import 'package:flutter/material.dart';
import '../../models/editor_models.dart';

/// Estimates text bounding boxes and solves collision-free positions
/// for co-visible subtitle clips in kinetic typography layouts.
class LayoutSolver {
  /// Safe margin from canvas edges (0.0 = left/top edge, 1.0 = right/bottom)
  static const double _margin = 0.08;
  static const double _safeMin = _margin;
  static const double _safeMax = 1.0 - _margin;

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
      final positioned = _applyLayout(group, preset, aspectRatio);

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
  List<SubtitleClip> _applyLayout(List<SubtitleClip> group, LayoutPreset preset, double aspectRatio) {
    final int count = group.length;
    final random = Random(group.first.id.hashCode);
    List<_Pos> positions;

    switch (preset) {
      case LayoutPreset.column:
        positions = _layoutColumn(count);
        break;
      case LayoutPreset.grid:
        positions = _layoutGrid(count);
        break;
      case LayoutPreset.staggered:
        positions = _layoutStaggered(count);
        break;
      case LayoutPreset.stairs:
        positions = _layoutStairs(count);
        break;
      case LayoutPreset.wave:
        positions = _layoutWave(count);
        break;
      case LayoutPreset.circle:
        positions = _layoutCircle(count);
        break;
      case LayoutPreset.spiral:
        positions = _layoutSpiral(count);
        break;
      case LayoutPreset.bento:
        positions = _layoutBento(count, group, aspectRatio);
        break;
      case LayoutPreset.random:
        positions = _layoutRandom(count, random);
        break;
      case LayoutPreset.masonry:
        positions = _layoutMasonry(count, group, aspectRatio);
        break;
      case LayoutPreset.collage:
        positions = _layoutCollage(count, random);
        break;
      case LayoutPreset.diagonal:
        positions = _layoutDiagonal(count);
        break;
      case LayoutPreset.target:
        positions = _layoutTarget(count);
        break;
      case LayoutPreset.explosion:
        positions = _layoutExplosion(count);
        break;
      case LayoutPreset.perspective:
        positions = _layoutPerspective(count);
        break;
      default:
        positions = _layoutColumn(count);
    }

    // Resolve collisions — nudge overlapping bounding boxes apart (skip for perfectly flush bento and masonry)
    if (preset != LayoutPreset.bento && preset != LayoutPreset.masonry) {
      positions = _resolveCollisions(group, positions, aspectRatio);
    }

    // Apply positions to clips
    return List.generate(count, (i) => group[i].copyWith(
      x: positions[i].x,
      y: positions[i].y,
    ));
  }

  // --- Layout algorithms ---

  List<_Pos> _layoutColumn(int count) {
    const gap = 0.12;
    final totalHeight = (count - 1) * gap;
    final startY = (1.0 - totalHeight) / 2;
    return List.generate(count, (i) => _Pos(0.5, startY + i * gap));
  }

  List<_Pos> _layoutGrid(int count) {
    final cols = count <= 4 ? 2 : (count <= 9 ? 3 : 4);
    final rows = (count / cols).ceil();
    final cellW = 0.7 / cols;
    final cellH = 0.6 / rows;
    return List.generate(count, (i) {
      final r = i ~/ cols;
      final c = i % cols;
      return _Pos(0.15 + (c + 0.5) * cellW, 0.2 + (r + 0.5) * cellH);
    });
  }

  List<_Pos> _layoutStaggered(int count) {
    return List.generate(count, (i) {
      final offset = (i % 2 == 0) ? -0.18 : 0.18;
      return _Pos(0.5 + offset, 0.15 + (i * (0.7 / count)));
    });
  }

  List<_Pos> _layoutStairs(int count) {
    return List.generate(count, (i) {
      final step = i / (count > 1 ? count - 1 : 1);
      return _Pos(0.2 + step * 0.6, 0.2 + step * 0.6);
    });
  }

  List<_Pos> _layoutWave(int count) {
    return List.generate(count, (i) {
      final t = i / (count > 1 ? count - 1 : 1);
      final px = 0.15 + t * 0.7;
      final py = 0.5 + sin(i * 0.8) * 0.2;
      return _Pos(px, py);
    });
  }

  List<_Pos> _layoutCircle(int count) {
    const radius = 0.25;
    return List.generate(count, (i) {
      final angle = (i / count) * 2.0 * pi;
      return _Pos(0.5 + cos(angle) * radius, 0.5 + sin(angle) * radius);
    });
  }

  List<_Pos> _layoutSpiral(int count) {
    return List.generate(count, (i) {
      final r = 0.05 + (i * 0.3 / count);
      final angle = i * 0.9;
      return _Pos(0.5 + cos(angle) * r, 0.5 + sin(angle) * r);
    });
  }

  /// High-end compact Bento Grid layout solver.
  /// Packs co-visible items with exact mathematical touch, sharing bounding box edges.
  List<_Pos> _layoutBento(int count, List<SubtitleClip> group, double aspectRatio) {
    if (count <= 1) return [const _Pos(0.5, 0.5)];

    // 1. Estimate sizes for each item using pixel-perfect _estimateBounds
    final List<double> ws = [];
    final List<double> hs = [];
    for (int i = 0; i < count; i++) {
      final bounds = _estimateBounds(group[i], const _Pos(0.5, 0.5), aspectRatio);
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

    return List.generate(count, (i) => _Pos(solvedX[i], solvedY[i]));
  }

  List<_Pos> _layoutRandom(int count, Random random) {
    return List.generate(count, (_) {
      final x = _safeMin + random.nextDouble() * (_safeMax - _safeMin);
      final y = _safeMin + random.nextDouble() * (_safeMax - _safeMin);
      return _Pos(x, y);
    });
  }

  // --- New Layout Algorithms ---

  /// Masonry Brick Wall layout solver.
  List<_Pos> _layoutMasonry(int count, List<SubtitleClip> group, double aspectRatio) {
    if (count <= 1) return [const _Pos(0.5, 0.5)];

    final List<double> ws = [];
    final List<double> hs = [];
    for (int i = 0; i < count; i++) {
      final bounds = _estimateBounds(group[i], const _Pos(0.5, 0.5), aspectRatio);
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

    return List.generate(count, (i) => _Pos(solvedX[i], solvedY[i]));
  }

  /// Punk Zine Collage
  List<_Pos> _layoutCollage(int count, Random random) {
    // Cluster in the center but very chaotic
    return List.generate(count, (i) {
      final r = random.nextDouble() * 0.25; // max radius from center
      final angle = random.nextDouble() * 2 * pi;
      return _Pos(0.5 + cos(angle) * r, 0.5 + sin(angle) * r);
    });
  }

  /// Dynamic Diagonal
  List<_Pos> _layoutDiagonal(int count) {
    return List.generate(count, (i) {
      // From top-left to bottom-right
      final step = count > 1 ? i / (count - 1) : 0.5;
      return _Pos(0.2 + step * 0.6, 0.2 + step * 0.6);
    });
  }

  /// Concentric Target
  List<_Pos> _layoutTarget(int count) {
    if (count <= 1) return [const _Pos(0.5, 0.5)];
    return List.generate(count, (i) {
      if (i == 0) return const _Pos(0.5, 0.5); // Center
      final ring = ((i - 1) ~/ 4) + 1; // 4 items per ring
      final itemsInRing = min(4, count - 1 - ((ring - 1) * 4));
      final idxInRing = (i - 1) % 4;
      final radius = 0.15 * ring;
      final angle = (idxInRing / itemsInRing) * 2 * pi + (ring * 0.5);
      return _Pos(0.5 + cos(angle) * radius, 0.5 + sin(angle) * radius);
    });
  }

  /// Radial Explosion
  List<_Pos> _layoutExplosion(int count) {
    if (count <= 1) return [const _Pos(0.5, 0.5)];
    return List.generate(count, (i) {
      if (i == 0) return const _Pos(0.5, 0.5); // Center origin
      final angle = (i / (count - 1)) * 2 * pi;
      final distance = 0.3; // exploded outward
      return _Pos(0.5 + cos(angle) * distance, 0.5 + sin(angle) * distance);
    });
  }

  /// Perspective Crawl (larger at bottom, smaller at top)
  List<_Pos> _layoutPerspective(int count) {
    return List.generate(count, (i) {
      final step = count > 1 ? i / (count - 1) : 0.5;
      // Start at bottom (y = 0.8), go up to top (y = 0.2)
      return _Pos(0.5, 0.8 - step * 0.6);
    });
  }

  // --- Collision resolution ---

  /// Estimates pixel-perfect bounding box dimensions for a text clip in normalized coords.
  /// Matches video_preview.dart calculation exactly using TextPainter.
  _Rect _estimateBounds(SubtitleClip clip, _Pos pos, double aspectRatio) {
    const double virtualHeight = 1080.0;
    final double virtualWidth = virtualHeight * aspectRatio;

    final textPainter = TextPainter(
      text: TextSpan(
        text: clip.text,
        style: TextStyle(
          fontSize: clip.fontSize,
          fontFamily: clip.fontFamily,
          letterSpacing: clip.letterSpacing,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    double extraPadding = 4.0;
    if (clip.isStrokeEnabled) extraPadding += clip.strokeWidth;
    if (clip.isShadowEnabled) {
      extraPadding += clip.shadowBlur + max(clip.shadowOffsetX.abs(), clip.shadowOffsetY.abs());
    } else if (clip.isGlowEnabled) {
      extraPadding += clip.glowSize;
    }

    final double rawW = (textPainter.width + extraPadding) * clip.scale;
    final double rawH = (textPainter.height + extraPadding) * clip.scale;

    final double rad = clip.rotation * pi / 180.0;
    final double absCos = cos(rad).abs();
    final double absSin = sin(rad).abs();

    final double rotW = rawW * absCos + rawH * absSin;
    final double rotH = rawW * absSin + rawH * absCos;

    final w = rotW / virtualWidth;
    final h = rotH / virtualHeight;

    return _Rect(
      pos.x - w / 2,
      pos.y - h / 2,
      w,
      h,
    );
  }

  List<_Pos> _resolveCollisions(List<SubtitleClip> clips, List<_Pos> positions, double aspectRatio) {
    final result = List<_Pos>.from(positions);
    const maxIterations = 30;
    const nudge = 0.04;

    for (int iter = 0; iter < maxIterations; iter++) {
      bool anyCollision = false;

      for (int i = 0; i < clips.length; i++) {
        for (int j = i + 1; j < clips.length; j++) {
          final rectA = _estimateBounds(clips[i], result[i], aspectRatio);
          final rectB = _estimateBounds(clips[j], result[j], aspectRatio);

          if (rectA.overlaps(rectB)) {
            anyCollision = true;
            // Push apart along Y axis primarily
            if (result[i].y <= result[j].y) {
              result[i] = _Pos(result[i].x, (result[i].y - nudge).clamp(_safeMin, _safeMax));
              result[j] = _Pos(result[j].x, (result[j].y + nudge).clamp(_safeMin, _safeMax));
            } else {
              result[i] = _Pos(result[i].x, (result[i].y + nudge).clamp(_safeMin, _safeMax));
              result[j] = _Pos(result[j].x, (result[j].y - nudge).clamp(_safeMin, _safeMax));
            }
          }
        }
      }

      if (!anyCollision) break;
    }

    return result;
  }
}

/// Simple 2D position helper
class _Pos {
  final double x;
  final double y;
  const _Pos(this.x, this.y);
}

/// Simple rectangle helper for collision detection
class _Rect {
  final double left;
  final double top;
  final double width;
  final double height;

  const _Rect(this.left, this.top, this.width, this.height);

  double get right => left + width;
  double get bottom => top + height;

  bool overlaps(_Rect other) {
    return left < other.right &&
        right > other.left &&
        top < other.bottom &&
        bottom > other.top;
  }
}
