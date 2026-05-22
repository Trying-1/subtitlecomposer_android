import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../../../providers/editor_provider.dart';
import '../../../providers/asset_provider.dart';
import 'common/common_controls.dart';

class BackgroundTab extends StatefulWidget {
  const BackgroundTab({super.key});

  @override
  State<BackgroundTab> createState() => _BackgroundTabState();
}

class _BackgroundTabState extends State<BackgroundTab> {
  int _activeTab = 0; // 0: Solid, 1: Control, 2: Assets

  @override
  void initState() {
    super.initState();
    // Auto-switch to Control if a background clip is selected
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<EditorProvider>();
      if (provider.selectedBackground != null) {
        setState(() => _activeTab = 1);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<EditorProvider>();
    final assetProvider = context.watch<AssetProvider>();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Top Tab Selector
        Container(
          height: 32,
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.03),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Expanded(child: _buildMainTab(0, 'SOLID')),
              Expanded(child: _buildMainTab(1, 'CONTROL', enabled: provider.selectedBackground != null)),
              Expanded(child: _buildMainTab(2, 'ASSETS')),
            ],
          ),
        ),

        if (_activeTab == 0)
          _buildSolidView(provider)
        else if (_activeTab == 1)
          _buildControlView(provider)
        else
          _buildAssetsView(context, provider, assetProvider),
      ],
    );
  }

  Widget _buildMainTab(int index, String label, {bool enabled = true}) {
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

  Widget _buildSolidView(EditorProvider provider) {
    return Stack(
      children: [
        CommonControls.buildProjectColorPicker(context, 'Solid Color', provider.backgroundColor, (c) => provider.setBackgroundColor(c)),
        if (provider.selectedBackground != null)
          Positioned(
            right: 0,
            top: 0,
            child: IconButton(
              onPressed: () => provider.selectClip(null),
              icon: const Icon(Icons.deselect_rounded, size: 18, color: Colors.orangeAccent),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          ),
      ],
    );
  }

  Widget _buildControlView(EditorProvider provider) {
    if (provider.selectedBackground == null) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32.0),
          child: Text("Select a background clip to transform", style: TextStyle(color: Colors.white24, fontSize: 11)),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (provider.backgroundImagePath != null)
          Container(
            padding: const EdgeInsets.all(8),
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.white10),
            ),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: Image.file(
                    File(provider.backgroundImagePath!),
                    width: 40,
                    height: 40,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(width: 40, height: 40, color: Colors.white10, child: const Icon(Icons.image_not_supported, size: 16)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    provider.backgroundImagePath!.split('/').last,
                    style: const TextStyle(fontSize: 10, color: Colors.white70),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                IconButton(
                  onPressed: () => provider.selectClip(null),
                  icon: const Icon(Icons.deselect_rounded, size: 18, color: Colors.orangeAccent),
                ),
              ],
            ),
          ),
        if (provider.selectedBackground != null && provider.selectedBackground!.imagePath != null && provider.selectedBackground!.assetWidth > 0)
          Padding(
            padding: const EdgeInsets.only(top: 8, bottom: 16),
            child: Row(
              children: [
                const Icon(Icons.photo_size_select_actual_rounded, size: 14, color: Colors.greenAccent),
                const SizedBox(width: 8),
                Text(
                  'RESOLUTION: ${provider.selectedBackground!.assetWidth} x ${provider.selectedBackground!.assetHeight}',
                  style: const TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    color: Colors.white60,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
        const Text('DURATION', style: TextStyle(fontSize: 8, color: Colors.deepPurpleAccent, fontWeight: FontWeight.w900, letterSpacing: 1.0)),
        const SizedBox(height: 12),
        Row(
          children: [
            _buildDurationItem('Start', provider.selectedBackground!.startTime),
            const SizedBox(width: 24),
            _buildDurationItem('End', provider.selectedBackground!.endTime),
            const SizedBox(width: 24),
            _buildDurationItem('Total', provider.selectedBackground!.endTime - provider.selectedBackground!.startTime, isTotal: true),
          ],
        ),
        const SizedBox(height: 16),
        InkWell(
          onTap: () {
            provider.extendSelectedBackgroundToFullDuration();
          },
          borderRadius: BorderRadius.circular(8),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
            decoration: BoxDecoration(
              color: Colors.deepPurpleAccent.withOpacity(0.08),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.deepPurpleAccent.withOpacity(0.2)),
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.fullscreen_rounded, size: 16, color: Colors.deepPurpleAccent),
                SizedBox(width: 8),
                Text(
                  'EXTEND TO FULL DURATION',
                  style: TextStyle(
                    fontFamily: 'KleeOne',
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),
        const Text('TRANSFORMATIONS', style: TextStyle(fontSize: 8, color: Colors.deepPurpleAccent, fontWeight: FontWeight.w900, letterSpacing: 1.0)),
        const SizedBox(height: 16),
        CommonControls.buildFillModeSelector(
          provider.backgroundFillMode,
          (mode) => provider.setBackgroundFillMode(mode),
        ),
        const SizedBox(height: 16),
        CommonControls.buildDialScrubber(context, 'Scale', provider.backgroundScale, 0.1, 5.0, (v) => provider.setBackgroundScale(v)),
        const SizedBox(height: 12),
        CommonControls.buildDialScrubber(context, 'Rotation', provider.backgroundRotation, -180, 180, (v) => provider.setBackgroundRotation(v)),
        const SizedBox(height: 8),
        CommonControls.buildQuickRotationControls(provider.backgroundRotation, (v) => provider.setBackgroundRotation(v)),
        const SizedBox(height: 12),
        CommonControls.buildDialScrubber(context, 'Horizontal (X)', provider.backgroundX, -2.0, 2.0, (v) => provider.setBackgroundX(v), onReset: () => provider.setBackgroundX(0.0)),
        const SizedBox(height: 12),
        CommonControls.buildDialScrubber(context, 'Vertical (Y)', provider.backgroundY, -2.0, 2.0, (v) => provider.setBackgroundY(v), onReset: () => provider.setBackgroundY(0.0)),
        const SizedBox(height: 24),
        const Text('IMAGE ADJUSTMENTS', style: TextStyle(fontSize: 8, color: Colors.deepPurpleAccent, fontWeight: FontWeight.w900, letterSpacing: 1.0)),
        const SizedBox(height: 16),
        CommonControls.buildDialScrubber(context, 'Brightness', provider.backgroundBrightness, 0.0, 3.0, (v) => provider.setBackgroundBrightness(v), onReset: () => provider.setBackgroundBrightness(1.0)),
        const SizedBox(height: 12),
        CommonControls.buildDialScrubber(context, 'Saturation', provider.backgroundSaturation, 0.0, 3.0, (v) => provider.setBackgroundSaturation(v), onReset: () => provider.setBackgroundSaturation(1.0)),
        const SizedBox(height: 12),
        CommonControls.buildDialScrubber(context, 'Contrast', provider.backgroundContrast, 0.0, 3.0, (v) => provider.setBackgroundContrast(v), onReset: () => provider.setBackgroundContrast(1.0)),
        const SizedBox(height: 12),
        CommonControls.buildDialScrubber(context, 'Blur', provider.backgroundBlur, 0.0, 25.0, (v) => provider.setBackgroundBlur(v), onReset: () => provider.setBackgroundBlur(0.0)),
      ],
    );
  }

  Widget _buildAssetsView(BuildContext context, EditorProvider provider, AssetProvider assetProvider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('MY BACKGROUNDS', style: TextStyle(fontSize: 8, color: Colors.deepPurpleAccent, fontWeight: FontWeight.w900, letterSpacing: 1.0)),
            IconButton(
              onPressed: () => _showImagePickerBottomSheet(context, provider),
              icon: const Icon(Icons.add_circle_outline_rounded, color: Colors.greenAccent, size: 18),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (assetProvider.backgroundAssets.isEmpty)
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Column(
                children: [
                  Icon(Icons.wallpaper_rounded, color: Colors.white.withOpacity(0.05), size: 48),
                  const SizedBox(height: 12),
                  const Text('No backgrounds imported', style: TextStyle(color: Colors.white24, fontSize: 11)),
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
            itemCount: assetProvider.backgroundAssets.length,
            itemBuilder: (context, index) {
              final path = assetProvider.backgroundAssets[index];
              final isVideo = path.toLowerCase().endsWith('.mp4') || 
                              path.toLowerCase().endsWith('.mov') || 
                              path.toLowerCase().endsWith('.mkv') ||
                              path.toLowerCase().endsWith('.webm');

              return Stack(
                children: [
                  InkWell(
                    onTap: () {
                      provider.setBackgroundImage(path);
                      setState(() => _activeTab = 1);
                    },
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.white.withOpacity(0.1)),
                        image: !isVideo ? DecorationImage(
                          image: FileImage(File(path)),
                          fit: BoxFit.cover,
                        ) : null,
                        color: isVideo ? Colors.black26 : null,
                      ),
                      child: isVideo ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.play_circle_filled_rounded, color: Colors.white.withOpacity(0.5), size: 24),
                            const SizedBox(height: 2),
                            const Text('VIDEO', style: TextStyle(fontSize: 6, color: Colors.white38, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ) : null,
                    ),
                  ),
                  Positioned(
                    top: 2,
                    right: 2,
                    child: InkWell(
                      onTap: () => assetProvider.removeBackgroundAsset(path),
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

  void _showImagePickerBottomSheet(BuildContext context, EditorProvider provider) {
    final assetProvider = Provider.of<AssetProvider>(context, listen: false);
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Color(0xFF1A1A23),
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),
            _buildPickerOption(
              icon: Icons.photo_library_rounded,
              label: 'Gallery (Photos)',
              subtitle: 'Pick images or GIFs from storage',
              onTap: () async {
                Navigator.pop(context);
                final picker = ImagePicker();
                final List<XFile> images = await picker.pickMultiImage();
                if (images.isNotEmpty) {
                  assetProvider.addBackgroundAssets(images.map((e) => e.path).toList());
                  provider.setBackgroundImage(images.first.path);
                  setState(() => _activeTab = 1);
                }
              },
            ),
            _buildPickerOption(
              icon: Icons.video_collection_rounded,
              label: 'Gallery (Videos)',
              subtitle: 'Pick video files from storage',
              onTap: () async {
                Navigator.pop(context);
                final picker = ImagePicker();
                final XFile? video = await picker.pickVideo(source: ImageSource.gallery);
                if (video != null) {
                  assetProvider.addBackgroundAssets([video.path]);
                  provider.setBackgroundImage(video.path);
                  setState(() => _activeTab = 1);
                }
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

  Widget _buildDurationItem(String label, Duration duration, {bool isTotal = false}) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    final ms = duration.inMilliseconds % 1000;
    
    final formatted = '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}.${ms.toString().padLeft(3, '0')}';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label.toUpperCase(), style: const TextStyle(fontSize: 7, color: Colors.white38, letterSpacing: 0.5)),
        const SizedBox(height: 4),
        Text(
          formatted,
          style: TextStyle(
            fontSize: 11, 
            color: isTotal ? Colors.cyanAccent : Colors.white70, 
            fontFamily: 'monospace',
            fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ],
    );
  }
}
