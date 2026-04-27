import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../../../providers/editor_provider.dart';
import 'common/common_controls.dart';

class BackgroundTab extends StatefulWidget {
  const BackgroundTab({super.key});

  @override
  State<BackgroundTab> createState() => _BackgroundTabState();
}

class _BackgroundTabState extends State<BackgroundTab> {
  int _bgSubTabIndex = 0;

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<EditorProvider>();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CommonControls.buildSubTabBar(
          ['SOLID', 'IMAGE'],
          _bgSubTabIndex,
          (idx) => setState(() => _bgSubTabIndex = idx),
        ),
        const SizedBox(height: 16),
        if (_bgSubTabIndex == 0)
          CommonControls.buildProjectColorPicker(context, 'Solid Color', provider.backgroundColor, (c) => provider.setBackgroundColor(c))
        else ...[
          if (provider.backgroundImagePath != null) ...[
            Container(
              padding: const EdgeInsets.all(8),
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
                    onPressed: () => provider.setBackgroundImage(null),
                    icon: const Icon(Icons.close_rounded, size: 18, color: Colors.redAccent),
                  ),
                ],
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
            CommonControls.buildSlider(context, 'Scale', provider.backgroundScale, 0.1, 5.0, (v) => provider.setBackgroundScale(v)),
            const SizedBox(height: 12),
            CommonControls.buildSlider(context, 'Rotation', provider.backgroundRotation, -180, 180, (v) => provider.setBackgroundRotation(v)),
            const SizedBox(height: 8),
            CommonControls.buildQuickRotationControls(provider.backgroundRotation, (v) => provider.setBackgroundRotation(v)),
            const SizedBox(height: 12),
            CommonControls.buildSlider(context, 'Horizontal (X)', provider.backgroundX, -2.0, 2.0, (v) => provider.setBackgroundX(v)),
            const SizedBox(height: 12),
            CommonControls.buildSlider(context, 'Vertical (Y)', provider.backgroundY, -2.0, 2.0, (v) => provider.setBackgroundY(v)),
          ] else
            CommonControls.buildSquareActionButton(
              icon: Icons.image_rounded,
              label: 'Pick Image',
              onTap: () => _showImagePickerBottomSheet(context, provider),
              color: Colors.deepPurpleAccent,
            ),
        ],
      ],
    );
  }

  void _showImagePickerBottomSheet(BuildContext context, EditorProvider provider) {
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
            const Text('CHOOSE BACKGROUND', style: TextStyle(fontSize: 10, color: Colors.deepPurpleAccent, fontWeight: FontWeight.w900, letterSpacing: 1.2)),
            const SizedBox(height: 24),
            _buildPickerOption(
              icon: Icons.photo_library_rounded,
              label: 'Gallery',
              subtitle: 'Choose from your photos',
              onTap: () async {
                Navigator.pop(context);
                final picker = ImagePicker();
                final image = await picker.pickImage(source: ImageSource.gallery);
                if (image != null) provider.setBackgroundImage(image.path);
              },
            ),
            const SizedBox(height: 12),
            _buildPickerOption(
              icon: Icons.camera_alt_rounded,
              label: 'Camera',
              subtitle: 'Capture a new background',
              onTap: () async {
                Navigator.pop(context);
                final picker = ImagePicker();
                final image = await picker.pickImage(source: ImageSource.camera);
                if (image != null) provider.setBackgroundImage(image.path);
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
}
