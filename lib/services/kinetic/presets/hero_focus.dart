import '../../../models/editor_models.dart';
import 'kinetic_style_core.dart';

const heroFocus = KineticStyle(
    name: 'Hero Focus',
    icon: '⭐',
    colorPalette: [
      0xFFE63946,
      0xFFF1FAEE,
      0xFFA8DADC,
      0xFF457B9D,
      0xFF1D3557,
    ], // High contrast modern
    fontPool: ['Poppins', 'LuckiestGuy', 'Michroma', 'BhuTukaExpandedOne'],
    minFontSize: 30.0,
    maxFontSize: 60.0,
    minScale: 1.0,
    maxScale: 2.0, // Important for the "hero" effect
    maxRotation: 0.0,
    layoutPreset: LayoutPreset.hero,
    entrancePool: [
      AnimationType.zoomIn,
      AnimationType.bounceIn,
      AnimationType.scaleUp,
      AnimationType.elasticStretch,
    ],
    exitPool: [AnimationType.zoomOut, AnimationType.scaleDown],
    animationDurationMs: 400,
    textCase: TextCase.upper,
  );
