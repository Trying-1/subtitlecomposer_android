import '../../../models/editor_models.dart';
import 'kinetic_style_core.dart';

const scatteredRandom = KineticStyle(
    name: 'Scattered Random',
    icon: '⚡',
    colorPalette: [
      0xFFF000FF,
      0xFF00FFFF,
      0xFF7000FF,
      0xFFFF2A6D,
      0xFFFFFFFF,
      0xFF05D9E8,
    ],
    fontPool: defaultFonts,
    minFontSize: 30.0,
    maxFontSize: 72.0,
    minScale: 0.8,
    maxScale: 1.6,
    maxRotation: 8.0,
    layoutPreset: LayoutPreset.random,
    entrancePool: [
      AnimationType.glitch,
      AnimationType.elasticDrop,
      AnimationType.zoomIn,
      AnimationType.elasticStretch,
      AnimationType.scaleUp,
    ],
    exitPool: [
      AnimationType.fadeOut,
      AnimationType.zoomOut,
      AnimationType.scaleDown,
    ],
    animationDurationMs: 350,
    textCase: TextCase.upper,
  );
