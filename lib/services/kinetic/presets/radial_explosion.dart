import '../../../models/editor_models.dart';
import 'kinetic_style_core.dart';

const radialExplosion = KineticStyle(
    name: 'Radial Explosion',
    icon: '💥',
    colorPalette: [0xFFFF5400, 0xFFFFBD00, 0xFFFE6D73, 0xFFFFFFFF],
    fontPool: ['BhuTukaExpandedOne', 'LuckiestGuy'],
    minFontSize: 40.0,
    maxFontSize: 90.0,
    minScale: 1.0,
    maxScale: 1.8,
    maxRotation: 15.0,
    layoutPreset: LayoutPreset.explosion,
    entrancePool: [
      AnimationType.bounceIn,
      AnimationType.elasticStretch,
      AnimationType.throwback,
    ],
    exitPool: [AnimationType.fadeOut],
    animationDurationMs: 350,
    textCase: TextCase.upper,
  );
