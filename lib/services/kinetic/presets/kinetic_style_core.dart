import '../../../models/editor_models.dart';

enum RotationMode { none, random, orthogonal }

class KineticStyle {
  final String name;
  final String icon;
  final List<int> colorPalette;
  final List<String> fontPool;
  final double minFontSize;
  final double maxFontSize;
  final double minScale;
  final double maxScale;
  final double maxRotation;
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
    String? name, String? icon, List<int>? colorPalette, List<String>? fontPool,
    double? minFontSize, double? maxFontSize, double? minScale, double? maxScale,
    double? maxRotation, RotationMode? rotationMode, LayoutPreset? layoutPreset,
    List<AnimationType>? entrancePool, List<AnimationType>? exitPool,
    int? animationDurationMs, bool? enableStroke, int? strokeColor,
    double? strokeWidth, bool? enableShadow, bool? enableGlow, TextCase? textCase,
    bool? enableEntranceAnimation, bool? enableExitAnimation,
  }) => KineticStyle(
    name: name ?? this.name, icon: icon ?? this.icon, colorPalette: colorPalette ?? this.colorPalette,
    fontPool: fontPool ?? this.fontPool, minFontSize: minFontSize ?? this.minFontSize,
    maxFontSize: maxFontSize ?? this.maxFontSize, minScale: minScale ?? this.minScale,
    maxScale: maxScale ?? this.maxScale, maxRotation: maxRotation ?? this.maxRotation,
    rotationMode: rotationMode ?? this.rotationMode, layoutPreset: layoutPreset ?? this.layoutPreset,
    entrancePool: entrancePool ?? this.entrancePool, exitPool: exitPool ?? this.exitPool,
    animationDurationMs: animationDurationMs ?? this.animationDurationMs,
    enableStroke: enableStroke ?? this.enableStroke, strokeColor: strokeColor ?? this.strokeColor,
    strokeWidth: strokeWidth ?? this.strokeWidth, enableShadow: enableShadow ?? this.enableShadow,
    enableGlow: enableGlow ?? this.enableGlow, textCase: textCase ?? this.textCase,
    enableEntranceAnimation: enableEntranceAnimation ?? this.enableEntranceAnimation,
    enableExitAnimation: enableExitAnimation ?? this.enableExitAnimation,
  );
}

const defaultFonts = [
  'Poppins', 'LuckiestGuy', 'Michroma', 'NewRocker',
  'BhuTukaExpandedOne', 'Bokor', 'Lacquer', 'MajorMonoDisplay',
];
