import '../../../models/editor_models.dart';
import 'kinetic_style_core.dart';

const targetRing = KineticStyle(
    name: 'Target Ring',
    icon: '🎯',
    colorPalette: [0xFFFF0000, 0xFFFFFFFF, 0xFF000000],
    fontPool: ['MajorMonoDisplay', 'Poppins'],
    minFontSize: 24.0,
    maxFontSize: 50.0,
    minScale: 0.8,
    maxScale: 1.2,
    maxRotation: 5.0,
    layoutPreset: LayoutPreset.target,
    entrancePool: [AnimationType.zoomIn, AnimationType.spin3D],
    exitPool: [AnimationType.zoomOut],
    animationDurationMs: 450,
    textCase: TextCase.title,
  );
