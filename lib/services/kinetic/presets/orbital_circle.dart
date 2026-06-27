import '../../../models/editor_models.dart';
import 'kinetic_style_core.dart';

const orbitalCircle = KineticStyle(
    name: 'Orbital Circle',
    icon: '🪐',
    colorPalette: [0xFFFF9F1C, 0xFFFFBF69, 0xFFFFFFFF, 0xFFCBF3F0],
    fontPool: ['Poppins', 'LuckiestGuy'],
    minFontSize: 26.0,
    maxFontSize: 56.0,
    minScale: 0.8,
    maxScale: 1.3,
    maxRotation: 15.0,
    layoutPreset: LayoutPreset.circle,
    entrancePool: [AnimationType.spin, AnimationType.zoomIn],
    exitPool: [AnimationType.zoomOut, AnimationType.spin],
    animationDurationMs: 500,
    textCase: TextCase.upper,
  );
