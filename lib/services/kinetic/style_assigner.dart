import 'dart:math';
import '../../models/editor_models.dart';
import 'kinetic_style.dart';

/// Assigns visual style properties (font, color, size, scale, rotation, effects)
/// to a list of SubtitleClips based on a KineticStyle configuration.
class StyleAssigner {
  final Random _random;

  StyleAssigner({int? seed}) : _random = Random(seed ?? DateTime.now().millisecondsSinceEpoch);

  /// Applies style properties to each clip and returns the updated clips.
  /// Ensures no two adjacent segments share the same color or font.
  List<SubtitleClip> assign(List<SubtitleClip> clips, KineticStyle style) {
    if (clips.isEmpty) return clips;

    final List<SubtitleClip> result = [];
    int lastColorIndex = -1;
    int lastFontIndex = -1;

    for (int i = 0; i < clips.length; i++) {
      final clip = clips[i];

      // --- Color: cycle through palette, avoid adjacent repeats ---
      int colorIndex = _random.nextInt(style.colorPalette.length);
      if (style.colorPalette.length > 1) {
        while (colorIndex == lastColorIndex) {
          colorIndex = _random.nextInt(style.colorPalette.length);
        }
      }
      lastColorIndex = colorIndex;
      final color = style.colorPalette[colorIndex];

      // --- Font: random from pool, avoid adjacent repeats ---
      int fontIndex = _random.nextInt(style.fontPool.length);
      if (style.fontPool.length > 1) {
        while (fontIndex == lastFontIndex) {
          fontIndex = _random.nextInt(style.fontPool.length);
        }
      }
      lastFontIndex = fontIndex;
      final fontFamily = style.fontPool[fontIndex];

      // --- Font size: random within range ---
      final fontSize = style.minFontSize +
          _random.nextDouble() * (style.maxFontSize - style.minFontSize);

      // --- Scale: random within range ---
      final scale = style.minScale +
          _random.nextDouble() * (style.maxScale - style.minScale);

      // --- Rotation ---
      double rotation = 0.0;
      switch (style.rotationMode) {
        case RotationMode.none:
          rotation = 0.0;
          break;
        case RotationMode.random:
          rotation = style.maxRotation > 0
              ? (_random.nextDouble() * 2 - 1) * style.maxRotation
              : 0.0;
          break;
        case RotationMode.orthogonal:
          final angles = [0.0, 90.0, 270.0];
          rotation = angles[_random.nextInt(angles.length)];
          break;
      }

      // --- Text casing ---
      String text = clip.text;
      switch (style.textCase) {
        case TextCase.upper:
          text = clip.text.toUpperCase();
          break;
        case TextCase.lower:
          text = clip.text.toLowerCase();
          break;
        case TextCase.title:
          text = clip.text.split(' ').map((w) {
            if (w.isEmpty) return w;
            return w[0].toUpperCase() + w.substring(1).toLowerCase();
          }).join(' ');
          break;
        case TextCase.none:
          break;
      }

      result.add(clip.copyWith(
        text: text,
        color: color,
        fontFamily: fontFamily,
        fontSize: fontSize,
        scale: scale,
        rotation: rotation,
        isStrokeEnabled: style.enableStroke,
        strokeColor: style.enableStroke ? style.strokeColor : null,
        strokeWidth: style.enableStroke ? style.strokeWidth : null,
        isShadowEnabled: style.enableShadow,
        shadowColor: style.enableShadow ? 0x88000000 : null,
        shadowBlur: style.enableShadow ? 8.0 : null,
        shadowOffsetX: style.enableShadow ? 4.0 : null,
        shadowOffsetY: style.enableShadow ? 4.0 : null,
        isGlowEnabled: style.enableGlow,
        glowColor: style.enableGlow ? color : null,
        glowSize: style.enableGlow ? 6.0 : null,
        opacity: 1.0,
        textOpacity: 1.0,
      ));
    }

    return result;
  }
}
