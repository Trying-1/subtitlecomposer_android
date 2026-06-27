import 'dart:math';
import 'package:flutter/material.dart';
import '../../../models/editor_models.dart';

/// Simple 2D position helper
class LayoutPos {
  final double x;
  final double y;
  const LayoutPos(this.x, this.y);
}

/// Simple rectangle helper for collision detection
class LayoutRect {
  final double left;
  final double top;
  final double width;
  final double height;

  const LayoutRect(this.left, this.top, this.width, this.height);

  double get right => left + width;
  double get bottom => top + height;

  bool overlaps(LayoutRect other) {
    return left < other.right &&
        right > other.left &&
        top < other.bottom &&
        bottom > other.top;
  }
}

/// Base interface for all kinetic layouts
abstract class KineticLayout {
  List<LayoutPos> calculate(int count, List<SubtitleClip> group, double aspectRatio, Random random);
}

/// Estimates pixel-perfect bounding box dimensions for a text clip in normalized coords.
LayoutRect estimateBounds(SubtitleClip clip, LayoutPos pos, double aspectRatio) {
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

  final lineMetrics = textPainter.computeLineMetrics();
  double tightTextHeight;
  if (lineMetrics.isNotEmpty) {
    final lm = lineMetrics.first;
    tightTextHeight = (lm.ascent + lm.descent) * 0.75;
  } else {
    tightTextHeight = textPainter.height * 0.75;
  }

  double extraPadding = 0.0;
  if (clip.isStrokeEnabled) extraPadding += clip.strokeWidth;
  if (clip.isShadowEnabled) {
    extraPadding += clip.shadowBlur + max(clip.shadowOffsetX.abs(), clip.shadowOffsetY.abs());
  } else if (clip.isGlowEnabled) {
    extraPadding += clip.glowSize;
  }

  final double rawW = (textPainter.width + extraPadding) * clip.scale;
  final double rawH = (tightTextHeight + extraPadding) * clip.scale;

  final double rad = clip.rotation * pi / 180.0;
  final double absCos = cos(rad).abs();
  final double absSin = sin(rad).abs();

  final double rotW = rawW * absCos + rawH * absSin;
  final double rotH = rawW * absSin + rawH * absCos;

  final w = rotW / virtualWidth;
  final h = rotH / virtualHeight;

  return LayoutRect(
    pos.x - w / 2,
    pos.y - h / 2,
    w,
    h,
  );
}
