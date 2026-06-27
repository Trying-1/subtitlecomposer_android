import '../../../models/editor_models.dart';
import 'kinetic_style_core.dart';

const minimalColumn = KineticStyle(
    name: 'Minimal Column',
    icon: '◻️',
    colorPalette: [0xFFFFFFFF, 0xFFE5E9F0, 0xFFD8DEE9, 0xFF8FBCBB, 0xFFABB2BF],
    fontPool: ['Poppins', 'Metrophobic', 'Michroma'],
    minFontSize: 28.0,
    maxFontSize: 52.0,
    minScale: 0.9,
    maxScale: 1.2,
    maxRotation: 0.0,
    layoutPreset: LayoutPreset.column,
    entrancePool: [
      AnimationType.smoothSlideUp,
      AnimationType.fadeIn,
      AnimationType.slideUp,
    ],
    exitPool: [AnimationType.fadeOut, AnimationType.slideDown],
    animationDurationMs: 500,
    textCase: TextCase.upper,
  );
