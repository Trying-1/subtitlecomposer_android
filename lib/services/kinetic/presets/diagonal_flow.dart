import '../../../models/editor_models.dart';
import 'kinetic_style_core.dart';

const diagonalFlow = KineticStyle(
    name: 'Diagonal Flow',
    icon: '📐',
    colorPalette: [0xFF00FFFF, 0xFFFF00FF, 0xFFFFFF00],
    fontPool: ['LuckiestGuy', 'Michroma'],
    minFontSize: 35.0,
    maxFontSize: 75.0,
    minScale: 0.9,
    maxScale: 1.4,
    maxRotation: -10.0, // Slight counter-tilt to the diagonal
    layoutPreset: LayoutPreset.diagonal,
    entrancePool: [AnimationType.slideUp, AnimationType.wavyBend],
    exitPool: [AnimationType.slideDown],
    animationDurationMs: 400,
    textCase: TextCase.upper,
  );
