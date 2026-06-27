import '../../../models/editor_models.dart';
import 'kinetic_style_core.dart';

const perspectiveCrawl = KineticStyle(
    name: 'Perspective Crawl',
    icon: '🛣️',
    colorPalette: [0xFFFFD700, 0xFFFFFFFF], // Star wars yellow and white
    fontPool: ['Poppins', 'Michroma'],
    minFontSize: 24.0,
    maxFontSize: 80.0, // Large variance for perspective depth
    minScale: 0.5, // Will scale down at the top
    maxScale: 2.0, // Will scale up at the bottom
    maxRotation: 0.0,
    layoutPreset: LayoutPreset.perspective,
    entrancePool: [AnimationType.slideFromBottom, AnimationType.fadeIn],
    exitPool: [AnimationType.fadeOut],
    animationDurationMs: 600,
    textCase: TextCase.upper,
  );
