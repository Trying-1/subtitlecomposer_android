import '../../../models/editor_models.dart';
import 'kinetic_style_core.dart';

const bentoBox = KineticStyle(
    name: 'Bento Box',
    icon: '🍱',
    colorPalette: [
      0xFFFF6B35,
      0xFFFFFFFF,
      0xFFF7C59F,
      0xFF00B4D8,
      0xFFABB2BF,
      0xFFEAEAEA,
    ],
    fontPool: ['Poppins', 'LuckiestGuy', 'Michroma'],
    minFontSize: 28.0,
    maxFontSize: 48.0,
    minScale: 0.95,
    maxScale: 1.15,
    maxRotation: 0.0,
    layoutPreset: LayoutPreset.bento,
    entrancePool: [
      AnimationType.scaleUp,
      AnimationType.fadeIn,
      AnimationType.bounceIn,
    ],
    exitPool: [AnimationType.scaleDown, AnimationType.fadeOut],
    animationDurationMs: 300,
    textCase: TextCase.upper,
  );
