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
  final VoidCallback? onTranscribe;
  final VoidCallback? onImportModel;
  final VoidCallback? onBulkEditJson;
  final VoidCallback? onBulkEditText;
  final VoidCallback? onForceAlign;
  final VoidCallback? onAddMusic;
  final VoidCallback? onAddSFX;
  final bool isModelReady;
  final bool isImporting;

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
    this.onTranscribe,
    this.onImportModel,
    this.onBulkEditJson,
    this.onBulkEditText,
    this.onForceAlign,
    this.onAddMusic,
    this.onAddSFX,
    this.isModelReady = false,
    this.isImporting = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('PROJECT ACTIONS', style: TextStyle(fontSize: 8, color: Colors.deepPurpleAccent, fontWeight: FontWeight.w900, letterSpacing: 1.0)),
        const SizedBox(height: 16),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            CommonControls.buildSquareActionButton(
              icon: Icons.create_new_folder_rounded, 
              label: 'New', 
              onTap: onNewProject,
              color: Colors.redAccent.withOpacity(0.8),
            ),
            CommonControls.buildSquareActionButton(icon: Icons.audiotrack_rounded, label: 'Audio', onTap: onImportAudio),
            CommonControls.buildSquareActionButton(icon: Icons.video_library_rounded, label: 'Video', onTap: onExtractAudio, color: Colors.blueAccent),
            CommonControls.buildSquareActionButton(icon: Icons.subtitles_rounded, label: 'Subs', onTap: onImportSubtitles),
            CommonControls.buildSquareActionButton(icon: Icons.format_quote_rounded, label: 'Words', onTap: onImportPlainText),
            CommonControls.buildSquareActionButton(icon: Icons.paste_rounded, label: 'Paste', onTap: onPasteSubtitles),
            CommonControls.buildSquareActionButton(icon: Icons.mic_rounded, label: 'Voice', onTap: onTranscribe, color: Colors.orangeAccent),
            CommonControls.buildSquareActionButton(icon: Icons.data_object_rounded, label: 'JSON Edit', onTap: onBulkEditJson, color: Colors.blueAccent),
            CommonControls.buildSquareActionButton(icon: Icons.text_snippet_rounded, label: 'Text Edit', onTap: onBulkEditText, color: Colors.indigoAccent),
            CommonControls.buildSquareActionButton(icon: Icons.auto_fix_high_rounded, label: 'Align', onTap: onForceAlign, color: Colors.amberAccent),
            CommonControls.buildSquareActionButton(icon: Icons.music_note_rounded, label: 'Music', onTap: onAddMusic, color: Colors.cyanAccent),
            CommonControls.buildSquareActionButton(icon: Icons.graphic_eq_rounded, label: 'SFX', onTap: onAddSFX, color: Colors.tealAccent),
            CommonControls.buildSquareActionButton(
              icon: isImporting ? null : (isModelReady ? Icons.check_circle_rounded : Icons.settings_input_component_rounded), 
              label: isImporting ? 'Loading...' : 'Model', 
              onTap: isImporting ? null : onImportModel, 
              color: isModelReady ? Colors.greenAccent : Colors.orangeAccent,
              child: isImporting ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.orangeAccent)) : null,
            ),
            CommonControls.buildSquareActionButton(icon: Icons.add_comment_rounded, label: 'Text', onTap: onAddClip, color: Colors.greenAccent),
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
