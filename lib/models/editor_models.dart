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
  custom,
  graph,
}

enum TrackType {
  text,
  overlay,
  background,
  audio,
}

enum TextCase {
  none,
  upper,
  lower,
  title,
}

enum CustomBlendMode {
  normal,
  multiply,
  screen,
  overlay,
  darken,
  lighten,
  colorDodge,
  colorBurn,
  hardLight,
  softLight,
  difference,
  exclusion,
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

class Keyframe {
  final double timeOffset; // Relative to clip start in seconds
  final double? x;
  final double? y;
  final double? scale;
  final double? rotation;
  final double? opacity;
  final EasingType easing;
  final double? cp1x;
  final double? cp1y;
  final double? cp2x;
  final double? cp2y;
  final List<double>? customGraphPoints;

  const Keyframe({
    required this.timeOffset,
    this.x,
    this.y,
    this.scale,
    this.rotation,
    this.opacity,
    this.easing = EasingType.linear,
    this.cp1x,
    this.cp1y,
    this.cp2x,
    this.cp2y,
    this.customGraphPoints,
  });

  Map<String, dynamic> toJson() => {
    'timeOffset': timeOffset,
    'x': x,
    'y': y,
    'scale': scale,
    'rotation': rotation,
    'opacity': opacity,
    'easing': easing.index,
    'cp1x': cp1x,
    'cp1y': cp1y,
    'cp2x': cp2x,
    'cp2y': cp2y,
    'customGraphPoints': customGraphPoints,
  };

  factory Keyframe.fromJson(Map<String, dynamic> json) => Keyframe(
    timeOffset: (json['timeOffset'] as num).toDouble(),
    x: (json['x'] as num?)?.toDouble(),
    y: (json['y'] as num?)?.toDouble(),
    scale: (json['scale'] as num?)?.toDouble(),
    rotation: (json['rotation'] as num?)?.toDouble(),
    opacity: (json['opacity'] as num?)?.toDouble(),
    easing: EasingType.values[json['easing'] as int? ?? 0],
    cp1x: (json['cp1x'] as num?)?.toDouble(),
    cp1y: (json['cp1y'] as num?)?.toDouble(),
    cp2x: (json['cp2x'] as num?)?.toDouble(),
    cp2y: (json['cp2y'] as num?)?.toDouble(),
    customGraphPoints: (json['customGraphPoints'] as List?)?.map((e) => (e as num).toDouble()).toList(),
  );

  Keyframe copyWith({
    double? timeOffset,
    double? x,
    double? y,
    double? scale,
    double? rotation,
    double? opacity,
    EasingType? easing,
    double? cp1x,
    double? cp1y,
    double? cp2x,
    double? cp2y,
    List<double>? customGraphPoints,
  }) => Keyframe(
    timeOffset: timeOffset ?? this.timeOffset,
    x: x ?? this.x,
    y: y ?? this.y,
    scale: scale ?? this.scale,
    rotation: rotation ?? this.rotation,
    opacity: opacity ?? this.opacity,
    easing: easing ?? this.easing,
    cp1x: cp1x ?? this.cp1x,
    cp1y: cp1y ?? this.cp1y,
    cp2x: cp2x ?? this.cp2x,
    cp2y: cp2y ?? this.cp2y,
    customGraphPoints: customGraphPoints ?? this.customGraphPoints,
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
  List<Keyframe> get keyframes;
  int get sourceDurationMs;
  Duration get duration => endTime - startTime;

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
  final bool isStrokeEnabled;
  final CustomBlendMode blendMode;
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
  @override
  final List<Keyframe> keyframes;
  @override
  final int sourceDurationMs;
  @override
  Duration get duration => endTime - startTime;

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
    this.isStrokeEnabled = false,
    this.blendMode = CustomBlendMode.normal,
    this.fontFamily = 'Poppins',
    this.entranceAnimation = const ClipAnimation(),
    this.exitAnimation = const ClipAnimation(),
    this.loopAnimation = const ClipAnimation(),
    this.keyframes = const [],
    this.sourceDurationMs = 0,
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
    'isStrokeEnabled': isStrokeEnabled,
    'blendMode': blendMode.index,
    'fontFamily': fontFamily,
    'entranceAnimation': entranceAnimation.toJson(),
    'exitAnimation': exitAnimation.toJson(),
    'loopAnimation': loopAnimation.toJson(),
    'keyframes': keyframes.map((k) => k.toJson()).toList(),
    'sourceDurationMs': sourceDurationMs,
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
    isBackgroundEnabled: json['isBackgroundEnabled'] as bool? ?? false,
    isStrokeEnabled: json['isStrokeEnabled'] as bool? ?? ((json['strokeWidth'] as num?)?.toDouble() ?? 0.0) > 0,
    blendMode: CustomBlendMode.values[json['blendMode'] as int? ?? 0],
    fontFamily: json['fontFamily'] as String? ?? 'Poppins',
    entranceAnimation: ClipAnimation.fromJson(Map<String, dynamic>.from(json['entranceAnimation'])),
    exitAnimation: ClipAnimation.fromJson(Map<String, dynamic>.from(json['exitAnimation'])),
    loopAnimation: ClipAnimation.fromJson(Map<String, dynamic>.from(json['loopAnimation'] ?? {})),
    keyframes: (json['keyframes'] as List? ?? []).map((k) => Keyframe.fromJson(Map<String, dynamic>.from(k))).toList(),
    sourceDurationMs: json['sourceDurationMs'] as int? ?? 0,
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
    bool? isStrokeEnabled,
    CustomBlendMode? blendMode,
    String? fontFamily,
    ClipAnimation? entranceAnimation,
    ClipAnimation? exitAnimation,
    ClipAnimation? loopAnimation,
    List<Keyframe>? keyframes,
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
    isStrokeEnabled: isStrokeEnabled ?? this.isStrokeEnabled,
    blendMode: blendMode ?? this.blendMode,
    fontFamily: fontFamily ?? this.fontFamily,
    entranceAnimation: entranceAnimation ?? this.entranceAnimation,
    exitAnimation: exitAnimation ?? this.exitAnimation,
    loopAnimation: loopAnimation ?? this.loopAnimation,
    keyframes: keyframes ?? this.keyframes,
    sourceDurationMs: sourceDurationMs ?? this.sourceDurationMs,
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
  final bool isShadowEnabled;
  final int shadowColor;
  final double shadowBlur;
  final double shadowOffsetX;
  final double shadowOffsetY;
  final bool isStrokeEnabled;
  final int strokeColor;
  final double strokeWidth;
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
  @override
  final List<Keyframe> keyframes;
  @override
  final int sourceDurationMs;
  @override
  Duration get duration => endTime - startTime;

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
    this.isShadowEnabled = false,
    this.shadowColor = 0x00000000,
    this.shadowBlur = 0.0,
    this.shadowOffsetX = 0.0,
    this.shadowOffsetY = 0.0,
    this.isStrokeEnabled = false,
    this.strokeColor = 0xFF000000,
    this.strokeWidth = 0.0,
    this.entranceAnimation = const ClipAnimation(),
    this.exitAnimation = const ClipAnimation(),
    this.loopAnimation = const ClipAnimation(),
    this.keyframes = const [],
    this.sourceDurationMs = 0,
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
    'isShadowEnabled': isShadowEnabled,
    'shadowColor': shadowColor,
    'shadowBlur': shadowBlur,
    'shadowOffsetX': shadowOffsetX,
    'shadowOffsetY': shadowOffsetY,
    'isStrokeEnabled': isStrokeEnabled,
    'strokeColor': strokeColor,
    'strokeWidth': strokeWidth,
    'entranceAnimation': entranceAnimation.toJson(),
    'exitAnimation': exitAnimation.toJson(),
    'loopAnimation': loopAnimation.toJson(),
    'keyframes': keyframes.map((k) => k.toJson()).toList(),
    'sourceDurationMs': sourceDurationMs,
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
    isShadowEnabled: json['isShadowEnabled'] as bool? ?? false,
    shadowColor: json['shadowColor'] as int? ?? 0x00000000,
    shadowBlur: (json['shadowBlur'] as num?)?.toDouble() ?? 0.0,
    shadowOffsetX: (json['shadowOffsetX'] as num?)?.toDouble() ?? 0.0,
    shadowOffsetY: (json['shadowOffsetY'] as num?)?.toDouble() ?? 0.0,
    isStrokeEnabled: json['isStrokeEnabled'] as bool? ?? false,
    strokeColor: json['strokeColor'] as int? ?? 0xFF000000,
    strokeWidth: (json['strokeWidth'] as num?)?.toDouble() ?? 0.0,
    entranceAnimation: ClipAnimation.fromJson(Map<String, dynamic>.from(json['entranceAnimation'])),
    exitAnimation: ClipAnimation.fromJson(Map<String, dynamic>.from(json['exitAnimation'])),
    loopAnimation: ClipAnimation.fromJson(Map<String, dynamic>.from(json['loopAnimation'] ?? {})),
    keyframes: (json['keyframes'] as List? ?? []).map((k) => Keyframe.fromJson(Map<String, dynamic>.from(k))).toList(),
    sourceDurationMs: json['sourceDurationMs'] as int? ?? 0,
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
    bool? isShadowEnabled,
    int? shadowColor,
    double? shadowBlur,
    double? shadowOffsetX,
    double? shadowOffsetY,
    bool? isStrokeEnabled,
    int? strokeColor,
    double? strokeWidth,
    ClipAnimation? entranceAnimation,
    ClipAnimation? exitAnimation,
    ClipAnimation? loopAnimation,
    List<Keyframe>? keyframes,
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
    isShadowEnabled: isShadowEnabled ?? this.isShadowEnabled,
    shadowColor: shadowColor ?? this.shadowColor,
    shadowBlur: shadowBlur ?? this.shadowBlur,
    shadowOffsetX: shadowOffsetX ?? this.shadowOffsetX,
    shadowOffsetY: shadowOffsetY ?? this.shadowOffsetY,
    isStrokeEnabled: isStrokeEnabled ?? this.isStrokeEnabled,
    strokeColor: strokeColor ?? this.strokeColor,
    strokeWidth: strokeWidth ?? this.strokeWidth,
    entranceAnimation: entranceAnimation ?? this.entranceAnimation,
    exitAnimation: exitAnimation ?? this.exitAnimation,
    loopAnimation: loopAnimation ?? this.loopAnimation,
    keyframes: keyframes ?? this.keyframes,
    sourceDurationMs: sourceDurationMs ?? this.sourceDurationMs,
    originalStartTime: originalStartTime ?? this.originalStartTime,
    originalEndTime: originalEndTime ?? this.originalEndTime,
    originalTrackId: originalTrackId ?? this.originalTrackId,
  );
}

class BackgroundClip implements TimelineClip {
  @override
  final String id;
  final String? imagePath;
  final int color;
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
  final int fillMode; // 0: cover, 1: fit, 2: center
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
  @override
  final List<Keyframe> keyframes;
  @override
  final int sourceDurationMs;
  @override
  Duration get duration => endTime - startTime;

  BackgroundClip({
    required this.id,
    this.imagePath,
    this.color = 0xFFFFFFFF,
    required this.startTime,
    required this.endTime,
    this.x = 0.5,
    this.y = 0.5,
    this.rotation = 0.0,
    this.scale = 1.0,
    this.opacity = 1.0,
    this.fillMode = 0,
    this.entranceAnimation = const ClipAnimation(),
    this.exitAnimation = const ClipAnimation(),
    this.loopAnimation = const ClipAnimation(),
    this.keyframes = const [],
    this.sourceDurationMs = 0,
    Duration? originalStartTime,
    Duration? originalEndTime,
    this.originalTrackId,
  }) : originalStartTime = originalStartTime ?? startTime,
       originalEndTime = originalEndTime ?? endTime;

  @override
  Map<String, dynamic> toJson() => {
    'id': id,
    'imagePath': imagePath,
    'color': color,
    'startTime': startTime.inMilliseconds,
    'endTime': endTime.inMilliseconds,
    'x': x,
    'y': y,
    'rotation': rotation,
    'scale': scale,
    'opacity': opacity,
    'fillMode': fillMode,
    'entranceAnimation': entranceAnimation.toJson(),
    'exitAnimation': exitAnimation.toJson(),
    'loopAnimation': loopAnimation.toJson(),
    'keyframes': keyframes.map((k) => k.toJson()).toList(),
    'sourceDurationMs': sourceDurationMs,
    'originalStartTime': originalStartTime.inMilliseconds,
    'originalEndTime': originalEndTime.inMilliseconds,
    'originalTrackId': originalTrackId,
  };

  factory BackgroundClip.fromJson(Map<String, dynamic> json) => BackgroundClip(
    id: json['id'],
    imagePath: json['imagePath'],
    color: json['color'] as int? ?? 0xFFFFFFFF,
    startTime: Duration(milliseconds: json['startTime']),
    endTime: Duration(milliseconds: json['endTime']),
    x: (json['x'] as num?)?.toDouble() ?? 0.5,
    y: (json['y'] as num?)?.toDouble() ?? 0.5,
    rotation: (json['rotation'] as num?)?.toDouble() ?? 0.0,
    scale: (json['scale'] as num?)?.toDouble() ?? 1.0,
    opacity: (json['opacity'] as num?)?.toDouble() ?? 1.0,
    fillMode: json['fillMode'] as int? ?? 0,
    entranceAnimation: ClipAnimation.fromJson(Map<String, dynamic>.from(json['entranceAnimation'])),
    exitAnimation: ClipAnimation.fromJson(Map<String, dynamic>.from(json['exitAnimation'])),
    loopAnimation: ClipAnimation.fromJson(Map<String, dynamic>.from(json['loopAnimation'] ?? {})),
    keyframes: (json['keyframes'] as List? ?? []).map((k) => Keyframe.fromJson(Map<String, dynamic>.from(k))).toList(),
    sourceDurationMs: json['sourceDurationMs'] as int? ?? 0,
    originalStartTime: Duration(milliseconds: json['originalStartTime'] ?? json['startTime']),
    originalEndTime: Duration(milliseconds: json['originalEndTime'] ?? json['endTime']),
    originalTrackId: json['originalTrackId'],
  );

  BackgroundClip copyWith({
    String? id,
    String? imagePath,
    int? color,
    Duration? startTime,
    Duration? endTime,
    double? x,
    double? y,
    double? rotation,
    double? scale,
    double? opacity,
    int? fillMode,
    ClipAnimation? entranceAnimation,
    ClipAnimation? exitAnimation,
    ClipAnimation? loopAnimation,
    List<Keyframe>? keyframes,
    Duration? originalStartTime,
    Duration? originalEndTime,
    String? originalTrackId,
  }) => BackgroundClip(
    id: id ?? this.id,
    imagePath: imagePath ?? this.imagePath,
    color: color ?? this.color,
    startTime: startTime ?? this.startTime,
    endTime: endTime ?? this.endTime,
    x: x ?? this.x,
    y: y ?? this.y,
    rotation: rotation ?? this.rotation,
    scale: scale ?? this.scale,
    opacity: opacity ?? this.opacity,
    fillMode: fillMode ?? this.fillMode,
    entranceAnimation: entranceAnimation ?? this.entranceAnimation,
    exitAnimation: exitAnimation ?? this.exitAnimation,
    loopAnimation: loopAnimation ?? this.loopAnimation,
    keyframes: keyframes ?? this.keyframes,
    sourceDurationMs: sourceDurationMs ?? this.sourceDurationMs,
    originalStartTime: originalStartTime ?? this.originalStartTime,
    originalEndTime: originalEndTime ?? this.originalEndTime,
    originalTrackId: originalTrackId ?? this.originalTrackId,
  );
}

class AudioClip implements TimelineClip {
  @override
  final String id;
  final String audioPath;
  @override
  final Duration startTime;
  @override
  final Duration endTime;
  final double volume;
  @override
  final double x = 0;
  @override
  final double y = 0;
  @override
  final double rotation = 0;
  @override
  final double scale = 1;
  @override
  final double opacity = 1;
  @override
  final Duration originalStartTime;
  @override
  final Duration originalEndTime;
  @override
  final String? originalTrackId;
  @override
  final ClipAnimation entranceAnimation = const ClipAnimation();
  @override
  final ClipAnimation exitAnimation = const ClipAnimation();
  @override
  final ClipAnimation loopAnimation = const ClipAnimation();
  @override
  final List<Keyframe> keyframes = const [];
  @override
  final int sourceDurationMs;
  final bool isMainAudio;
  @override
  Duration get duration => endTime - startTime;

  AudioClip({
    required this.id,
    required this.audioPath,
    required this.startTime,
    required this.endTime,
    this.volume = 1.0,
    this.sourceDurationMs = 0,
    this.isMainAudio = false,
    Duration? originalStartTime,
    Duration? originalEndTime,
    this.originalTrackId,
  }) : originalStartTime = originalStartTime ?? startTime,
       originalEndTime = originalEndTime ?? endTime;

  @override
  Map<String, dynamic> toJson() => {
    'id': id,
    'audioPath': audioPath,
    'startTime': startTime.inMilliseconds,
    'endTime': endTime.inMilliseconds,
    'volume': volume,
    'sourceDurationMs': sourceDurationMs,
    'isMainAudio': isMainAudio,
    'originalStartTime': originalStartTime.inMilliseconds,
    'originalEndTime': originalEndTime.inMilliseconds,
    'originalTrackId': originalTrackId,
  };

  factory AudioClip.fromJson(Map<String, dynamic> json) => AudioClip(
    id: json['id'],
    audioPath: json['audioPath'],
    startTime: Duration(milliseconds: json['startTime']),
    endTime: Duration(milliseconds: json['endTime']),
    volume: (json['volume'] as num?)?.toDouble() ?? 1.0,
    sourceDurationMs: json['sourceDurationMs'] as int? ?? 0,
    isMainAudio: json['isMainAudio'] as bool? ?? false,
    originalStartTime: Duration(milliseconds: json['originalStartTime'] ?? json['startTime']),
    originalEndTime: Duration(milliseconds: json['originalEndTime'] ?? json['endTime']),
    originalTrackId: json['originalTrackId'],
  );

  AudioClip copyWith({
    String? id,
    String? audioPath,
    Duration? startTime,
    Duration? endTime,
    double? volume,
    int? sourceDurationMs,
    bool? isMainAudio,
    Duration? originalStartTime,
    Duration? originalEndTime,
    String? originalTrackId,
  }) => AudioClip(
    id: id ?? this.id,
    audioPath: audioPath ?? this.audioPath,
    startTime: startTime ?? this.startTime,
    endTime: endTime ?? this.endTime,
    volume: volume ?? this.volume,
    sourceDurationMs: sourceDurationMs ?? this.sourceDurationMs,
    isMainAudio: isMainAudio ?? this.isMainAudio,
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
  final List<BackgroundClip> backgrounds;
  final List<AudioClip> audioClips;

  Track({
    required this.id,
    this.name = "Track",
    this.type = TrackType.text,
    this.clips = const [],
    this.overlays = const [],
    this.backgrounds = const [],
    this.audioClips = const [],
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'type': type.index,
    'clips': clips.map((c) => c.toJson()).toList(),
    'overlays': overlays.map((c) => c.toJson()).toList(),
    'backgrounds': backgrounds.map((c) => c.toJson()).toList(),
    'audioClips': audioClips.map((c) => c.toJson()).toList(),
  };

  factory Track.fromJson(Map<String, dynamic> json) => Track(
    id: json['id'],
    name: json['name'] ?? "Track",
    type: TrackType.values[json['type'] ?? 0],
    clips: (json['clips'] as List? ?? []).map((c) => SubtitleClip.fromJson(Map<String, dynamic>.from(c))).toList(),
    overlays: (json['overlays'] as List? ?? []).map((o) => OverlayClip.fromJson(Map<String, dynamic>.from(o))).toList(),
    backgrounds: (json['backgrounds'] as List? ?? []).map((b) => BackgroundClip.fromJson(Map<String, dynamic>.from(b))).toList(),
    audioClips: (json['audioClips'] as List? ?? []).map((a) => AudioClip.fromJson(Map<String, dynamic>.from(a))).toList(),
  );

  Track copyWith({
    String? id,
    String? name,
    TrackType? type,
    List<SubtitleClip>? clips,
    List<OverlayClip>? overlays,
    List<BackgroundClip>? backgrounds,
  }) => Track(
    id: id ?? this.id,
    name: name ?? this.name,
    type: type ?? this.type,
    clips: clips ?? this.clips,
    overlays: overlays ?? this.overlays,
    backgrounds: backgrounds ?? this.backgrounds,
    audioClips: audioClips ?? this.audioClips,
  );
}
