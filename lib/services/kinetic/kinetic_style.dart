import '../../models/editor_models.dart';

enum RotationMode {
  none,
  random,
  orthogonal,
}

/// Configuration model for a kinetic typography style/theme.
/// Controls how text segments are styled, positioned, and animated.
class KineticStyle {
  final String name;
  final String icon; // emoji for UI display
  final List<int> colorPalette;
  final List<String> fontPool;
  final double minFontSize;
  final double maxFontSize;
  final double minScale;
  final double maxScale;
  final double maxRotation; // degrees, applied as ± random
  final RotationMode rotationMode;
  final LayoutPreset layoutPreset;
  final List<AnimationType> entrancePool;
  final List<AnimationType> exitPool;
  final int animationDurationMs;
  final bool enableStroke;
  final int strokeColor;
  final double strokeWidth;
  final bool enableShadow;
  final bool enableGlow;
  final TextCase textCase;
  final bool enableEntranceAnimation;
  final bool enableExitAnimation;

  const KineticStyle({
    required this.name,
    this.icon = '✨',
    required this.colorPalette,
    required this.fontPool,
    this.minFontSize = 32.0,
    this.maxFontSize = 64.0,
    this.minScale = 0.85,
    this.maxScale = 1.4,
    this.maxRotation = 0.0,
    this.rotationMode = RotationMode.none,
    this.layoutPreset = LayoutPreset.column,
    this.entrancePool = const [AnimationType.fadeIn],
    this.exitPool = const [AnimationType.fadeOut],
    this.animationDurationMs = 400,
    this.enableStroke = false,
    this.strokeColor = 0xFF000000,
    this.strokeWidth = 2.0,
    this.enableShadow = false,
    this.enableGlow = false,
    this.textCase = TextCase.upper,
    this.enableEntranceAnimation = true,
    this.enableExitAnimation = false,
  });

  KineticStyle copyWith({
    String? name,
    String? icon,
    List<int>? colorPalette,
    List<String>? fontPool,
    double? minFontSize,
    double? maxFontSize,
    double? minScale,
    double? maxScale,
    double? maxRotation,
    RotationMode? rotationMode,
    LayoutPreset? layoutPreset,
    List<AnimationType>? entrancePool,
    List<AnimationType>? exitPool,
    int? animationDurationMs,
    bool? enableStroke,
    int? strokeColor,
    double? strokeWidth,
    bool? enableShadow,
    bool? enableGlow,
    TextCase? textCase,
    bool? enableEntranceAnimation,
    bool? enableExitAnimation,
  }) => KineticStyle(
    name: name ?? this.name,
    icon: icon ?? this.icon,
    colorPalette: colorPalette ?? this.colorPalette,
    fontPool: fontPool ?? this.fontPool,
    minFontSize: minFontSize ?? this.minFontSize,
    maxFontSize: maxFontSize ?? this.maxFontSize,
    minScale: minScale ?? this.minScale,
    maxScale: maxScale ?? this.maxScale,
    maxRotation: maxRotation ?? this.maxRotation,
    rotationMode: rotationMode ?? this.rotationMode,
    layoutPreset: layoutPreset ?? this.layoutPreset,
    entrancePool: entrancePool ?? this.entrancePool,
    exitPool: exitPool ?? this.exitPool,
    animationDurationMs: animationDurationMs ?? this.animationDurationMs,
    enableStroke: enableStroke ?? this.enableStroke,
    strokeColor: strokeColor ?? this.strokeColor,
    strokeWidth: strokeWidth ?? this.strokeWidth,
    enableShadow: enableShadow ?? this.enableShadow,
    enableGlow: enableGlow ?? this.enableGlow,
    textCase: textCase ?? this.textCase,
    enableEntranceAnimation: enableEntranceAnimation ?? this.enableEntranceAnimation,
    enableExitAnimation: enableExitAnimation ?? this.enableExitAnimation,
  );
}

/// Built-in kinetic typography presets.
class KineticPresets {
  static const _defaultFonts = [
    'Poppins', 'LuckiestGuy', 'Michroma', 'NewRocker',
    'BhuTukaExpandedOne', 'Bokor', 'Lacquer', 'MajorMonoDisplay',
  ];

  static final List<KineticStyle> all = [
    cyberpunkBurst,
    minimalStack,
    retroPop,
    natureFlow,
    bentoBlocky,
    masonryWall,
    punkZine,
    diagonalForce,
    concentricTarget,
    radialExplosion,
    perspectiveCrawl,
    gridMatrix,
    stairStep,
    orbitalCircle,
    hypnoticSpiral,
    fullRandom,
  ];

  static const cyberpunkBurst = KineticStyle(
    name: 'Cyberpunk Burst',
    icon: '⚡',
    colorPalette: [0xFFF000FF, 0xFF00FFFF, 0xFF7000FF, 0xFFFF2A6D, 0xFFFFFFFF, 0xFF05D9E8],
    fontPool: _defaultFonts,
    minFontSize: 30.0,
    maxFontSize: 72.0,
    minScale: 0.8,
    maxScale: 1.6,
    maxRotation: 8.0,
    layoutPreset: LayoutPreset.random,
    entrancePool: [
      AnimationType.glitch,
      AnimationType.elasticDrop,
      AnimationType.zoomIn,
      AnimationType.elasticStretch,
      AnimationType.scaleUp,
    ],
    exitPool: [
      AnimationType.fadeOut,
      AnimationType.zoomOut,
      AnimationType.scaleDown,
    ],
    animationDurationMs: 350,
    enableStroke: false,
    strokeColor: 0xFF000000,
    strokeWidth: 3.0,
    enableShadow: false,
    enableGlow: false,
    textCase: TextCase.upper,
  );

  static const minimalStack = KineticStyle(
    name: 'Minimal Stack',
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
    exitPool: [
      AnimationType.fadeOut,
      AnimationType.slideDown,
    ],
    animationDurationMs: 500,
    enableStroke: false,
    enableShadow: false,
    enableGlow: false,
    textCase: TextCase.upper,
  );

  static const retroPop = KineticStyle(
    name: 'Retro Pop',
    icon: '🕹️',
    colorPalette: [0xFFFF0054, 0xFFFF5400, 0xFFFFBD00, 0xFFE9FF70, 0xFF00B4D8, 0xFFFE6D73],
    fontPool: _defaultFonts,
    minFontSize: 34.0,
    maxFontSize: 68.0,
    minScale: 0.85,
    maxScale: 1.5,
    maxRotation: 12.0,
    layoutPreset: LayoutPreset.staggered,
    entrancePool: [
      AnimationType.bounceIn,
      AnimationType.flipX,
      AnimationType.flipY,
      AnimationType.flip3D_X,
      AnimationType.scaleUp,
      AnimationType.throwback,
    ],
    exitPool: [
      AnimationType.scaleDown,
      AnimationType.fadeOut,
      AnimationType.zoomOut,
    ],
    animationDurationMs: 400,
    enableStroke: false,
    strokeColor: 0xFF000000,
    strokeWidth: 4.0,
    enableShadow: false,
    enableGlow: false,
    textCase: TextCase.upper,
  );

  static const natureFlow = KineticStyle(
    name: 'Nature Flow',
    icon: '🌿',
    colorPalette: [0xFF2D6A4F, 0xFF40916C, 0xFF52B788, 0xFF74C69D, 0xFF95D5B2, 0xFFD8F3DC],
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
    exitPool: [
      AnimationType.fadeOut,
      AnimationType.slideDown,
    ],
    animationDurationMs: 600,
    enableStroke: false,
    enableShadow: false,
    enableGlow: false,
    textCase: TextCase.title,
  );

  static const masonryWall = KineticStyle(
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
    entrancePool: [
      AnimationType.scaleUp,
      AnimationType.fadeIn,
    ],
    exitPool: [
      AnimationType.scaleDown,
      AnimationType.fadeOut,
    ],
    animationDurationMs: 400,
    enableStroke: false,
    enableShadow: false,
    enableGlow: false,
    textCase: TextCase.upper,
  );

  static const punkZine = KineticStyle(
    name: 'Punk Zine',
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
    exitPool: [
      AnimationType.fadeOut,
    ],
    animationDurationMs: 300,
    enableStroke: false,
    strokeColor: 0xFF000000,
    strokeWidth: 4.0,
    enableShadow: false,
    enableGlow: false,
    textCase: TextCase.upper,
  );

  static const diagonalForce = KineticStyle(
    name: 'Diagonal Force',
    icon: '📐',
    colorPalette: [0xFF00FFFF, 0xFFFF00FF, 0xFFFFFF00],
    fontPool: ['LuckiestGuy', 'Michroma'],
    minFontSize: 35.0,
    maxFontSize: 75.0,
    minScale: 0.9,
    maxScale: 1.4,
    maxRotation: -10.0, // Slight counter-tilt to the diagonal
    layoutPreset: LayoutPreset.diagonal,
    entrancePool: [
      AnimationType.slideUp,
      AnimationType.wavyBend,
    ],
    exitPool: [
      AnimationType.slideDown,
    ],
    animationDurationMs: 400,
    enableStroke: false,
    strokeColor: 0xFF000000,
    strokeWidth: 3.0,
    enableShadow: false,
    enableGlow: false,
    textCase: TextCase.upper,
  );

  static const concentricTarget = KineticStyle(
    name: 'Target Ring',
    icon: '🎯',
    colorPalette: [0xFFFF0000, 0xFFFFFFFF, 0xFF000000],
    fontPool: ['MajorMonoDisplay', 'Poppins'],
    minFontSize: 24.0,
    maxFontSize: 50.0,
    minScale: 0.8,
    maxScale: 1.2,
    maxRotation: 5.0,
    layoutPreset: LayoutPreset.target,
    entrancePool: [
      AnimationType.zoomIn,
      AnimationType.spin3D,
    ],
    exitPool: [
      AnimationType.zoomOut,
    ],
    animationDurationMs: 450,
    enableStroke: false,
    enableShadow: false,
    enableGlow: false,
    textCase: TextCase.title,
  );

  static const radialExplosion = KineticStyle(
    name: 'Explosion',
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
    exitPool: [
      AnimationType.fadeOut,
    ],
    animationDurationMs: 350,
    enableStroke: false,
    strokeColor: 0xFF000000,
    strokeWidth: 5.0,
    enableShadow: false,
    enableGlow: false,
    textCase: TextCase.upper,
  );

  static const perspectiveCrawl = KineticStyle(
    name: 'Perspective',
    icon: '🛣️',
    colorPalette: [0xFFFFD700, 0xFFFFFFFF], // Star wars yellow and white
    fontPool: ['Poppins', 'Michroma'],
    minFontSize: 24.0,
    maxFontSize: 80.0, // Large variance for perspective depth
    minScale: 0.5, // Will scale down at the top
    maxScale: 2.0, // Will scale up at the bottom
    maxRotation: 0.0,
    layoutPreset: LayoutPreset.perspective,
    entrancePool: [
      AnimationType.slideFromBottom,
      AnimationType.fadeIn,
    ],
    exitPool: [
      AnimationType.fadeOut,
    ],
    animationDurationMs: 600,
    enableStroke: false,
    enableShadow: false,
    enableGlow: false,
    textCase: TextCase.upper,
  );

  static const gridMatrix = KineticStyle(
    name: 'Grid Matrix',
    icon: '🔲',
    colorPalette: [0xFF00FF41, 0xFF008F11, 0xFFFFFFFF], // Hacker green
    fontPool: ['MajorMonoDisplay', 'Michroma'],
    minFontSize: 28.0,
    maxFontSize: 42.0,
    minScale: 0.9,
    maxScale: 1.1,
    maxRotation: 0.0,
    layoutPreset: LayoutPreset.grid,
    entrancePool: [
      AnimationType.typewriter,
      AnimationType.fadeIn,
    ],
    exitPool: [
      AnimationType.fadeOut,
    ],
    animationDurationMs: 400,
    enableStroke: false,
    enableShadow: false,
    enableGlow: false,
    textCase: TextCase.upper,
  );

  static const stairStep = KineticStyle(
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
    entrancePool: [
      AnimationType.slideFromBottom,
      AnimationType.slideFromTop,
    ],
    exitPool: [
      AnimationType.slideDown,
    ],
    animationDurationMs: 350,
    enableStroke: false,
    strokeColor: 0xFFFFFFFF,
    strokeWidth: 2.0,
    enableShadow: false,
    enableGlow: false,
    textCase: TextCase.title,
  );

  static const orbitalCircle = KineticStyle(
    name: 'Orbital',
    icon: '🪐',
    colorPalette: [0xFFFF9F1C, 0xFFFFBF69, 0xFFFFFFFF, 0xFFCBF3F0],
    fontPool: ['Poppins', 'LuckiestGuy'],
    minFontSize: 26.0,
    maxFontSize: 56.0,
    minScale: 0.8,
    maxScale: 1.3,
    maxRotation: 15.0,
    layoutPreset: LayoutPreset.circle,
    entrancePool: [
      AnimationType.spin,
      AnimationType.zoomIn,
    ],
    exitPool: [
      AnimationType.zoomOut,
      AnimationType.spin,
    ],
    animationDurationMs: 500,
    enableStroke: false,
    enableShadow: false,
    enableGlow: false,
    textCase: TextCase.upper,
  );

  static const hypnoticSpiral = KineticStyle(
    name: 'Hypnotic',
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
    exitPool: [
      AnimationType.zoomOut,
    ],
    animationDurationMs: 600,
    enableStroke: false,
    strokeColor: 0xFF000000,
    strokeWidth: 3.0,
    enableShadow: false,
    enableGlow: false,
    textCase: TextCase.title,
  );

  static const fullRandom = KineticStyle(
    name: 'Full Random',
    icon: '🎲',
    colorPalette: [
      0xFFFF0054, 0xFF00FFFF, 0xFFF000FF, 0xFFFFBD00, 0xFF7000FF,
      0xFF00FF41, 0xFFFF5400, 0xFF05D9E8, 0xFFFE6D73, 0xFFFFFFFF,
    ],
    fontPool: _defaultFonts,
    minFontSize: 26.0,
    maxFontSize: 76.0,
    minScale: 0.7,
    maxScale: 1.8,
    maxRotation: 15.0,
    layoutPreset: LayoutPreset.random,
    entrancePool: [
      AnimationType.fadeIn,
      AnimationType.slideUp,
      AnimationType.scaleUp,
      AnimationType.bounceIn,
      AnimationType.zoomIn,
      AnimationType.elasticDrop,
      AnimationType.glitch,
      AnimationType.flipX,
      AnimationType.throwback,
      AnimationType.spiralDrop,
      AnimationType.elasticStretch,
      AnimationType.flip3D_X,
      AnimationType.spin3D,
    ],
    exitPool: [
      AnimationType.fadeOut,
      AnimationType.slideDown,
      AnimationType.scaleDown,
      AnimationType.zoomOut,
    ],
    animationDurationMs: 400,
    enableStroke: false,
    strokeColor: 0xFF000000,
    strokeWidth: 2.5,
    enableShadow: false,
    enableGlow: false,
    textCase: TextCase.upper,
  );

  static const bentoBlocky = KineticStyle(
    name: 'Bento Blocky',
    icon: '🍱',
    colorPalette: [0xFFFF6B35, 0xFFFFFFFF, 0xFFF7C59F, 0xFF00B4D8, 0xFFABB2BF, 0xFFEAEAEA],
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
    exitPool: [
      AnimationType.scaleDown,
      AnimationType.fadeOut,
    ],
    animationDurationMs: 300,
    enableStroke: false,
    enableShadow: false,
    enableGlow: false,
    textCase: TextCase.upper,
  );
}
