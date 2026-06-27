import '../../../models/editor_models.dart';
import 'kinetic_style_core.dart';

const stairStep = KineticStyle(
    name: 'Stair Step',
    icon: '📶',
    colorPalette: [0xFF4361EE, 0xFF3A0CA3, 0xFF7209B7, 0xFFF72585],
    fontPool: ['Poppins', 'BhuTukaExpandedOne'],
    minFontSize: 30.0,
    maxFontSize: 50.0,
    minScale: 0.9,
    maxScale: 1.2,
    maxRotation: 0.0,
    layoutPreset: LayoutPreset.stairs,
    entrancePool: [AnimationType.slideFromBottom, AnimationType.slideFromTop],
    exitPool: [AnimationType.slideDown],
    animationDurationMs: 350,
    textCase: TextCase.title,
  );
