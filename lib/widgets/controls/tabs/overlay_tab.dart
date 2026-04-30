import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../../models/editor_models.dart';
import '../../../providers/editor_provider.dart';
import '../../../providers/asset_provider.dart';
import '../../../utils/animation_library.dart';
import 'common/common_controls.dart';

class OverlayTab extends StatefulWidget {
  final OverlayClip? selectedOverlay;
  final Function(String path) onAddOverlay;
  final Function({
    double? x,
    double? y,
    double? rotation,
    double? scale,
    double? opacity,
    ClipAnimation? entranceAnimation,
    ClipAnimation? exitAnimation,
    ClipAnimation? loopAnimation,
  }) onUpdate;

  const OverlayTab({
    super.key,
    this.selectedOverlay,
    required this.onAddOverlay,
    required this.onUpdate,
  });

  @override
  State<OverlayTab> createState() => _OverlayTabState();
}

class _OverlayTabState extends State<OverlayTab> {
  int _activeTab = 0; // 0: Control, 1: Assets

  @override
  void initState() {
    super.initState();
    // If no overlay is selected, default to Assets tab
    if (widget.selectedOverlay == null) {
      _activeTab = 1;
    }
  }

  @override
  void didUpdateWidget(OverlayTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Auto-switch to Control if an overlay was just selected
    if (widget.selectedOverlay != null && oldWidget.selectedOverlay == null) {
      _activeTab = 0;
    }
  }

  void _pickAssets(BuildContext context, ImageSource source, {bool isVideo = false}) async {
    final picker = ImagePicker();
    final assetProvider = context.read<AssetProvider>();
    
    if (isVideo) {
      final XFile? video = await picker.pickVideo(source: source);
      if (video != null) {
        assetProvider.addAssets([video.path]);
      }
      return;
    }

    if (source == ImageSource.gallery) {
      final List<XFile> images = await picker.pickMultiImage();
      if (images.isNotEmpty) {
        assetProvider.addAssets(images.map((i) => i.path).toList());
      }
    } else {
      final XFile? image = await picker.pickImage(source: source);
      if (image != null) {
        assetProvider.addAssets([image.path]);
      }
    }
  }

  Widget _buildAssetsView(BuildContext context, AssetProvider assetProvider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('MY ASSETS', style: TextStyle(fontSize: 8, color: Colors.deepPurpleAccent, fontWeight: FontWeight.w900, letterSpacing: 1.0)),
            IconButton(
              onPressed: () => _showPickerOptions(context),
              icon: const Icon(Icons.add_circle_outline_rounded, color: Colors.greenAccent, size: 18),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (assetProvider.assets.isEmpty)
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Column(
                children: [
                  Icon(Icons.photo_library_outlined, color: Colors.white.withOpacity(0.05), size: 48),
                  const SizedBox(height: 12),
                  const Text('No assets imported', style: TextStyle(color: Colors.white24, fontSize: 11)),
                ],
              ),
            ),
          )
        else
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
            ),
            itemCount: assetProvider.assets.length,
            itemBuilder: (context, index) {
              final path = assetProvider.assets[index];
              return Stack(
                children: [
                  InkWell(
                    onTap: () => widget.onAddOverlay(path),
                    onLongPress: () => _showRenameDialog(context, assetProvider, path),
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.white.withOpacity(0.1)),
                        image: path.toLowerCase().endsWith('.mp4') || path.toLowerCase().endsWith('.mov') || path.toLowerCase().endsWith('.mkv') || path.toLowerCase().endsWith('.webm')
                          ? null
                          : DecorationImage(
                              image: FileImage(File(path)),
                              fit: BoxFit.cover,
                            ),
                      ),
                      child: path.toLowerCase().endsWith('.mp4') || path.toLowerCase().endsWith('.mov') || path.toLowerCase().endsWith('.mkv') || path.toLowerCase().endsWith('.webm')
                        ? Center(child: Icon(Icons.videocam_rounded, color: Colors.deepPurpleAccent.withOpacity(0.5), size: 32))
                        : Stack(
                            children: [
                              Positioned(
                                bottom: 0, left: 0, right: 0,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.black54,
                                    borderRadius: const BorderRadius.vertical(bottom: Radius.circular(8)),
                                  ),
                                  child: Text(
                                    assetProvider.getAssetName(path),
                                    style: const TextStyle(color: Colors.white, fontSize: 8),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ),
                            ],
                          ),
                    ),
                  ),
                  Positioned(
                    top: 2,
                    right: 2,
                    child: InkWell(
                      onTap: () => assetProvider.removeAsset(path),
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: const BoxDecoration(
                          color: Colors.black54,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.close, color: Colors.redAccent, size: 10),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
      ],
    );
  }

  void _showRenameDialog(BuildContext context, AssetProvider assetProvider, String path) {
    final TextEditingController controller = TextEditingController(text: assetProvider.getAssetName(path));
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A23),
        title: const Text('Rename Asset', style: TextStyle(color: Colors.white, fontSize: 16)),
        content: TextField(
          controller: controller,
          autofocus: true,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            hintText: 'Enter new name',
            hintStyle: TextStyle(color: Colors.white24),
            enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white10)),
            focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.deepPurpleAccent)),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Colors.white38)),
          ),
          TextButton(
            onPressed: () {
              if (controller.text.trim().isNotEmpty) {
                assetProvider.renameAsset(path, controller.text.trim());
              }
              Navigator.pop(context);
            },
            child: const Text('Rename', style: TextStyle(color: Colors.deepPurpleAccent)),
          ),
        ],
      ),
    );
  }

  void _showPickerOptions(BuildContext context) {
     showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: const Color(0xFF14141E),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          border: Border.all(color: Colors.white.withOpacity(0.05)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('IMPORT ASSETS', style: TextStyle(fontSize: 10, color: Colors.deepPurpleAccent, fontWeight: FontWeight.w900, letterSpacing: 1.2)),
            const SizedBox(height: 24),
            _buildPickerOption(
              icon: Icons.photo_library_rounded,
              label: 'Gallery (Photos)',
              subtitle: 'Pick multiple images',
              onTap: () {
                Navigator.pop(context);
                _pickAssets(context, ImageSource.gallery);
              },
            ),
            const SizedBox(height: 12),
            _buildPickerOption(
              icon: Icons.video_library_rounded,
              label: 'Gallery (Videos)',
              subtitle: 'Pick video overlays',
              onTap: () {
                Navigator.pop(context);
                _pickAssets(context, ImageSource.gallery, isVideo: true);
              },
            ),
            const SizedBox(height: 12),
            _buildPickerOption(
              icon: Icons.camera_alt_rounded,
              label: 'Camera',
              subtitle: 'Capture new asset',
              onTap: () {
                Navigator.pop(context);
                _pickAssets(context, ImageSource.camera);
              },
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildPickerOption({
    required IconData icon,
    required String label,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.03),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withOpacity(0.05)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.deepPurpleAccent.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: Colors.deepPurpleAccent, size: 20),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 2),
                  Text(subtitle, style: const TextStyle(color: Colors.white38, fontSize: 11)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: Colors.white24, size: 20),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final assetProvider = context.watch<AssetProvider>();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Tab Header
        Container(
          height: 32,
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.03),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Expanded(child: _buildSubTab(0, 'CONTROL', widget.selectedOverlay != null)),
              Expanded(child: _buildSubTab(1, 'ASSETS', true)),
              Expanded(child: _buildSubTab(2, 'ANIMATIONS', widget.selectedOverlay != null)),
            ],
          ),
        ),

        // Tab Content
        if (_activeTab == 0 && widget.selectedOverlay != null)
           Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('OVERLAY TRANSFORM', style: TextStyle(fontSize: 8, color: Colors.deepPurpleAccent, fontWeight: FontWeight.w900, letterSpacing: 1.0)),
              const SizedBox(height: 12),
              CommonControls.buildSlider(
                context,
                'Scale',
                widget.selectedOverlay!.scale,
                0.1,
                5.0,
                (v) => widget.onUpdate(scale: v),
              ),
              CommonControls.buildSlider(
                context,
                'Opacity',
                widget.selectedOverlay!.opacity,
                0.0,
                1.0,
                (v) => widget.onUpdate(opacity: v),
              ),
              const SizedBox(height: 12),
              CommonControls.buildSlider(
                context,
                'Rotation',
                widget.selectedOverlay!.rotation,
                -180,
                180,
                (v) => widget.onUpdate(rotation: v),
              ),
              CommonControls.buildQuickRotationControls(
                widget.selectedOverlay!.rotation,
                (v) => widget.onUpdate(rotation: v),
              ),
              const SizedBox(height: 16),
              const Text('POSITION', style: TextStyle(fontSize: 8, color: Colors.deepPurpleAccent, fontWeight: FontWeight.w900, letterSpacing: 1.0)),
              const SizedBox(height: 12),
              CommonControls.buildSlider(
                context,
                'X Position',
                widget.selectedOverlay!.x,
                -0.5,
                1.5,
                (v) => widget.onUpdate(x: v),
              ),
              CommonControls.buildSlider(
                context,
                'Y Position',
                widget.selectedOverlay!.y,
                -0.5,
                1.5,
                (v) => widget.onUpdate(y: v),
              ),
            ],
          )
        else if (_activeTab == 2 && widget.selectedOverlay != null)
          _buildAnimationsView()
        else
          _buildAssetsView(context, assetProvider),
      ],
    );
  }

  Widget _buildSubTab(int index, String label, bool enabled) {
    final active = _activeTab == index;
    return GestureDetector(
      onTap: enabled ? () => setState(() => _activeTab = index) : null,
      child: Opacity(
        opacity: enabled ? 1.0 : 0.3,
        child: Container(
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: active ? Colors.white.withOpacity(0.05) : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            border: active ? Border.all(color: Colors.deepPurpleAccent.withOpacity(0.2)) : null,
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.bold,
              color: active ? Colors.white : Colors.white38,
              letterSpacing: 0.5,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAnimationsView() {
    final overlay = widget.selectedOverlay!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildAnimationCategory(
          'ENTRANCE',
          AnimationLibrary.entranceAnimations,
          overlay.entranceAnimation,
          (type) => widget.onUpdate(entranceAnimation: overlay.entranceAnimation.copyWith(type: type)),
        ),
        const SizedBox(height: 16),
        _buildAnimationCategory(
          'EXIT',
          AnimationLibrary.exitAnimations,
          overlay.exitAnimation,
          (type) => widget.onUpdate(exitAnimation: overlay.exitAnimation.copyWith(type: type)),
        ),
        const SizedBox(height: 16),
        _buildAnimationCategory(
          'LOOP',
          AnimationLibrary.loopAnimations,
          overlay.loopAnimation,
          (type) => widget.onUpdate(loopAnimation: overlay.loopAnimation.copyWith(type: type)),
        ),
      ],
    );
  }

  Widget _buildAnimationCategory(
    String title,
    List<AnimationMetadata> items,
    ClipAnimation current,
    Function(AnimationType) onSelected,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontSize: 8, color: Colors.deepPurpleAccent, fontWeight: FontWeight.w900, letterSpacing: 1.0)),
        const SizedBox(height: 10),
        SizedBox(
          height: 60,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: items.length,
            itemBuilder: (context, index) {
              final item = items[index];
              final active = current.type == item.type;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: InkWell(
                  onTap: () => onSelected(item.type),
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    width: 60,
                    decoration: BoxDecoration(
                      color: active ? Colors.deepPurpleAccent.withOpacity(0.1) : Colors.white.withOpacity(0.03),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: active ? Colors.deepPurpleAccent.withOpacity(0.4) : Colors.white.withOpacity(0.05)),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(item.icon, size: 16, color: active ? Colors.deepPurpleAccent : Colors.white38),
                        const SizedBox(height: 4),
                        Text(item.label, style: TextStyle(fontSize: 8, color: active ? Colors.white : Colors.white38, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
