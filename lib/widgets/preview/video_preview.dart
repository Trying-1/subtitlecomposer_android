import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/editor_provider.dart';
import '../../models/editor_models.dart';
import '../../services/native_bridge.dart';

class VideoPreview extends StatefulWidget {
  const VideoPreview({super.key});

  @override
  State<VideoPreview> createState() => _VideoPreviewState();
}

class _VideoPreviewState extends State<VideoPreview> {
  final NativeBridge _bridge = NativeBridge();
  final GlobalKey _canvasKey = GlobalKey();
  int? _textureId;
  bool _isInitialized = false;

  final Map<String, ui.Size> _imageDimensions = {};

  @override
  void initState() {
    super.initState();
    _initPreview();
  }

  Future<void> _initPreview() async {
    final textureId = await _bridge.initRenderer(1280, 720);
    if (mounted) {
      final provider = context.read<EditorProvider>();
      provider.syncToNative(); // Trigger full sync after native engine is ready
      setState(() {
        _textureId = textureId;
        _isInitialized = true;
      });
    }
  }

  @override
  void dispose() {
    _bridge.disposeRenderer();
    super.dispose();
  }

  double _baseScale = 1.0;
  bool _allowInteraction = false;
  bool _isWorkspaceNavigating = false;
  
  double _previewZoom = 1.0;
  double _basePreviewZoom = 1.0;
  Offset _previewOffset = Offset.zero;
  Offset _basePreviewOffset = Offset.zero;

  double _startFocalPointX = 0;
  
  // Scaling/Rotation state
  bool _isScaling = false;
  bool _isRotating = false;
  double _initialScale = 1.0;
  double _initialRotation = 0.0;
  double _initialDistance = 1.0;
  double _initialAngle = 0.0;

  void _handleScaleStart(ScaleStartDetails details, BoxConstraints constraints) {
    final provider = context.read<EditorProvider>();
    
    _allowInteraction = false;
    _isWorkspaceNavigating = false;

    // Mode-based or Multi-touch: Workspace zoom/pan
    if (provider.isPreviewZoomMode || details.pointerCount >= 2) {
      debugPrint("VideoPreview: Pan/Zoom Start. Mode: ${provider.isPreviewZoomMode}, Pointers: ${details.pointerCount}");
      _isWorkspaceNavigating = true;
      _basePreviewZoom = provider.previewZoom;
      _basePreviewOffset = provider.previewOffset;
      return;
    }

    final tapX = details.localFocalPoint.dx / constraints.maxWidth;
    final tapY = details.localFocalPoint.dy / constraints.maxHeight;

    final currentlySelected = provider.selectedTimelineClip;
    
    if (currentlySelected != null && !(currentlySelected is BackgroundClip)) {
      final dx = (tapX - currentlySelected.x).abs();
      final dy = (tapY - currentlySelected.y).abs();
      
      if (dx < 0.15 && dy < 0.15) {
        _allowInteraction = true;
        _baseScale = currentlySelected.scale;
        return;
      }
    }

    provider.selectClipAt(tapX, tapY, deselectIfEmpty: false, toggle: false);
    
    // If no clip is selected at this position, allow direct panning
    final currentSelected = provider.selectedTimelineClip;
    if (currentSelected == null || currentSelected is BackgroundClip) {
      debugPrint("VideoPreview: Empty space. Enabling Pan.");
      _isWorkspaceNavigating = true;
      _basePreviewZoom = provider.previewZoom;
      _basePreviewOffset = provider.previewOffset;
      return;
    }

    _allowInteraction = false;
  }

  void _handleScaleUpdate(BuildContext context, ScaleUpdateDetails details, BoxConstraints constraints) {
    final provider = context.read<EditorProvider>();

    if (_isWorkspaceNavigating) {
      final newZoom = (_basePreviewZoom * details.scale).clamp(0.5, 10.0);
      if (newZoom != provider.previewZoom) {
        provider.setPreviewZoom(newZoom);
      }
      
      if (details.focalPointDelta != Offset.zero) {
        debugPrint("VideoPreview: Panning delta: ${details.focalPointDelta}");
        provider.updatePreviewOffset(details.focalPointDelta);
      }
      return;
    }

    if (!_allowInteraction) return;

    final clip = provider.selectedTimelineClip;
    if (clip == null || clip is BackgroundClip) return;

    // Handle drag
    final dx = details.focalPointDelta.dx / constraints.maxWidth;
    final dy = details.focalPointDelta.dy / constraints.maxHeight;

    if (provider.selectedClipIds.length > 1) {
      provider.moveClips(provider.selectedClipIds, dx, dy, silent: true);
    } else {
      provider.updateClip(
        clip.id,
        x: (clip.x + dx).clamp(-0.5, 1.5),
        y: (clip.y + dy).clamp(-0.5, 1.5),
        silent: true,
      );
      setState(() {}); // Trigger local rebuild so selection box follows
    }
  }

  void _handleScaleEnd() {
    final provider = context.read<EditorProvider>();
    // Final sync and notify to ensure all other UI (like timeline) updates
    provider.syncToNative();
    provider.notifyListeners();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_textureId == null) {
      return const Center(child: Text("Failed to initialize OpenGL preview"));
    }

    final provider = context.watch<EditorProvider>();

    return LayoutBuilder(
      builder: (context, outerConstraints) {
        return Container(
          color: const Color(0xFF16161A), // Even darker for focus
          clipBehavior: Clip.hardEdge,
          decoration: const BoxDecoration(), // Required for clip
          child: Stack(
            children: [
              // 1. Canvas Layer
              Center(
                child: Transform(
                  transform: Matrix4.identity()
                    ..translate(provider.previewOffset.dx, provider.previewOffset.dy)
                    ..scale(provider.previewZoom),
                  alignment: Alignment.center,
                  child: AspectRatio(
                    key: ValueKey('preview_${provider.aspectRatio}'),
                    aspectRatio: provider.aspectRatio,
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                      final dpr = MediaQuery.of(context).devicePixelRatio;
                      // Sync actual dimensions to native only when they change
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        final width = (constraints.maxWidth * dpr * provider.previewZoom).toInt();
                        final height = (constraints.maxHeight * dpr * provider.previewZoom).toInt();
                        if (width != provider.lastRenderWidth || height != provider.lastRenderHeight) {
                          provider.updateProjectSync(width: width, height: height);
                        }
                      });

                      return RepaintBoundary(
                        key: provider.previewRepaintKey,
                        child: Container(
                          key: _canvasKey,
                          color: Color(provider.backgroundColor), // Actual video background
                          child: Stack(
                            children: [
                              GestureDetector(
                                behavior: HitTestBehavior.opaque,
                                onScaleStart: (details) => _handleScaleStart(details, constraints),
                                onScaleUpdate: (details) => _handleScaleUpdate(context, details, constraints),
                                onScaleEnd: (_) => _handleScaleEnd(),
                                onTapUp: (details) {
                                  if (provider.isPreviewZoomMode) return;
                                  final tapX = details.localPosition.dx / constraints.maxWidth;
                                  final tapY = details.localPosition.dy / constraints.maxHeight;
                                  provider.selectClipAt(tapX, tapY);
                                },
                                child: Texture(textureId: _textureId!),
                              ),
                              // Selection Overlay (Single or Multi)
                              _buildSelectionOverlay(provider, constraints),
                            ],
                          ),
                        ),
                      );
                      },
                  ),
                ),
              ),
            ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSelectionOverlay(EditorProvider provider, BoxConstraints constraints) {
    final visibleSelected = provider.selectedTimelineClips.where((c) => 
      !(c is BackgroundClip) &&
      provider.currentTime >= c.startTime &&
      provider.currentTime <= c.endTime
    ).toList();

    if (visibleSelected.isEmpty || provider.isPreviewZoomMode) return const SizedBox.shrink();

    double minX = double.infinity;
    double minY = double.infinity;
    double maxX = -double.infinity;
    double maxY = -double.infinity;

    for (var clip in visibleSelected) {
      final size = _getClipSize(clip, constraints);
      final left = (clip.x * constraints.maxWidth) - (size.width / 2);
      final top = (clip.y * constraints.maxHeight) - (size.height / 2);
      final right = left + size.width;
      final bottom = top + size.height;

      if (left < minX) minX = left;
      if (top < minY) minY = top;
      if (right > maxX) maxX = right;
      if (bottom > maxY) maxY = bottom;
    }

    final clip = visibleSelected.first;
    final centerX = clip.x * constraints.maxWidth;
    final centerY = clip.y * constraints.maxHeight;
    final boxSize = math.max(maxX - minX, maxY - minY);
    
    final bgColor = Color(provider.backgroundColor);
    final selectionColor = bgColor.computeLuminance() > 0.5 ? Colors.black : Colors.white;

    return Stack(
      children: [
        Transform.rotate(
          angle: -clip.rotation * math.pi / 180,
          origin: Offset(centerX, centerY),
          alignment: Alignment.topLeft,
          child: Stack(
            children: [
              // Selection Border
              Positioned(
                left: minX,
                top: minY,
                width: maxX - minX,
                height: maxY - minY,
                child: IgnorePointer(
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: selectionColor, width: 1.0 / provider.previewZoom),
                    ),
                  ),
                ),
              ),
              
              // Corner Handles (Dots)
              _buildHandle(minX, minY, 0, boxSize, provider, constraints, clip, selectionColor), // Top Left
              _buildHandle(maxX, minY, 1, boxSize, provider, constraints, clip, selectionColor), // Top Right
              _buildHandle(minX, maxY, 2, boxSize, provider, constraints, clip, selectionColor), // Bottom Left
              _buildHandle(maxX, maxY, 3, boxSize, provider, constraints, clip, selectionColor), // Bottom Right
              
              // Rotation Handle (Top Right, slightly offset)
              _buildRotationHandle(maxX, minY, boxSize, provider, constraints, clip, selectionColor),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRotationHandle(double x, double y, double boxSize, EditorProvider provider, BoxConstraints constraints, TimelineClip clip, Color selectionColor) {
    final double scaleFactor = math.min(1.0, math.max(0.3, boxSize / 150.0)) / provider.previewZoom;
    final double handleSize = 24.0 * scaleFactor;
    final double touchSize = math.max(30.0 / provider.previewZoom, handleSize * 1.5);
    final double offset = 25.0 * scaleFactor; // Distance from corner
    
    return Positioned(
      left: x + offset - (touchSize / 2),
      top: y - offset - (touchSize / 2),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onScaleStart: (details) {
          _isRotating = true;
          _initialRotation = clip.rotation;
          
          final RenderBox? box = _canvasKey.currentContext?.findRenderObject() as RenderBox?;
          if (box == null) return;
          final localPoint = box.globalToLocal(details.focalPoint);
          
          final centerX = clip.x * constraints.maxWidth;
          final centerY = clip.y * constraints.maxHeight;
          
          _initialAngle = math.atan2(localPoint.dy - centerY, localPoint.dx - centerX);
        },
        onScaleUpdate: (details) {
          if (!_isRotating) return;
          
          final RenderBox? box = _canvasKey.currentContext?.findRenderObject() as RenderBox?;
          if (box == null) return;
          final localPoint = box.globalToLocal(details.focalPoint);
          
          final centerX = clip.x * constraints.maxWidth;
          final centerY = clip.y * constraints.maxHeight;
          
          final currentAngle = math.atan2(localPoint.dy - centerY, localPoint.dx - centerX);
          
          double angleDiff = (currentAngle - _initialAngle) * 180 / math.pi;
          provider.updateClip(clip.id, rotation: _initialRotation - angleDiff, silent: true);
          setState(() {});
        },
        onScaleEnd: (_) {
          _isRotating = false;
          provider.syncToNative();
          provider.notifyListeners();
        },
        child: Container(
          width: touchSize,
          height: touchSize,
          color: Colors.transparent, // Invisible touch target
          alignment: Alignment.center,
          child: Container(
            width: handleSize,
            height: handleSize,
            decoration: BoxDecoration(
              color: Colors.blueAccent,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 4 * scaleFactor,
                  offset: Offset(0, 2 * scaleFactor),
                ),
              ],
            ),
            child: Icon(
              Icons.rotate_right,
              size: 16 * scaleFactor,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHandle(double x, double y, int index, double boxSize, EditorProvider provider, BoxConstraints constraints, TimelineClip clip, Color selectionColor) {
    final double scaleFactor = math.min(1.0, math.max(0.3, boxSize / 150.0)) / provider.previewZoom;
    final double handleSize = 14.0 * scaleFactor;
    final double touchSize = math.max(24.0 / provider.previewZoom, handleSize * 1.5);
    
    return Positioned(
      left: x - (touchSize / 2),
      top: y - (touchSize / 2),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onScaleStart: (details) {
          _isScaling = true;
          _initialScale = clip.scale;
          
          final RenderBox? box = _canvasKey.currentContext?.findRenderObject() as RenderBox?;
          if (box == null) return;
          final localPoint = box.globalToLocal(details.focalPoint);
          
          final centerX = clip.x * constraints.maxWidth;
          final centerY = clip.y * constraints.maxHeight;
          
          _initialDistance = math.sqrt(
            math.pow(localPoint.dx - centerX, 2) + math.pow(localPoint.dy - centerY, 2)
          );
        },
        onScaleUpdate: (details) {
          if (!_isScaling) return;
          
          final RenderBox? box = _canvasKey.currentContext?.findRenderObject() as RenderBox?;
          if (box == null) return;
          final localPoint = box.globalToLocal(details.focalPoint);
          
          final centerX = clip.x * constraints.maxWidth;
          final centerY = clip.y * constraints.maxHeight;
          
          final currentDistance = math.sqrt(
            math.pow(localPoint.dx - centerX, 2) + math.pow(localPoint.dy - centerY, 2)
          );
          
          if (_initialDistance > 0) {
            double newScale = _initialScale * (currentDistance / _initialDistance);
            provider.updateClip(clip.id, scale: newScale.clamp(0.1, 10.0), silent: true);
            setState(() {});
          }
        },
        onScaleEnd: (_) {
          _isScaling = false;
          provider.syncToNative();
          provider.notifyListeners();
        },
        child: Container(
          width: touchSize,
          height: touchSize,
          color: Colors.transparent, // Invisible touch target
          alignment: Alignment.center,
          child: Container(
            width: handleSize,
            height: handleSize,
            decoration: BoxDecoration(
              color: selectionColor,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.blueAccent, width: math.max(0.5, 2.0 * scaleFactor)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 4 * scaleFactor,
                  offset: Offset(0, 2 * scaleFactor),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Size _getClipSize(TimelineClip clip, BoxConstraints constraints) {
    double baseWidth = 0.4 * constraints.maxWidth;
    double baseHeight = 0.2 * constraints.maxHeight;

    if (clip is SubtitleClip) {
      final textPainter = TextPainter(
        text: TextSpan(
          text: clip.text,
          style: TextStyle(
            fontSize: clip.fontSize * (constraints.maxHeight / 1080),
            fontFamily: clip.fontFamily,
            letterSpacing: clip.letterSpacing,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      
      final lineMetrics = textPainter.computeLineMetrics();
      double tightTextHeight;
      if (lineMetrics.isNotEmpty) {
        final lm = lineMetrics.first;
        // lm.ascent + lm.descent gives full typographic height including invisible accent/tail padding.
        // We multiply by 0.75 to strip this invisible padding and hug the actual letter ink.
        tightTextHeight = (lm.ascent + lm.descent) * 0.75;
      } else {
        tightTextHeight = textPainter.height * 0.75;
      }

      double extraPadding = 0.0;
      if (clip.isStrokeEnabled) extraPadding += clip.strokeWidth;
      if (clip.isShadowEnabled) {
        extraPadding += clip.shadowBlur + math.max(clip.shadowOffsetX.abs(), clip.shadowOffsetY.abs());
      } else if (clip.isGlowEnabled) {
        extraPadding += clip.glowSize;
      }
      
      baseWidth = textPainter.width + extraPadding;
      baseHeight = tightTextHeight + extraPadding;
    } else if (clip is OverlayClip) {
      if (_imageDimensions.containsKey(clip.imagePath)) {
        final imgSize = _imageDimensions[clip.imagePath]!;
        // Use a base width and scale height by aspect ratio
        baseWidth = 0.3 * constraints.maxWidth;
        baseHeight = baseWidth * (imgSize.height / imgSize.width);
      } else {
        // Trigger dimension fetch and use fallback
        _fetchImageDimensions(clip.imagePath);
        baseWidth = 0.3 * constraints.maxWidth;
        baseHeight = 0.3 * constraints.maxWidth;
      }
    }

    return Size(baseWidth * clip.scale, baseHeight * clip.scale);
  }

  Future<void> _fetchImageDimensions(String path) async {
    if (_imageDimensions.containsKey(path)) return;
    
    try {
      final Completer<ui.Image> completer = Completer();
      final ImageProvider provider = FileImage(File(path));
      final ImageStream stream = provider.resolve(ImageConfiguration.empty);
      
      late ImageStreamListener listener;
      listener = ImageStreamListener((ImageInfo info, bool synchronousCall) {
        completer.complete(info.image);
        stream.removeListener(listener);
      }, onError: (dynamic exception, StackTrace? stackTrace) {
        completer.completeError(exception);
        stream.removeListener(listener);
      });
      
      stream.addListener(listener);
      final ui.Image image = await completer.future;
      
      if (mounted) {
        setState(() {
          _imageDimensions[path] = ui.Size(image.width.toDouble(), image.height.toDouble());
        });
      }
    } catch (e) {
      debugPrint("Error fetching image dimensions: $e");
      // Put a dummy size to avoid repeated attempts
      _imageDimensions[path] = const ui.Size(100, 100);
    }
  }

  Widget _buildSelectionBox(TimelineClip clip, BoxConstraints constraints) {
    final size = _getClipSize(clip, constraints);
    final boxWidth = size.width;
    final boxHeight = size.height;

    return Positioned(
      left: (clip.x * constraints.maxWidth) - (boxWidth / 2),
      top: (clip.y * constraints.maxHeight) - (boxHeight / 2),
      width: boxWidth,
      height: boxHeight,
      child: IgnorePointer(
        child: Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.white38, width: 0.8),
          ),
        ),
      ),
    );
  }
}
