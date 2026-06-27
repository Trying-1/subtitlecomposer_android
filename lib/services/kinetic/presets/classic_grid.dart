import '../../../models/editor_models.dart';
import 'kinetic_style_core.dart';

const classicGrid = KineticStyle(
    name: 'Classic Grid',
    icon: '🔲',
    colorPalette: [0xFF00FF41, 0xFF008F11, 0xFFFFFFFF], // Hacker green
    fontPool: ['MajorMonoDisplay', 'Michroma'],
    minFontSize: 28.0,
    maxFontSize: 42.0,
    minScale: 0.9,
    maxScale: 1.1,
    maxRotation: 0.0,
    layoutPreset: LayoutPreset.grid,
    entrancePool: [AnimationType.typewriter, AnimationType.fadeIn],
    exitPool: [AnimationType.fadeOut],
    animationDurationMs: 400,
    textCase: TextCase.upper,
  );
