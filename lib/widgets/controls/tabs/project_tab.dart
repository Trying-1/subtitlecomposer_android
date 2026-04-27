import 'package:flutter/material.dart';
import 'common/common_controls.dart';

class ProjectTab extends StatelessWidget {
  final VoidCallback? onImportAudio;
  final VoidCallback? onImportSubtitles;
  final VoidCallback? onAddClip;
  final VoidCallback? onExport;
  final VoidCallback? onNewProject;

  const ProjectTab({
    super.key,
    this.onImportAudio,
    this.onImportSubtitles,
    this.onAddClip,
    this.onExport,
    this.onNewProject,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('PROJECT ACTIONS', style: TextStyle(fontSize: 8, color: Colors.deepPurpleAccent, fontWeight: FontWeight.w900, letterSpacing: 1.0)),
        const SizedBox(height: 20),
        Row(
          children: [
            CommonControls.buildSquareActionButton(
              icon: Icons.create_new_folder_rounded, 
              label: 'New', 
              onTap: onNewProject,
              color: Colors.redAccent.withOpacity(0.8),
            ),
            const SizedBox(width: 16),
            CommonControls.buildSquareActionButton(icon: Icons.audiotrack_rounded, label: 'Audio', onTap: onImportAudio),
            const SizedBox(width: 16),
            CommonControls.buildSquareActionButton(icon: Icons.subtitles_rounded, label: 'Subs', onTap: onImportSubtitles),
            const SizedBox(width: 16),
            CommonControls.buildSquareActionButton(icon: Icons.add_comment_rounded, label: 'Text', onTap: onAddClip, color: Colors.greenAccent),
            const SizedBox(width: 16),
            CommonControls.buildSquareActionButton(
              icon: Icons.ios_share_rounded, 
              label: 'Export', 
              onTap: onExport, 
              color: Colors.deepPurpleAccent,
              isPrimary: true,
            ),
          ],
        ),
      ],
    );
  }
}
