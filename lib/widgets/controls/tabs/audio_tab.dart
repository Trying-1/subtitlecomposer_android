import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../../models/editor_models.dart';
import '../../../providers/editor_provider.dart';
import '../../../providers/asset_provider.dart';
import 'common/common_controls.dart';

class AudioTab extends StatefulWidget {
  final AudioClip? selectedAudio;
  final Function(String path) onAddAudio;
  final Function({
    double? volume,
  }) onUpdate;

  const AudioTab({
    super.key,
    this.selectedAudio,
    required this.onAddAudio,
    required this.onUpdate,
  });

  @override
  State<AudioTab> createState() => _AudioTabState();
}

class _AudioTabState extends State<AudioTab> {
  int _activeTab = 0; // 0: Control, 1: Assets

  @override
  void initState() {
    super.initState();
    if (widget.selectedAudio == null) {
      _activeTab = 1;
    }
  }

  @override
  void didUpdateWidget(AudioTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selectedAudio != null && oldWidget.selectedAudio == null) {
      _activeTab = 0;
    }
  }

  void _pickAudioFiles(BuildContext context) async {
    try {
      final result = await FilePicker.pickFiles(type: FileType.audio, allowMultiple: true);
      
      if (result != null && result.files.isNotEmpty) {
        final paths = result.files.map((f) => f.path).whereType<String>().toList();
        if (paths.isNotEmpty && context.mounted) {
          context.read<AssetProvider>().addAudioAssets(paths);
        }
      }
    } catch (e) {
      print("Error picking audio files: $e");
    }
  }

  Widget _buildAssetsView(BuildContext context, AssetProvider assetProvider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('AUDIO LIBRARY', style: TextStyle(fontSize: 8, color: Colors.cyanAccent, fontWeight: FontWeight.w900, letterSpacing: 1.0)),
            IconButton(
              onPressed: () => _showPickerOptions(context),
              icon: const Icon(Icons.add_circle_outline_rounded, color: Colors.cyanAccent, size: 18),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (assetProvider.audioAssets.isEmpty)
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Column(
                children: [
                  Icon(Icons.audiotrack_rounded, color: Colors.white.withOpacity(0.05), size: 48),
                  const SizedBox(height: 12),
                  const Text('No audio files imported', style: TextStyle(color: Colors.white24, fontSize: 11)),
                ],
              ),
            ),
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: assetProvider.audioAssets.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final path = assetProvider.audioAssets[index];
              final fileName = path.split('/').last;
              
              return InkWell(
                onTap: () => widget.onAddAudio(path),
                onLongPress: () => _showRenameDialog(context, assetProvider, path),
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.03),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.white.withOpacity(0.05)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.cyanAccent.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.music_note_rounded, color: Colors.cyanAccent, size: 16),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          assetProvider.getAssetName(path),
                          style: const TextStyle(color: Colors.white70, fontSize: 12),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      IconButton(
                        onPressed: () => _showRenameDialog(context, assetProvider, path),
                        icon: const Icon(Icons.edit_outlined, color: Colors.white38, size: 14),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        onPressed: () => assetProvider.removeAudioAsset(path),
                        icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 16),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                ),
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
            focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.cyanAccent)),
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
            child: const Text('Rename', style: TextStyle(color: Colors.cyanAccent)),
          ),
        ],
      ),
    );
  }

  void _showPickerOptions(BuildContext parentContext) {
    showModalBottomSheet(
      context: parentContext,
      backgroundColor: Colors.transparent,
      builder: (modalContext) => Container(
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
            const Text('IMPORT AUDIO', style: TextStyle(fontSize: 10, color: Colors.cyanAccent, fontWeight: FontWeight.w900, letterSpacing: 1.2)),
            const SizedBox(height: 24),
            _buildPickerOption(
              icon: Icons.audiotrack_rounded,
              label: 'Audio File',
              subtitle: 'Import MP3, WAV, etc.',
              onTap: () {
                Navigator.pop(modalContext);
                _pickAudioFiles(parentContext);
              },
            ),
            const SizedBox(height: 12),
            _buildPickerOption(
              icon: Icons.video_library_rounded,
              label: 'Extract from Video',
              subtitle: 'Use audio from a video clip',
              onTap: () {
                Navigator.pop(modalContext);
                _pickFromVideo(parentContext);
              },
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Future<void> _pickFromVideo(BuildContext context) async {
    try {
      final picker = ImagePicker();
      final XFile? video = await picker.pickVideo(source: ImageSource.gallery);
      if (video != null && context.mounted) {
        context.read<AssetProvider>().addAudioAssets([video.path]);
      }
    } catch (e) {
      print("Error picking video for audio extraction: $e");
    }
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
                color: Colors.cyanAccent.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: Colors.cyanAccent, size: 20),
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
    print("AudioTab: Building with ${assetProvider.audioAssets.length} audio assets");

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
              Expanded(child: _buildSubTab(0, 'CONTROL', widget.selectedAudio != null)),
              Expanded(child: _buildSubTab(1, 'LIBRARY', true)),
            ],
          ),
        ),

        // Tab Content
        if (_activeTab == 0 && widget.selectedAudio != null)
           Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('AUDIO SETTINGS', style: TextStyle(fontSize: 8, color: Colors.cyanAccent, fontWeight: FontWeight.w900, letterSpacing: 1.0)),
              const SizedBox(height: 12),
              CommonControls.buildSlider(
                context,
                'Volume',
                widget.selectedAudio!.volume,
                0.0,
                2.0,
                (v) => widget.onUpdate(volume: v),
              ),
              const SizedBox(height: 16),
              const Text('INFO', style: TextStyle(fontSize: 8, color: Colors.cyanAccent, fontWeight: FontWeight.w900, letterSpacing: 1.0)),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.03),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  children: [
                    _buildInfoRow('Name', widget.selectedAudio!.audioPath.split('/').last),
                    const SizedBox(height: 8),
                    _buildInfoRow('Duration', '${(widget.selectedAudio!.duration.inMilliseconds / 1000).toStringAsFixed(2)}s'),
                  ],
                ),
              ),
            ],
          )
        else
          _buildAssetsView(context, assetProvider),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: Colors.white38, fontSize: 11)),
        Flexible(
          child: Text(
            value, 
            style: const TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.bold),
            overflow: TextOverflow.ellipsis,
          ),
        ),
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
            border: active ? Border.all(color: Colors.cyanAccent.withOpacity(0.2)) : null,
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
}
