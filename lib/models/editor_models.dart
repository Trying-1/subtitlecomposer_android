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
  wobble,
  shake,
  zoomIn,
  zoomOut,
  flipX,
  flipY,
  pulse,
  bounce,
  swing,
  spin,
  elasticDrop,
  heartbeat,
  jello,
}

enum EasingType {
  linear,
  easeIn,
  easeOut,
  easeInOut,
  bounceOut,
  elasticOut,
}

enum TrackType {
  text,
  overlay,
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

abstract class TimelineClip {
  String get id;
  Duration get startTime;
  Duration get endTime;
  double get x;
  double get y;
  double get rotation;
  double get scale;
  double get opacity;
  Duration get originalStartTime;
  Duration get originalEndTime;
  String? get originalTrackId;
  ClipAnimation get entranceAnimation;
  ClipAnimation get exitAnimation;
  ClipAnimation get loopAnimation;

  Map<String, dynamic> toJson();
}

class SubtitleClip implements TimelineClip {
  @override
  final String id;
  final String text;
  @override
  final Duration startTime;
  @override
  final Duration endTime;
  @override
  final double x;
  @override
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
  @override
  final double rotation;  // degrees
  @override
  final double scale;
  @override
  final double opacity;
  final String fontFamily;
  final double textOpacity;
  final bool isShadowEnabled;
  final bool isBackgroundEnabled;
  @override
  final Duration originalStartTime;
  @override
  final Duration originalEndTime;
  @override
  final String? originalTrackId;
  @override
  final ClipAnimation entranceAnimation;
  @override
  final ClipAnimation exitAnimation;
  @override
  final ClipAnimation loopAnimation;

  SubtitleClip({
    required this.id,
    required this.text,
    required this.startTime,
    required this.endTime,
    this.x = 0.5,
    this.y = 0.5,
    this.fontSize = 50.0,
    this.color = 0xFF000000,
    this.strokeColor = 0xFF000000,
    this.strokeWidth = 0.0,
    this.shadowColor = 0x00000000,
    this.shadowBlur = 0.0,
    this.shadowOffsetX = 0.0,
    this.shadowOffsetY = 0.0,
    this.backgroundColor = 0xFFFFFFFF,
    this.backgroundRadius = 0.0,
    this.letterSpacing = 0.0,
    this.rotation = 0.0,
    this.scale = 1.0,
    this.opacity = 1.0,
    this.textOpacity = 1.0,
    this.isShadowEnabled = true,
    this.isBackgroundEnabled = false,
    this.fontFamily = 'Poppins',
    this.entranceAnimation = const ClipAnimation(),
    this.exitAnimation = const ClipAnimation(),
    this.loopAnimation = const ClipAnimation(),
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
    'textOpacity': textOpacity,
    'isShadowEnabled': isShadowEnabled,
    'isBackgroundEnabled': isBackgroundEnabled,
    'fontFamily': fontFamily,
    'entranceAnimation': entranceAnimation.toJson(),
    'exitAnimation': exitAnimation.toJson(),
    'loopAnimation': loopAnimation.toJson(),
    'originalStartTime': originalStartTime.inMilliseconds,
    'originalEndTime': originalEndTime.inMilliseconds,
    'originalTrackId': originalTrackId,
  };

  factory SubtitleClip.fromJson(Map<String, dynamic> json) => SubtitleClip(
    id: json['id'],
    text: json['text'],
    startTime: Duration(milliseconds: json['startTime']),
    endTime: Duration(milliseconds: json['endTime']),
    x: (json['x'] as num?)?.toDouble() ?? 0.5,
    y: (json['y'] as num?)?.toDouble() ?? 0.5,
    fontSize: (json['fontSize'] as num?)?.toDouble() ?? 50.0,
    color: json['color'] as int? ?? 0xFF000000,
    strokeColor: json['strokeColor'] as int? ?? 0xFF000000,
    strokeWidth: (json['strokeWidth'] as num?)?.toDouble() ?? 0.0,
    shadowColor: json['shadowColor'] as int? ?? 0x00000000,
    shadowBlur: (json['shadowBlur'] as num?)?.toDouble() ?? 0.0,
    shadowOffsetX: (json['shadowOffsetX'] as num?)?.toDouble() ?? 0.0,
    shadowOffsetY: (json['shadowOffsetY'] as num?)?.toDouble() ?? 0.0,
    backgroundColor: json['backgroundColor'] as int? ?? 0xFFFFFFFF,
    backgroundRadius: (json['backgroundRadius'] as num?)?.toDouble() ?? 0.0,
    letterSpacing: (json['letterSpacing'] as num?)?.toDouble() ?? 0.0,
    rotation: (json['rotation'] as num?)?.toDouble() ?? 0.0,
    scale: (json['scale'] as num?)?.toDouble() ?? 1.0,
    opacity: (json['opacity'] as num?)?.toDouble() ?? 1.0,
    textOpacity: (json['textOpacity'] as num?)?.toDouble() ?? 1.0,
    isShadowEnabled: json['isShadowEnabled'] as bool? ?? true,
    isBackgroundEnabled: json['isBackgroundEnabled'] as bool? ?? true,
    fontFamily: json['fontFamily'] as String? ?? 'Poppins',
    entranceAnimation: ClipAnimation.fromJson(Map<String, dynamic>.from(json['entranceAnimation'])),
    exitAnimation: ClipAnimation.fromJson(Map<String, dynamic>.from(json['exitAnimation'])),
    loopAnimation: ClipAnimation.fromJson(Map<String, dynamic>.from(json['loopAnimation'] ?? {})),
    originalStartTime: Duration(milliseconds: json['originalStartTime'] ?? json['startTime']),
    originalEndTime: Duration(milliseconds: json['originalEndTime'] ?? json['endTime']),
    originalTrackId: json['originalTrackId'],
  );

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
    double? textOpacity,
    bool? isShadowEnabled,
    bool? isBackgroundEnabled,
    String? fontFamily,
    ClipAnimation? entranceAnimation,
    ClipAnimation? exitAnimation,
    ClipAnimation? loopAnimation,
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
    textOpacity: textOpacity ?? this.textOpacity,
    isShadowEnabled: isShadowEnabled ?? this.isShadowEnabled,
    isBackgroundEnabled: isBackgroundEnabled ?? this.isBackgroundEnabled,
    fontFamily: fontFamily ?? this.fontFamily,
    entranceAnimation: entranceAnimation ?? this.entranceAnimation,
    exitAnimation: exitAnimation ?? this.exitAnimation,
    loopAnimation: loopAnimation ?? this.loopAnimation,
    originalStartTime: originalStartTime ?? this.originalStartTime,
    originalEndTime: originalEndTime ?? this.originalEndTime,
    originalTrackId: originalTrackId ?? this.originalTrackId,
  );
}

class OverlayClip implements TimelineClip {
  @override
  final String id;
  final String imagePath;
  @override
  final Duration startTime;
  @override
  final Duration endTime;
  @override
  final double x;
  @override
  final double y;
  @override
  final double rotation;
  @override
  final double scale;
  @override
  final double opacity;
  @override
  final Duration originalStartTime;
  @override
  final Duration originalEndTime;
  @override
  final String? originalTrackId;
  @override
  final ClipAnimation entranceAnimation;
  @override
  final ClipAnimation exitAnimation;
  @override
  final ClipAnimation loopAnimation;

  OverlayClip({
    required this.id,
    required this.imagePath,
    required this.startTime,
    required this.endTime,
    this.x = 0.5,
    this.y = 0.5,
    this.rotation = 0.0,
    this.scale = 1.0,
    this.opacity = 1.0,
    this.entranceAnimation = const ClipAnimation(),
    this.exitAnimation = const ClipAnimation(),
    this.loopAnimation = const ClipAnimation(),
    Duration? originalStartTime,
    Duration? originalEndTime,
    this.originalTrackId,
  }) : originalStartTime = originalStartTime ?? startTime,
       originalEndTime = originalEndTime ?? endTime;

  Map<String, dynamic> toJson() => {
    'id': id,
    'imagePath': imagePath,
    'startTime': startTime.inMilliseconds,
    'endTime': endTime.inMilliseconds,
    'x': x,
    'y': y,
    'rotation': rotation,
    'scale': scale,
    'opacity': opacity,
    'entranceAnimation': entranceAnimation.toJson(),
    'exitAnimation': exitAnimation.toJson(),
    'loopAnimation': loopAnimation.toJson(),
    'originalStartTime': originalStartTime.inMilliseconds,
    'originalEndTime': originalEndTime.inMilliseconds,
    'originalTrackId': originalTrackId,
  };

  factory OverlayClip.fromJson(Map<String, dynamic> json) => OverlayClip(
    id: json['id'],
    imagePath: json['imagePath'],
    startTime: Duration(milliseconds: json['startTime']),
    endTime: Duration(milliseconds: json['endTime']),
    x: (json['x'] as num?)?.toDouble() ?? 0.5,
    y: (json['y'] as num?)?.toDouble() ?? 0.5,
    rotation: (json['rotation'] as num?)?.toDouble() ?? 0.0,
    scale: (json['scale'] as num?)?.toDouble() ?? 1.0,
    opacity: (json['opacity'] as num?)?.toDouble() ?? 1.0,
    entranceAnimation: ClipAnimation.fromJson(Map<String, dynamic>.from(json['entranceAnimation'])),
    exitAnimation: ClipAnimation.fromJson(Map<String, dynamic>.from(json['exitAnimation'])),
    loopAnimation: ClipAnimation.fromJson(Map<String, dynamic>.from(json['loopAnimation'] ?? {})),
    originalStartTime: Duration(milliseconds: json['originalStartTime'] ?? json['startTime']),
    originalEndTime: Duration(milliseconds: json['originalEndTime'] ?? json['endTime']),
    originalTrackId: json['originalTrackId'],
  );

  OverlayClip copyWith({
    String? id,
    String? imagePath,
    Duration? startTime,
    Duration? endTime,
    double? x,
    double? y,
    double? rotation,
    double? scale,
    double? opacity,
    ClipAnimation? entranceAnimation,
    ClipAnimation? exitAnimation,
    ClipAnimation? loopAnimation,
    Duration? originalStartTime,
    Duration? originalEndTime,
    String? originalTrackId,
  }) => OverlayClip(
    id: id ?? this.id,
    imagePath: imagePath ?? this.imagePath,
    startTime: startTime ?? this.startTime,
    endTime: endTime ?? this.endTime,
    x: x ?? this.x,
    y: y ?? this.y,
    rotation: rotation ?? this.rotation,
    scale: scale ?? this.scale,
    opacity: opacity ?? this.opacity,
    entranceAnimation: entranceAnimation ?? this.entranceAnimation,
    exitAnimation: exitAnimation ?? this.exitAnimation,
    loopAnimation: loopAnimation ?? this.loopAnimation,
    originalStartTime: originalStartTime ?? this.originalStartTime,
    originalEndTime: originalEndTime ?? this.originalEndTime,
    originalTrackId: originalTrackId ?? this.originalTrackId,
  );
}

class Track {
  final String id;
  final String name;
  final TrackType type;
  final List<SubtitleClip> clips;
  final List<OverlayClip> overlays;

  Track({
    required this.id,
    this.name = "Track",
    this.type = TrackType.text,
    this.clips = const [],
    this.overlays = const [],
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'type': type.index,
    'clips': clips.map((c) => c.toJson()).toList(),
    'overlays': overlays.map((c) => c.toJson()).toList(),
  };

  factory Track.fromJson(Map<String, dynamic> json) => Track(
    id: json['id'],
    name: json['name'] ?? "Track",
    type: TrackType.values[json['type'] ?? 0],
    clips: (json['clips'] as List? ?? []).map((c) => SubtitleClip.fromJson(Map<String, dynamic>.from(c))).toList(),
    overlays: (json['overlays'] as List? ?? []).map((o) => OverlayClip.fromJson(Map<String, dynamic>.from(o))).toList(),
  );
}
