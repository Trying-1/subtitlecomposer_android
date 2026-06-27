import '../../../models/editor_models.dart';
import 'kinetic_style_core.dart';

const wavyFlow = KineticStyle(
    name: 'Wavy Flow',
    icon: '🌿',
    colorPalette: [
      0xFF2D6A4F,
      0xFF40916C,
      0xFF52B788,
      0xFF74C69D,
      0xFF95D5B2,
      0xFFD8F3DC,
    ],
    fontPool: ['Poppins', 'Bellota', 'KleeOne', 'Caramel'],
    minFontSize: 30.0,
    maxFontSize: 56.0,
    minScale: 0.9,
    maxScale: 1.3,
    maxRotation: 5.0,
    layoutPreset: LayoutPreset.wave,
    entrancePool: [
      AnimationType.fadeIn,
      AnimationType.smoothSlideUp,
      AnimationType.wavyBend,
      AnimationType.slideFromBottom,
    ],
    exitPool: [AnimationType.fadeOut, AnimationType.slideDown],
    animationDurationMs: 600,
    textCase: TextCase.title,
  );
