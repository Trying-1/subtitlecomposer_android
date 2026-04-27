import 'package:flutter/material.dart';
import 'common/common_controls.dart';

class ProjectTab extends StatelessWidget {
  final VoidCallback? onImportAudio;
  final VoidCallback? onImportSubtitles;
  final VoidCallback? onImportPlainText;
  final VoidCallback? onPasteSubtitles;
  final VoidCallback? onAddClip;
  final VoidCallback? onExtractAudio;
  final VoidCallback? onExport;
  final VoidCallback? onNewProject;

  const ProjectTab({
    super.key,
    this.onImportAudio,
    this.onImportSubtitles,
    this.onImportPlainText,
    this.onPasteSubtitles,
    this.onAddClip,
    this.onExtractAudio,
    this.onExport,
    this.onNewProject,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('PROJECT ACTIONS', style: TextStyle(fontSize: 8, color: Colors.deepPurpleAccent, fontWeight: FontWeight.w900, letterSpacing: 1.0)),
        const SizedBox(height: 16),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          child: Row(
            children: [
              CommonControls.buildSquareActionButton(
                icon: Icons.create_new_folder_rounded, 
                label: 'New', 
                onTap: onNewProject,
                color: Colors.redAccent.withOpacity(0.8),
              ),
              const SizedBox(width: 12),
              CommonControls.buildSquareActionButton(icon: Icons.audiotrack_rounded, label: 'Audio', onTap: onImportAudio),
              const SizedBox(width: 12),
              CommonControls.buildSquareActionButton(icon: Icons.video_library_rounded, label: 'Video', onTap: onExtractAudio, color: Colors.blueAccent),
              const SizedBox(width: 12),
              CommonControls.buildSquareActionButton(icon: Icons.subtitles_rounded, label: 'Subs', onTap: onImportSubtitles),
              const SizedBox(width: 12),
              CommonControls.buildSquareActionButton(icon: Icons.format_quote_rounded, label: 'Words', onTap: onImportPlainText),
              const SizedBox(width: 12),
              CommonControls.buildSquareActionButton(icon: Icons.paste_rounded, label: 'Paste', onTap: onPasteSubtitles),
              const SizedBox(width: 12),
              CommonControls.buildSquareActionButton(icon: Icons.add_comment_rounded, label: 'Text', onTap: onAddClip, color: Colors.greenAccent),
              const SizedBox(width: 12),
              CommonControls.buildSquareActionButton(
                icon: Icons.ios_share_rounded, 
                label: 'Export', 
                onTap: onExport, 
                color: Colors.deepPurpleAccent,
                isPrimary: true,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
