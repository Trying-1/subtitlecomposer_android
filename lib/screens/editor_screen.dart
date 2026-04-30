import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import '../providers/editor_provider.dart';
import '../widgets/preview/video_preview.dart';
import '../widgets/timeline/timeline_editor.dart';
import '../widgets/controls/bottom_control_panel.dart';
import '../services/audio_service.dart';
import '../models/editor_models.dart';
import '../providers/asset_provider.dart';
import 'package:path/path.dart' as p;

class EditorScreen extends StatefulWidget {
  const EditorScreen({super.key});

  @override
  State<EditorScreen> createState() => _EditorScreenState();
}

class _EditorScreenState extends State<EditorScreen> {
  final AudioService _audioService = AudioService();

  Future<void> _pickAudio(BuildContext context, EditorProvider provider) async {
    final result = await FilePicker.pickFiles(type: FileType.audio);
    if (result != null && context.mounted) {
      final path = result.files.single.path!;
      provider.loadAudio(path);
      context.read<AssetProvider>().addAudioAssets([path]);
    }
  }

  Future<void> _pickSubtitles(BuildContext context, EditorProvider provider) async {
    final result = await FilePicker.pickFiles();
    if (result != null && context.mounted) {
      final path = result.files.single.path!;
      final format = path.endsWith('.json') ? 'json' : 'ass';
      provider.loadSubtitles(path, format);
    }
  }

  Future<void> _pickPlainText(BuildContext context, EditorProvider provider) async {
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['txt'],
    );
    if (result != null && context.mounted) {
      provider.importPlainText(result.files.single.path!);
    }
  }

  Future<String?> _pickModelFile() async {
    final result = await FilePicker.pickFiles(
      type: FileType.any,
      // Note: whisper models are usually .bin
    );
    return result?.files.single.path;
  }

  Future<void> _extractAudioFromVideo(BuildContext context, EditorProvider provider) async {
    final audioPath = await _audioService.pickVideoAndExtractAudio();
    if (audioPath != null && context.mounted) {
      provider.loadAudio(audioPath);
      context.read<AssetProvider>().addAudioAssets([audioPath]);
    }
  }

  void _showPasteSubtitlesDialog(BuildContext context, EditorProvider provider) {
    final controller = TextEditingController();
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Dismiss',
      barrierColor: Colors.black87,
      transitionDuration: const Duration(milliseconds: 250),
      transitionBuilder: (context, anim1, anim2, child) {
        return SlideTransition(
          position: Tween<Offset>(begin: const Offset(0, -1), end: Offset.zero).animate(CurvedAnimation(parent: anim1, curve: Curves.easeOutCubic)),
          child: child,
        );
      },
      pageBuilder: (context, anim1, anim2) => Align(
        alignment: Alignment.topCenter,
        child: Material(
          color: Colors.transparent,
          child: Container(
            margin: EdgeInsets.only(top: MediaQuery.of(context).padding.top),
            decoration: const BoxDecoration(
              color: Color(0xFF111116),
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(16)),
              boxShadow: [BoxShadow(color: Colors.black54, blurRadius: 20)],
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text('Paste Subtitles', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  TextField(
                    controller: controller,
                    maxLines: 8,
                    autofocus: true,
                    style: const TextStyle(color: Colors.white, fontSize: 13),
                    decoration: InputDecoration(
                      hintText: 'Paste your paragraph here...',
                      hintStyle: TextStyle(color: Colors.white.withOpacity(0.2)),
                      filled: true,
                      fillColor: Colors.white.withOpacity(0.05),
                      contentPadding: const EdgeInsets.all(12),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('CANCEL', style: TextStyle(color: Colors.white38, fontSize: 11, fontWeight: FontWeight.bold)),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: ElevatedButton(
                          onPressed: () {
                            if (controller.text.trim().isNotEmpty) {
                              provider.generateSubtitlesFromText(controller.text.trim());
                            }
                            Navigator.pop(context);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.deepPurpleAccent,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            elevation: 0,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          child: const Text('GENERATE', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showTranscribeDialog(BuildContext context, EditorProvider provider) {
    if (provider.audioPath == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please import audio first')),
      );
      return;
    }

    final promptController = TextEditingController(text: "Transcribe exactly in Romanized Hindi (Hinglish). Use phonetic English characters. Example: 'Kaise ho aap?'");
    final languageController = TextEditingController(text: "hi");

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Voice to Text', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Using local Whisper.cpp model for word-level transcription.',
                style: TextStyle(color: Colors.white70, fontSize: 11),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: Colors.orangeAccent.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                child: const Text(
                  'TIP: For Romanized (Phonetic) Hindi, use a multilingual model, set language to "hi" or "auto", and use a Romanized initial prompt.',
                  style: TextStyle(color: Colors.orangeAccent, fontSize: 9, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: Colors.white.withOpacity(0.05), borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.white10)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('ACTIVE MODEL', style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
                        if (provider.whisperModelPath != null)
                           const Icon(Icons.check_circle, color: Colors.greenAccent, size: 14),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      provider.whisperModelPath != null ? p.basename(provider.whisperModelPath!) : "No model imported",
                      style: TextStyle(color: provider.whisperModelPath != null ? Colors.white : Colors.white24, fontSize: 13, fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () async {
                          final path = await _pickModelFile();
                          if (path != null) {
                            try {
                              await provider.importModel(path);
                            } catch (e) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Import failed: $e')));
                              }
                            }
                          }
                        },
                        icon: const Icon(Icons.file_download_outlined, size: 16),
                        label: const Text('IMPORT MODEL', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.orangeAccent,
                          side: const BorderSide(color: Colors.orangeAccent),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        promptController.text = "Transcribe strictly in Romanized Hindi (Hinglish) using phonetic English letters. NO DEVANAGARI. Example strings: 'Mera naam Trexx hai', 'Aap kaise hain?', 'Main aaj bahut khush hoon'. Only use English alphabet.";
                        languageController.text = "hi";
                      },
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.blueAccent),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: const Text('HINGLISH PRESET', style: TextStyle(color: Colors.blueAccent, fontSize: 10, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orangeAccent.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orangeAccent.withOpacity(0.2)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline, color: Colors.orangeAccent, size: 16),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        "TIP: To get clean Romanized text, use the Hinglish preset and a larger model (like 'small' or 'medium') if possible.",
                        style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 10),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: languageController,
                style: const TextStyle(color: Colors.white, fontSize: 13),
                decoration: InputDecoration(
                  labelText: 'Target Language (hi, en, auto)',
                  labelStyle: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 11),
                  filled: true,
                  fillColor: Colors.black26,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: promptController,
                style: const TextStyle(color: Colors.white, fontSize: 13),
                decoration: InputDecoration(
                  labelText: 'Initial Prompt (for Romanization)',
                  labelStyle: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 11),
                  filled: true,
                  fillColor: Colors.black26,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CANCEL', style: TextStyle(color: Colors.white38, fontSize: 11, fontWeight: FontWeight.bold)),
          ),
          ElevatedButton(
            onPressed: () async {
              final prompt = promptController.text.trim();
              final lang = languageController.text.trim();
              Navigator.pop(context);
              
              try {
                final segments = await provider.transcribeAudioRaw(prompt: prompt, language: lang);
                if (segments != null && context.mounted) {
                  _showReviewTranscriptionDialog(context, provider, segments);
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error: $e')),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orangeAccent,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('TRANSCRIBE', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _showReviewTranscriptionDialog(BuildContext context, EditorProvider provider, List<Map<String, dynamic>> segments, {bool isJson = false}) {
    final List<Map<String, dynamic>> editedSegments = List.from(segments.map((e) => Map<String, dynamic>.from(e)));
    final jsonController = TextEditingController(text: const JsonEncoder.withIndent('  ').convert(editedSegments));
    
    int? activeIndex;
    final editController = TextEditingController();

    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Dismiss',
      barrierColor: Colors.black87,
      transitionDuration: const Duration(milliseconds: 250),
      transitionBuilder: (context, anim1, anim2, child) {
        return SlideTransition(
          position: Tween<Offset>(begin: const Offset(0, -1), end: Offset.zero).animate(CurvedAnimation(parent: anim1, curve: Curves.easeOutCubic)),
          child: child,
        );
      },
      pageBuilder: (context, anim1, anim2) => Align(
        alignment: Alignment.topCenter,
        child: Material(
          color: Colors.transparent,
          child: Container(
            margin: EdgeInsets.only(top: MediaQuery.of(context).padding.top),
            decoration: const BoxDecoration(
              color: Color(0xFF111116),
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(16)),
              boxShadow: [BoxShadow(color: Colors.black54, blurRadius: 20)],
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(isJson ? 'JSON Editor' : 'Visual Editor', style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                    if (!isJson) ListenableBuilder(
                      listenable: provider,
                      builder: (context, _) => IconButton(
                        icon: Icon(provider.isPlaying ? Icons.pause_circle_filled : Icons.play_circle_filled, color: Colors.orangeAccent, size: 28),
                        onPressed: provider.togglePlay,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                SizedBox(
                  height: 300,
                  child: isJson ? TextField(
                    controller: jsonController,
                    maxLines: null,
                    expands: true,
                    style: const TextStyle(color: Colors.greenAccent, fontSize: 12, fontFamily: 'monospace'),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: Colors.white.withOpacity(0.05),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                    ),
                  ) : StatefulBuilder(
                    builder: (context, setModalState) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.05),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: SingleChildScrollView(
                                child: ListenableBuilder(
                                  listenable: provider,
                                  builder: (context, _) {
                                    final currentPosMs = provider.currentTime.inMilliseconds;
                                    return Wrap(
                                      spacing: 4,
                                      runSpacing: 4,
                                      children: List.generate(editedSegments.length, (index) {
                                        final segment = editedSegments[index];
                                        final isEditing = activeIndex == index;
                                        final isHighlighted = currentPosMs >= segment['start'] && currentPosMs < segment['end'];
                                        
                                        return InkWell(
                                          onTap: () {
                                            setModalState(() {
                                              activeIndex = index;
                                              editController.text = editedSegments[index]['text'];
                                              provider.seek(Duration(milliseconds: segment['start']));
                                            });
                                          },
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                            decoration: BoxDecoration(
                                              color: isEditing ? Colors.orangeAccent : (isHighlighted ? Colors.green.withValues(alpha: 0.3) : Colors.white10),
                                              borderRadius: BorderRadius.circular(4),
                                              border: Border.all(color: (isEditing ? Colors.orangeAccent : (isHighlighted ? Colors.green : Colors.transparent))),
                                            ),
                                            child: Text(
                                              segment['text'],
                                              style: TextStyle(
                                                color: isEditing ? Colors.black : Colors.white,
                                                fontSize: 13,
                                                fontWeight: (isEditing || isHighlighted) ? FontWeight.bold : FontWeight.normal,
                                              ),
                                            ),
                                          ),
                                        );
                                      }),
                                    );
                                  },
                                ),
                              ),
                            ),
                          ),
                          if (activeIndex != null) ...[
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                              decoration: BoxDecoration(color: Colors.white.withOpacity(0.05), borderRadius: BorderRadius.circular(8)),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: TextField(
                                      controller: editController,
                                      autofocus: true,
                                      style: const TextStyle(color: Colors.white, fontSize: 13),
                                      textInputAction: TextInputAction.next,
                                      decoration: InputDecoration(
                                        hintText: 'Edit word...',
                                        hintStyle: TextStyle(color: Colors.white.withOpacity(0.3)),
                                        border: InputBorder.none,
                                        isDense: true,
                                      ),
                                      onChanged: (val) {
                                        setModalState(() {
                                          editedSegments[activeIndex!]['text'] = val;
                                        });
                                      },
                                      onSubmitted: (val) {
                                        setModalState(() {
                                          editedSegments[activeIndex!]['text'] = val.trim();
                                          if (activeIndex! < editedSegments.length - 1) {
                                            activeIndex = activeIndex! + 1;
                                            editController.text = editedSegments[activeIndex!]['text'];
                                          } else {
                                            activeIndex = null;
                                            editController.clear();
                                          }
                                        });
                                      },
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 20),
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(),
                                    onPressed: () {
                                      setModalState(() {
                                        editedSegments.removeAt(activeIndex!);
                                        activeIndex = null;
                                        editController.clear();
                                      });
                                    },
                                  ),
                                  const SizedBox(width: 12),
                                  IconButton(
                                    icon: const Icon(Icons.arrow_forward_ios, color: Colors.orangeAccent, size: 16),
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(),
                                    onPressed: () {
                                      setModalState(() {
                                        editedSegments[activeIndex!]['text'] = editController.text.trim();
                                        if (activeIndex! < editedSegments.length - 1) {
                                          activeIndex = activeIndex! + 1;
                                          editController.text = editedSegments[activeIndex!]['text'];
                                        } else {
                                          activeIndex = null;
                                          editController.clear();
                                        }
                                      });
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ]
                        ],
                      );
                    }
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('DISCARD', style: TextStyle(color: Colors.white38, fontSize: 11, fontWeight: FontWeight.bold)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: ElevatedButton(
                        onPressed: () {
                          if (isJson) {
                            try {
                              final data = jsonDecode(jsonController.text);
                              final List<Map<String, dynamic>> newSegs = List<Map<String, dynamic>>.from(data);
                              provider.applyTranscriptionClips(newSegs);
                              Navigator.pop(context);
                            } catch(e) {
                              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Invalid JSON format: $e')));
                            }
                          } else {
                            if (activeIndex != null && editController.text.trim().isNotEmpty) {
                              editedSegments[activeIndex!]['text'] = editController.text.trim();
                            }
                            provider.applyTranscriptionClips(editedSegments);
                            Navigator.pop(context);
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orangeAccent,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        child: const Text('APPLY TO TIMELINE', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

  void _showAddTextDialog(BuildContext context, EditorProvider provider) {
    final controller = TextEditingController();
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Dismiss',
      barrierColor: Colors.black87,
      transitionDuration: const Duration(milliseconds: 250),
      transitionBuilder: (context, anim1, anim2, child) {
        return SlideTransition(
          position: Tween<Offset>(begin: const Offset(0, -1), end: Offset.zero).animate(CurvedAnimation(parent: anim1, curve: Curves.easeOutCubic)),
          child: child,
        );
      },
      pageBuilder: (context, anim1, anim2) => Align(
        alignment: Alignment.topCenter,
        child: Material(
          color: Colors.transparent,
          child: Container(
            margin: EdgeInsets.only(top: MediaQuery.of(context).padding.top),
            decoration: const BoxDecoration(
              color: Color(0xFF111116),
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(16)),
              boxShadow: [BoxShadow(color: Colors.black54, blurRadius: 20)],
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text('Add New Text', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  TextField(
                    controller: controller,
                    autofocus: true,
                    style: const TextStyle(color: Colors.white, fontSize: 13),
                    decoration: InputDecoration(
                      hintText: 'Enter text here...',
                      hintStyle: TextStyle(color: Colors.white.withOpacity(0.2)),
                      filled: true,
                      fillColor: Colors.white.withOpacity(0.05),
                      contentPadding: const EdgeInsets.all(12),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                    ),
                    onSubmitted: (val) {
                      if (val.trim().isNotEmpty) {
                        provider.addClip(val.trim());
                      }
                      Navigator.pop(context);
                    },
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('CANCEL', style: TextStyle(color: Colors.white38, fontSize: 11, fontWeight: FontWeight.bold)),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: ElevatedButton(
                          onPressed: () {
                            if (controller.text.trim().isNotEmpty) {
                              provider.addClip(controller.text.trim());
                            }
                            Navigator.pop(context);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.deepPurpleAccent,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            elevation: 0,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          child: const Text('ADD', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showForceAlignDialog(BuildContext context, EditorProvider provider) {
    final controller = TextEditingController();
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Dismiss',
      barrierColor: Colors.black87,
      transitionDuration: const Duration(milliseconds: 250),
      transitionBuilder: (context, anim1, anim2, child) {
        return SlideTransition(
          position: Tween<Offset>(begin: const Offset(0, -1), end: Offset.zero).animate(CurvedAnimation(parent: anim1, curve: Curves.easeOutCubic)),
          child: child,
        );
      },
      pageBuilder: (context, anim1, anim2) => Align(
        alignment: Alignment.topCenter,
        child: Material(
          color: Colors.transparent,
          child: Container(
            margin: EdgeInsets.only(top: MediaQuery.of(context).padding.top),
            decoration: const BoxDecoration(
              color: Color(0xFF111116),
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(16)),
              boxShadow: [BoxShadow(color: Colors.black54, blurRadius: 20)],
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text('Force Align Script', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  const Text('Paste your exact script below. Words will be matched to speech detected in audio.', style: TextStyle(color: Colors.white38, fontSize: 11)),
                  const SizedBox(height: 16),
                  TextField(
                    controller: controller,
                    maxLines: 8,
                    autofocus: true,
                    style: const TextStyle(color: Colors.amberAccent, fontSize: 13, fontFamily: 'monospace'),
                    decoration: InputDecoration(
                      hintText: 'Paste your script here...',
                      hintStyle: TextStyle(color: Colors.white.withOpacity(0.1)),
                      filled: true,
                      fillColor: Colors.white.withOpacity(0.05),
                      contentPadding: const EdgeInsets.all(12),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('CANCEL', style: TextStyle(color: Colors.white38, fontSize: 11, fontWeight: FontWeight.bold)),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: ElevatedButton.icon(
                          onPressed: () {
                            if (controller.text.trim().isNotEmpty) {
                              provider.forceAlignText(controller.text.trim());
                            }
                            Navigator.pop(context);
                          },
                          icon: const Icon(Icons.auto_fix_high_rounded, size: 16),
                          label: const Text('ALIGN SCRIPT', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.amberAccent,
                            foregroundColor: Colors.black,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            elevation: 0,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _handleImportAudioClip(BuildContext context, EditorProvider provider) async {
    final result = await FilePicker.pickFiles(type: FileType.audio);
    if (result != null && result.files.single.path != null && context.mounted) {
      final path = result.files.single.path!;
      await provider.addAudioClip(path);
      context.read<AssetProvider>().addAudioAssets([path]);
    }
  }

  Future<void> _handleExport(BuildContext context, EditorProvider provider) async {
    final path = await provider.exportVideo();
    if (path != null && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Video exported to gallery'),
          backgroundColor: Colors.deepPurpleAccent,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _handleNewProject(BuildContext context, EditorProvider provider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('New Project?', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
        content: const Text(
          'This will clear your current timeline and background settings. Your imported assets will be saved.',
          style: TextStyle(color: Colors.white60, fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CANCEL', style: TextStyle(color: Colors.white38, fontSize: 11, fontWeight: FontWeight.bold)),
          ),
          ElevatedButton(
            onPressed: () {
              provider.resetProject();
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent.withOpacity(0.8),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('RESET', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<EditorProvider>();

    return Scaffold(
      backgroundColor: const Color(0xFF0F0F13),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              flex: provider.isTimelineCollapsed ? 1 : 6,
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
                child: VideoPreview(),
              ),
            ),
            if (provider.isTimelineCollapsed)
                TimelineEditor(
                tracks: provider.tracks,
                overlayTracks: provider.overlayTracks,
                backgroundTracks: provider.backgroundTracks,
                audioTracks: provider.audioTracks,
                currentTime: provider.currentTime,
                playbackTime: provider.playbackTime,
                totalDuration: provider.totalDuration,
                isPlaying: provider.isPlaying,
                onTogglePlay: provider.togglePlay,
                isCollapsed: true,
                onToggleCollapse: provider.toggleTimelineCollapse,
                onSeek: (dur) => provider.seek(dur),
                selectedClipIds: provider.selectedClipIds,
                isMultiSelectMode: provider.isMultiSelectMode,
                onToggleMultiSelect: provider.toggleMultiSelectMode,
                isAllSelected: provider.isAllSelected,
                onToggleSelectAll: () => provider.toggleSelectAll(),
                zoomLevel: provider.zoomLevel,
                onSelect: (id) => provider.selectClip(id),
                onToggleSelect: (id) => provider.toggleClipSelection(id),
                onZoomChanged: (v) => provider.setZoomLevel(v),
                onMoveClip: (clip, trackId, startTime) => provider.moveClip(clip, trackId, startTime),
                onAddTrack: (type) => provider.addNewTrack(type),
                onUpdateClipTiming: (clip, start, end, resolve) => provider.updateClipTiming(clip, start, end, resolveCollisions: resolve),
                onResolveCollisions: (id) => provider.forceResolveCollisions(id),
                onStackSelected: () => provider.stackSelectedClips(),
                onResetSelected: () => provider.resetSelectedClips(),
                onSplit: () => provider.selectedClipIds.isNotEmpty ? provider.splitClip(provider.selectedClipIds.first) : null,
                onMerge: () => provider.mergeSelectedClips(),
                onSplitToWords: () => provider.splitSelectedClipToWords(),
                onDelete: () => provider.deleteSelectedClips(),
                onActionStart: () => provider.saveState(),
                onUndo: () => provider.undo(),
                onRedo: () => provider.redo(),
                canUndo: provider.canUndo,
                canRedo: provider.canRedo,
                onAddKeyframe: () => provider.addKeyframeAtCurrentTime(),
                onClearKeyframes: () => provider.clearKeyframes(),
                isKeyframeAtCurrentTime: provider.isKeyframeAtCurrentTime,
                showTextTracks: provider.showTextTracks,
                showOverlayTracks: provider.showOverlayTracks,
                showBackgroundTracks: provider.showBackgroundTracks,
                showAudioTracks: provider.showAudioTracks,
                onToggleTextTracks: provider.toggleTextTracks,
                onToggleOverlayTracks: provider.toggleOverlayTracks,
                onToggleBackgroundTracks: provider.toggleBackgroundTracks,
                onToggleAudioTracks: provider.toggleAudioTracks,
                markers: provider.markers,
                onAddMarker: () => provider.addMarker(),
                onClearMarkers: () => provider.clearMarkers(),
                isCollisionAdjustEnabled: provider.isCollisionAdjustEnabled,
                onToggleCollisionAdjust: provider.toggleCollisionAdjust,
                onAddText: () => _showAddTextDialog(context, provider),
              )
            else
              Expanded(
                flex: 3,
                child: TimelineEditor(
                  tracks: provider.tracks,
                  overlayTracks: provider.overlayTracks,
                  backgroundTracks: provider.backgroundTracks,
                  audioTracks: provider.audioTracks,
                  currentTime: provider.currentTime,
                  playbackTime: provider.playbackTime,
                  totalDuration: provider.totalDuration,
                  isPlaying: provider.isPlaying,
                  onTogglePlay: provider.togglePlay,
                  isCollapsed: false,
                  onToggleCollapse: provider.toggleTimelineCollapse,
                  onSeek: (dur) => provider.seek(dur),
                  selectedClipIds: provider.selectedClipIds,
                  isMultiSelectMode: provider.isMultiSelectMode,
                  onToggleMultiSelect: provider.toggleMultiSelectMode,
                  isAllSelected: provider.isAllSelected,
                  onToggleSelectAll: () => provider.toggleSelectAll(),
                  zoomLevel: provider.zoomLevel,
                  onSelect: (id) => provider.selectClip(id),
                  onToggleSelect: (id) => provider.toggleClipSelection(id),
                  onZoomChanged: (v) => provider.setZoomLevel(v),
                  onMoveClip: (clip, trackId, startTime) => provider.moveClip(clip, trackId, startTime),
                  onAddTrack: (type) => provider.addNewTrack(type),
                  onUpdateClipTiming: (clip, start, end, resolve) => provider.updateClipTiming(clip, start, end, resolveCollisions: resolve),
                  onResolveCollisions: (id) => provider.forceResolveCollisions(id),
                  onStackSelected: () => provider.stackSelectedClips(),
                  onResetSelected: () => provider.resetSelectedClips(),
                  onSplit: () => provider.selectedClipIds.isNotEmpty ? provider.splitClip(provider.selectedClipIds.first) : null,
                  onMerge: () => provider.mergeSelectedClips(),
                  onSplitToWords: () => provider.splitSelectedClipToWords(),
                  onDelete: () => provider.deleteSelectedClips(),
                  onActionStart: () => provider.saveState(),
                  onUndo: () => provider.undo(),
                  onRedo: () => provider.redo(),
                  canUndo: provider.canUndo,
                  canRedo: provider.canRedo,
                  onAddKeyframe: () => provider.addKeyframeAtCurrentTime(),
                  onClearKeyframes: () => provider.clearKeyframes(),
                  isKeyframeAtCurrentTime: provider.isKeyframeAtCurrentTime,
                  showTextTracks: provider.showTextTracks,
                  showOverlayTracks: provider.showOverlayTracks,
                  showBackgroundTracks: provider.showBackgroundTracks,
                  showAudioTracks: provider.showAudioTracks,
                  onToggleTextTracks: provider.toggleTextTracks,
                  onToggleOverlayTracks: provider.toggleOverlayTracks,
                  onToggleBackgroundTracks: provider.toggleBackgroundTracks,
                  onToggleAudioTracks: provider.toggleAudioTracks,
                  markers: provider.markers,
                  onAddMarker: () => provider.addMarker(),
                  onClearMarkers: () => provider.clearMarkers(),
                  isCollisionAdjustEnabled: provider.isCollisionAdjustEnabled,
                  onToggleCollisionAdjust: provider.toggleCollisionAdjust,
                  onAddText: () => _showAddTextDialog(context, provider),
                ),
              ),
            if (provider.isTimelineCollapsed)
              LinearProgressIndicator(
                value: provider.totalDuration.inMilliseconds > 0 
                    ? provider.currentTime.inMilliseconds / provider.totalDuration.inMilliseconds 
                    : 0.0,
                backgroundColor: Colors.white.withOpacity(0.05),
                color: Colors.deepPurpleAccent,
                minHeight: 2,
              ),
            if (provider.isExporting)
              const LinearProgressIndicator(color: Colors.deepPurpleAccent, backgroundColor: Colors.white10),
            const Divider(height: 1, color: Colors.white10),
            BottomControlPanel(
              clip: provider.selectedTimelineClip,
              selectedOverlay: provider.selectedOverlay,
              selectedAudio: provider.selectedAudio,
              selectedClipIds: provider.selectedClipIds,
              currentTime: provider.currentTime,
              onImportAudio: () => _pickAudio(context, provider),
              onExtractAudio: () => _extractAudioFromVideo(context, provider),
              onImportSubtitles: () => _pickSubtitles(context, provider),
              onImportPlainText: () => _pickPlainText(context, provider),
              onPasteSubtitles: () => _showPasteSubtitlesDialog(context, provider),
              onExport: () => _handleExport(context, provider),
              onAddClip: () => _showAddTextDialog(context, provider),
              onNewProject: () => _handleNewProject(context, provider),
              onTranscribe: () => _showTranscribeDialog(context, provider),
              onForceAlign: () => _showForceAlignDialog(context, provider),
              onAddMusic: () => _handleImportAudioClip(context, provider),
              onAddSFX: () => _handleImportAudioClip(context, provider),
              onBulkEditJson: () {
                if (provider.tracks.isEmpty || provider.tracks.every((t) => t.clips.isEmpty)) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No subtitles to edit yet!')));
                  return;
                }
                final List<Map<String, dynamic>> currentSegments = [];
                for (var t in provider.tracks) {
                  for (var c in t.clips) {
                    currentSegments.add({'start': c.startTime.inMilliseconds, 'end': c.endTime.inMilliseconds, 'text': c.text});
                  }
                }
                currentSegments.sort((a,b) => (a['start'] as int).compareTo(b['start'] as int));
                _showReviewTranscriptionDialog(context, provider, currentSegments, isJson: true);
              },
              onBulkEditText: () {
                if (provider.tracks.isEmpty || provider.tracks.every((t) => t.clips.isEmpty)) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No subtitles to edit yet!')));
                  return;
                }
                final List<Map<String, dynamic>> currentSegments = [];
                for (var t in provider.tracks) {
                  for (var c in t.clips) {
                    currentSegments.add({'start': c.startTime.inMilliseconds, 'end': c.endTime.inMilliseconds, 'text': c.text});
                  }
                }
                currentSegments.sort((a,b) => (a['start'] as int).compareTo(b['start'] as int));
                _showReviewTranscriptionDialog(context, provider, currentSegments, isJson: false);
              },
              onImportModel: () async {
                final path = await _pickModelFile();
                if (path != null) {
                  try {
                    await provider.importModel(path);
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Import failed: $e')));
                    }
                  }
                }
              },
              isModelReady: provider.whisperModelPath != null,
              isImportingModel: provider.isImportingModel,
              onAddOverlay: (path) => provider.addOverlay(path),
              onAddAudioClip: (path) => provider.addAudioClip(path),
              onUpdate: ({
                String? text,
                double? fontSize,
                double? x,
                double? y,
                double? letterSpacing,
                double? rotation,
                double? scale,
                double? opacity,
                bool? isShadowEnabled,
                bool? isBackgroundEnabled,
                bool? isStrokeEnabled,
                int? color,
                int? strokeColor,
                double? strokeWidth,
                int? shadowColor,
                double? shadowBlur,
                double? shadowOffsetX,
                double? shadowOffsetY,
                int? backgroundColor,
                double? backgroundRadius,
                String? fontFamily,
                ClipAnimation? entranceAnimation,
                ClipAnimation? exitAnimation,
                ClipAnimation? loopAnimation,
                double? textOpacity,
                List<Keyframe>? keyframes,
                TextCase? textCase,
                double? volume,
                CustomBlendMode? blendMode,
              }) {
                provider.updateClips(
                  provider.selectedClipIds,
                  text: text,
                  fontSize: fontSize,
                  x: x,
                  y: y,
                  color: color,
                  strokeColor: strokeColor,
                  strokeWidth: strokeWidth,
                  shadowColor: shadowColor,
                  shadowBlur: shadowBlur,
                  shadowOffsetX: shadowOffsetX,
                  shadowOffsetY: shadowOffsetY,
                  backgroundColor: backgroundColor,
                  backgroundRadius: backgroundRadius,
                  letterSpacing: letterSpacing,
                  rotation: rotation,
                  scale: scale,
                  opacity: opacity,
                  textOpacity: textOpacity,
                  isShadowEnabled: isShadowEnabled,
                  isBackgroundEnabled: isBackgroundEnabled,
                  isStrokeEnabled: isStrokeEnabled,
                  fontFamily: fontFamily,
                  entranceAnimation: entranceAnimation,
                  exitAnimation: exitAnimation,
                  loopAnimation: loopAnimation,
                  keyframes: keyframes,
                  textCase: textCase,
                  volume: volume,
                  blendMode: blendMode,
                );
              },
              onApplyPreset: (preset) {
                for (var id in provider.selectedClipIds) {
                  provider.applyPreset(id, preset);
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}
