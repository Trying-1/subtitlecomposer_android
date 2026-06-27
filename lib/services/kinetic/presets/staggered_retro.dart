import '../../../models/editor_models.dart';
import 'kinetic_style_core.dart';

const staggeredRetro = KineticStyle(
    name: 'Staggered Retro',
    icon: '🕹️',
    colorPalette: [
      0xFFFF0054,
      0xFFFF5400,
      0xFFFFBD00,
      0xFFE9FF70,
      0xFF00B4D8,
      0xFFFE6D73,
    ],
    fontPool: defaultFonts,
    minFontSize: 34.0,
    maxFontSize: 68.0,
    minScale: 0.85,
    maxScale: 1.5,
    maxRotation: 12.0,
    layoutPreset: LayoutPreset.staggered,
    entrancePool: [
      AnimationType.bounceIn,
      AnimationType.flipX,
      AnimationType.flipY,
      AnimationType.flip3D_X,
      AnimationType.scaleUp,
      AnimationType.throwback,
    ],
    exitPool: [
      AnimationType.scaleDown,
      AnimationType.fadeOut,
      AnimationType.zoomOut,
    ],
    animationDurationMs: 400,
    textCase: TextCase.upper,
  );
