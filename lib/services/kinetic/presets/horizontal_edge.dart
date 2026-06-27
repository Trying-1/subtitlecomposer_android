import '../../../models/editor_models.dart';
import 'kinetic_style_core.dart';

const horizontalEdge = KineticStyle(
    name: 'Horizontal Edge',
    icon: '➡️',
    colorPalette: [0xFF000000, 0xFFFFFFFF],
    fontPool: ['Poppins'],
    minFontSize: 42.0,
    maxFontSize: 42.0,
    minScale: 1.0,
    maxScale: 1.0,
    maxRotation: 0.0,
    layoutPreset: LayoutPreset.row,
    entrancePool: [
      AnimationType.staggeredSlideFromRight,
    ],
    exitPool: [
      AnimationType.staggeredSlideFromLeft,
    ],
    animationDurationMs: 600,
    textCase: TextCase.upper,
  );
