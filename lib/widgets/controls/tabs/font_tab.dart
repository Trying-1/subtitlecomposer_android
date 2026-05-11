import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import '../../../models/editor_models.dart';
import '../../../providers/font_provider.dart';
import '../../../providers/editor_provider.dart';

class FontTab extends StatefulWidget {
  final SubtitleClip clip;
  final Function({String? fontFamily}) onUpdate;

  const FontTab({
    super.key,
    required this.clip,
    required this.onUpdate,
  });

  @override
  State<FontTab> createState() => _FontTabState();
}

class _FontTabState extends State<FontTab> {
  Future<void> _importFont(BuildContext context) async {
    final editorProvider = context.read<EditorProvider>();
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['ttf', 'otf'],
      initialDirectory: editorProvider.lastUsedDirectory,
    );
    if (result != null && context.mounted) {
      final path = result.files.single.path!;
      editorProvider.updateLastUsedDirectory(path);
      await context.read<FontProvider>().importFont(path);
    }
  }

  @override
  Widget build(BuildContext context) {
    final fontProvider = context.watch<FontProvider>();
    final customFonts = fontProvider.customFonts;
    
    final defaultFonts = [
      'Poppins', 'Bellota', 'BhuTukaExpandedOne', 'Bokor', 'BungeeHairline',
      'Caramel', 'Explora', 'GrandifloraOne', 'KleeOne', 'Lacquer', 
      'LibreBarcode39Text', 'LuckiestGuy', 'MajorMonoDisplay', 'Metrophobic', 
      'Michroma', 'NewRocker', 'NewTegomin', 'ProtestRevolution'
    ];

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('MY FONTS', style: TextStyle(fontSize: 8, color: Colors.deepPurpleAccent, fontWeight: FontWeight.w900, letterSpacing: 1.0)),
              IconButton(
                icon: const Icon(Icons.add_rounded, size: 18, color: Colors.deepPurpleAccent),
                onPressed: () => _importFont(context),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (customFonts.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: Colors.white.withOpacity(0.02), borderRadius: BorderRadius.circular(8)),
              child: const Text('No custom fonts imported', style: TextStyle(color: Colors.white24, fontSize: 10)),
            )
          else
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              childAspectRatio: 2.5,
              crossAxisSpacing: 6,
              mainAxisSpacing: 6,
            ),
            itemCount: customFonts.length,
            itemBuilder: (context, index) {
              final font = customFonts[index];
              final isSelected = widget.clip.fontFamily == font.family;
              return GestureDetector(
                onTap: () => widget.onUpdate(fontFamily: font.family),
                onLongPress: () => _confirmDelete(font),
                child: Container(
                  decoration: BoxDecoration(
                    color: isSelected ? Colors.deepPurpleAccent.withOpacity(0.2) : Colors.white.withOpacity(0.03),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: isSelected ? Colors.deepPurpleAccent.withOpacity(0.5) : Colors.transparent),
                  ),
                  child: Center(
                    child: Text(
                      font.family,
                      textAlign: TextAlign.center,
                      style: TextStyle(fontFamily: font.family, color: isSelected ? Colors.white : Colors.white38, fontSize: 9),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 24),
          const Text('PRESET FONTS', style: TextStyle(fontSize: 8, color: Colors.white38, fontWeight: FontWeight.w900, letterSpacing: 1.0)),
          const SizedBox(height: 12),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              childAspectRatio: 2.5,
              crossAxisSpacing: 6,
              mainAxisSpacing: 6,
            ),
            itemCount: defaultFonts.length,
            itemBuilder: (context, index) {
              final font = defaultFonts[index];
              final isSelected = widget.clip.fontFamily == font;
              return GestureDetector(
                onTap: () => widget.onUpdate(fontFamily: font),
                child: Container(
                  decoration: BoxDecoration(
                    color: isSelected ? Colors.deepPurpleAccent.withOpacity(0.2) : Colors.white.withOpacity(0.03),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: isSelected ? Colors.deepPurpleAccent.withOpacity(0.5) : Colors.transparent),
                  ),
                  child: Center(
                    child: Text(
                      font,
                      style: TextStyle(fontFamily: font, color: isSelected ? Colors.white : Colors.white38, fontSize: 9),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  void _confirmDelete(CustomFont font) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A24),
        title: Text('Delete ${font.family}?', style: const TextStyle(color: Colors.white, fontSize: 14)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('CANCEL')),
          TextButton(
            onPressed: () {
              context.read<FontProvider>().deleteFont(font);
              Navigator.pop(context);
            },
            child: const Text('DELETE', style: TextStyle(color: Colors.pinkAccent)),
          ),
        ],
      ),
    );
  }
}
