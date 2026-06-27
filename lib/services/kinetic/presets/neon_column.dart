import '../../../models/editor_models.dart';
import 'kinetic_style_core.dart';

const neonColumn = KineticStyle(
    name: 'Neon Column',
    icon: '🔮',
    colorPalette: [0xFFFF00F0, 0xFF00FFCC, 0xFF3300FF, 0xFFFFFF00, 0xFFFFFFFF],
    fontPool: defaultFonts,
    minFontSize: 32.0,
    maxFontSize: 60.0,
    minScale: 0.9,
    maxScale: 1.3,
    maxRotation: 0.0,
    layoutPreset: LayoutPreset.column,
    entrancePool: [
      AnimationType.zoomIn,
      AnimationType.fadeIn,
      AnimationType.smoothSlideUp,
    ],
    exitPool: [AnimationType.zoomOut, AnimationType.fadeOut],
    animationDurationMs: 400,
    textCase: TextCase.upper,
  );
