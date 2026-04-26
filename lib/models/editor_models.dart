enum AnimationType {
  none,
  fadeIn,
  fadeOut,
  slideUp,
  slideDown,
  slideLeft,
  slideRight,
  scaleUp,
  scaleDown,
  typewriter,
  bounceIn,
  rotateIn,
}

enum EasingType {
  linear,
  easeIn,
  easeOut,
  easeInOut,
  bounceOut,
  elasticOut,
}

class ClipAnimation {
  final AnimationType type;
  final EasingType easing;
  final int durationMs;

  const ClipAnimation({
    this.type = AnimationType.none,
    this.easing = EasingType.easeOut,
    this.durationMs = 500,
  });

  Map<String, dynamic> toJson() => {
    'type': type.index,
    'easing': easing.index,
    'durationMs': durationMs,
  };

  factory ClipAnimation.fromJson(Map<String, dynamic> json) => ClipAnimation(
    type: AnimationType.values[json['type'] as int? ?? 0],
    easing: EasingType.values[json['easing'] as int? ?? 0],
    durationMs: json['durationMs'] as int? ?? 500,
  );

  ClipAnimation copyWith({
    AnimationType? type,
    EasingType? easing,
    int? durationMs,
  }) => ClipAnimation(
    type: type ?? this.type,
    easing: easing ?? this.easing,
    durationMs: durationMs ?? this.durationMs,
  );
}

class SubtitleClip {
  final String id;
  final String text;
  final Duration startTime;
  final Duration endTime;
  final double x;
  final double y;
  final double fontSize;
  final int color; // ARGB
  final int strokeColor;
  final double strokeWidth;
  final int shadowColor;
  final double shadowBlur;
  final double shadowOffsetX;
  final double shadowOffsetY;
  final int backgroundColor;
  final double backgroundRadius;
  final double letterSpacing;
  final double rotation;  // degrees
  final double scale;
  final double opacity;
  final String fontFamily;
  final ClipAnimation entranceAnimation;
  final ClipAnimation exitAnimation;
  final Duration originalStartTime;
  final Duration originalEndTime;
  final String? originalTrackId;

  SubtitleClip({
    required this.id,
    required this.text,
    required this.startTime,
    required this.endTime,
    this.x = 0.5,
    this.y = 0.8,
    this.fontSize = 24.0,
    this.color = 0xFFFFFFFF,
    this.strokeColor = 0xFF000000,
    this.strokeWidth = 0.0,
    this.shadowColor = 0x00000000,
    this.shadowBlur = 0.0,
    this.shadowOffsetX = 0.0,
    this.shadowOffsetY = 0.0,
    this.backgroundColor = 0x00000000,
    this.backgroundRadius = 0.0,
    this.letterSpacing = 0.0,
    this.rotation = 0.0,
    this.scale = 1.0,
    this.opacity = 1.0,
    this.fontFamily = 'Poppins',
    this.entranceAnimation = const ClipAnimation(),
    this.exitAnimation = const ClipAnimation(),
    Duration? originalStartTime,
    Duration? originalEndTime,
    this.originalTrackId,
  }) : originalStartTime = originalStartTime ?? startTime,
       originalEndTime = originalEndTime ?? endTime;

  Map<String, dynamic> toJson() => {
    'id': id,
    'text': text,
    'startTime': startTime.inMilliseconds,
    'endTime': endTime.inMilliseconds,
    'x': x,
    'y': y,
    'fontSize': fontSize,
    'color': color,
    'strokeColor': strokeColor,
    'strokeWidth': strokeWidth,
    'shadowColor': shadowColor,
    'shadowBlur': shadowBlur,
    'shadowOffsetX': shadowOffsetX,
    'shadowOffsetY': shadowOffsetY,
    'backgroundColor': backgroundColor,
    'backgroundRadius': backgroundRadius,
    'letterSpacing': letterSpacing,
    'rotation': rotation,
    'scale': scale,
    'opacity': opacity,
    'fontFamily': fontFamily,
    'entranceAnimation': entranceAnimation.toJson(),
    'exitAnimation': exitAnimation.toJson(),
    'originalStartTime': originalStartTime.inMilliseconds,
    'originalEndTime': originalEndTime.inMilliseconds,
    'originalTrackId': originalTrackId,
  };

  SubtitleClip copyWith({
    String? id,
    String? text,
    Duration? startTime,
    Duration? endTime,
    double? x,
    double? y,
    double? fontSize,
    int? color,
    int? strokeColor,
    double? strokeWidth,
    int? shadowColor,
    double? shadowBlur,
    double? shadowOffsetX,
    double? shadowOffsetY,
    int? backgroundColor,
    double? backgroundRadius,
    double? letterSpacing,
    double? rotation,
    double? scale,
    double? opacity,
    String? fontFamily,
    ClipAnimation? entranceAnimation,
    ClipAnimation? exitAnimation,
    Duration? originalStartTime,
    Duration? originalEndTime,
    String? originalTrackId,
  }) => SubtitleClip(
    id: id ?? this.id,
    text: text ?? this.text,
    startTime: startTime ?? this.startTime,
    endTime: endTime ?? this.endTime,
    x: x ?? this.x,
    y: y ?? this.y,
    fontSize: fontSize ?? this.fontSize,
    color: color ?? this.color,
    strokeColor: strokeColor ?? this.strokeColor,
    strokeWidth: strokeWidth ?? this.strokeWidth,
    shadowColor: shadowColor ?? this.shadowColor,
    shadowBlur: shadowBlur ?? this.shadowBlur,
    shadowOffsetX: shadowOffsetX ?? this.shadowOffsetX,
    shadowOffsetY: shadowOffsetY ?? this.shadowOffsetY,
    backgroundColor: backgroundColor ?? this.backgroundColor,
    backgroundRadius: backgroundRadius ?? this.backgroundRadius,
    letterSpacing: letterSpacing ?? this.letterSpacing,
    rotation: rotation ?? this.rotation,
    scale: scale ?? this.scale,
    opacity: opacity ?? this.opacity,
    fontFamily: fontFamily ?? this.fontFamily,
    entranceAnimation: entranceAnimation ?? this.entranceAnimation,
    exitAnimation: exitAnimation ?? this.exitAnimation,
    originalStartTime: originalStartTime ?? this.originalStartTime,
    originalEndTime: originalEndTime ?? this.originalEndTime,
    originalTrackId: originalTrackId ?? this.originalTrackId,
  );
}

class Track {
  final String id;
  final String name;
  final List<SubtitleClip> clips;

  Track({
    required this.id,
    this.name = "Track",
    this.clips = const [],
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'clips': clips.map((c) => c.toJson()).toList(),
  };
}
