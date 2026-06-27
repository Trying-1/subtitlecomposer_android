import '../../../models/editor_models.dart';
import 'kinetic_style_core.dart';

const masonryWall = KineticStyle(
    name: 'Masonry Wall',
    icon: '🧱',
    colorPalette: [0xFFE07A5F, 0xFF3D405B, 0xFF81B29A, 0xFFF2CC8F, 0xFFF4F1DE],
    fontPool: ['Poppins', 'Michroma', 'NewRocker'],
    minFontSize: 30.0,
    maxFontSize: 46.0,
    minScale: 0.9,
    maxScale: 1.1,
    maxRotation: 0.0,
    layoutPreset: LayoutPreset.masonry,
    entrancePool: [AnimationType.scaleUp, AnimationType.fadeIn],
    exitPool: [AnimationType.scaleDown, AnimationType.fadeOut],
    animationDurationMs: 400,
    textCase: TextCase.upper,
  );
