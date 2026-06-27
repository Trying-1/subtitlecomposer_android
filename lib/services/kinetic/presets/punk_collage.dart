import '../../../models/editor_models.dart';
import 'kinetic_style_core.dart';

const punkCollage = KineticStyle(
    name: 'Punk Collage',
    icon: '🗞️',
    colorPalette: [0xFF000000, 0xFFFFFFFF, 0xFFFF0000, 0xFFFFF000],
    fontPool: ['Lacquer', 'NewRocker', 'Bokor'],
    minFontSize: 40.0,
    maxFontSize: 80.0,
    minScale: 0.8,
    maxScale: 1.6,
    maxRotation: 25.0,
    layoutPreset: LayoutPreset.collage,
    entrancePool: [
      AnimationType.glitch,
      AnimationType.elasticDrop,
      AnimationType.bounceIn,
    ],
    exitPool: [AnimationType.fadeOut],
    animationDurationMs: 300,
    textCase: TextCase.upper,
  );
