import '../../../models/editor_models.dart';
import 'kinetic_style_core.dart';

const hypnoticSpiral = KineticStyle(
    name: 'Hypnotic Spiral',
    icon: '🌀',
    colorPalette: [0xFF9D4EDD, 0xFFC77DFF, 0xFFE0AAFF, 0xFFFFFFFF],
    fontPool: ['Caramel', 'Bellota', 'Lacquer'],
    minFontSize: 24.0,
    maxFontSize: 64.0,
    minScale: 0.7,
    maxScale: 1.5,
    maxRotation: 45.0,
    layoutPreset: LayoutPreset.spiral,
    entrancePool: [
      AnimationType.spiralDrop,
      AnimationType.spin3D,
      AnimationType.wobble,
    ],
    exitPool: [AnimationType.zoomOut],
    animationDurationMs: 600,
    textCase: TextCase.title,
  );
