import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;
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

  void _handleScaleStart(ScaleStartDetails details, BoxConstraints constraints) {
    final provider = context.read<EditorProvider>();
    
    _allowInteraction = false;
    _isWorkspaceNavigating = false;

    // Multi-touch: Workspace zoom/pan
    if (details.pointerCount >= 2) {
      _isWorkspaceNavigating = true;
      _basePreviewZoom = _previewZoom;
      _basePreviewOffset = _previewOffset;
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
    _allowInteraction = false;
  }

  void _handleScaleUpdate(BuildContext context, ScaleUpdateDetails details, BoxConstraints constraints) {
    final provider = context.read<EditorProvider>();

    if (_isWorkspaceNavigating) {
      setState(() {
        _previewZoom = (_basePreviewZoom * details.scale).clamp(1.0, 5.0);
        if (_previewZoom > 1.0) {
          _previewOffset = _basePreviewOffset + details.focalPointDelta;
        } else {
          _previewOffset = Offset.zero;
        }
      });
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
                    ..translate(_previewOffset.dx, _previewOffset.dy)
                    ..scale(_previewZoom),
                  alignment: Alignment.center,
                  child: AspectRatio(
                    key: ValueKey('preview_${provider.aspectRatio}'),
                    aspectRatio: provider.aspectRatio,
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                      final dpr = MediaQuery.of(context).devicePixelRatio;
                      // Sync actual dimensions to native only when they change
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        final width = (constraints.maxWidth * dpr).toInt();
                        final height = (constraints.maxHeight * dpr).toInt();
                        if (width != provider.lastRenderWidth || height != provider.lastRenderHeight) {
                          provider.updateProjectSync(width: width, height: height);
                        }
                      });

                      return Container(
                          color: Color(provider.backgroundColor), // Actual video background
                          child: Stack(
                            children: [
                              GestureDetector(
                                behavior: HitTestBehavior.opaque,
                                onScaleStart: (details) => _handleScaleStart(details, constraints),
                                onScaleUpdate: (details) => _handleScaleUpdate(context, details, constraints),
                                onScaleEnd: (_) => _handleScaleEnd(),
                                onTapUp: (details) {
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

    if (visibleSelected.isEmpty) return const SizedBox.shrink();

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

    return Positioned(
      left: minX,
      top: minY,
      width: maxX - minX,
      height: maxY - minY,
      child: IgnorePointer(
        child: Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.white38, width: 0.8),
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
            fontSize: clip.fontSize * (constraints.maxHeight / 720),
            fontFamily: clip.fontFamily,
            fontWeight: FontWeight.bold,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      
      baseWidth = textPainter.width + 30;
      baseHeight = textPainter.height + 20;
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
