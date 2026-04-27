import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import '../../../models/editor_models.dart';
import '../../../providers/font_provider.dart';
import 'common/common_controls.dart';

class TextTab extends StatefulWidget {
  final SubtitleClip clip;
  final Function({String? text, String? fontFamily, double? fontSize, double? letterSpacing, TextCase? textCase}) onUpdate;

  const TextTab({
    super.key,
    required this.clip,
    required this.onUpdate,
  });

  @override
  State<TextTab> createState() => _TextTabState();
}

class _TextTabState extends State<TextTab> {
  int _activeSubTabIndex = 0;

  Future<void> _importFont(BuildContext context) async {
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['ttf', 'otf'],
    );
    if (result != null && context.mounted) {
      final path = result.files.single.path!;
      await context.read<FontProvider>().importFont(path);
    }
  }

  @override
  Widget build(BuildContext context) {
    final fontProvider = context.watch<FontProvider>();
    final customFontFamilies = fontProvider.customFonts.map((f) => f.family).toList();

    return Column(
      children: [
        CommonControls.buildSubTabBar(['CONTROLS', 'FONTS'], _activeSubTabIndex, (index) {
          setState(() => _activeSubTabIndex = index);
        }),
        const SizedBox(height: 16),
        if (_activeSubTabIndex == 0) _buildControls(customFontFamilies) else _buildFontLibrary(fontProvider),
      ],
    );
  }

  Widget _buildControls(List<String> customFonts) {
    return Column(
      children: [
        CommonControls.buildTextField(widget.clip.text, (v) => widget.onUpdate(text: v)),
        const SizedBox(height: 16),
        CommonControls.buildFontFamilyDropdown(
          widget.clip.fontFamily, 
          (v) => widget.onUpdate(fontFamily: v),
          customFonts: customFonts,
        ),
        const SizedBox(height: 16),
        _buildCasingRow(),
        const SizedBox(height: 16),
        CommonControls.buildSlider(context, 'Font Size', widget.clip.fontSize, 10, 200, (v) => widget.onUpdate(fontSize: v)),
        const SizedBox(height: 12),
        CommonControls.buildSlider(context, 'Letter Spacing', widget.clip.letterSpacing, -5, 40, (v) => widget.onUpdate(letterSpacing: v)),
      ],
    );
  }

  Widget _buildCasingRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        const Text('CASING', style: TextStyle(fontSize: 8, color: Colors.white38, fontWeight: FontWeight.w900, letterSpacing: 1.0)),
        const SizedBox(width: 12),
        _buildCasingButton('AA', () {
          widget.onUpdate(textCase: TextCase.upper);
        }),
        const SizedBox(width: 8),
        _buildCasingButton('aa', () {
          widget.onUpdate(textCase: TextCase.lower);
        }),
        const SizedBox(width: 8),
        _buildCasingButton('Aa', () {
          widget.onUpdate(textCase: TextCase.title);
        }),
      ],
    );
  }

  Widget _buildCasingButton(String label, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(4),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: Colors.white10),
        ),
        child: Text(
          label,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 10,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildFontLibrary(FontProvider fontProvider) {
    final customFonts = fontProvider.customFonts;
    
    // Default asset fonts from CommonControls
    final defaultFonts = [
      'Poppins', 'Bellota', 'BhuTukaExpandedOne', 'Bokor', 'BungeeHairline',
      'Caramel', 'Centralwell', 'Chalk Board', 'Eternal', 'Explora',
      'GrandifloraOne', 'KleeOne', 'Lacquer', 'LibreBarcode39Text',
      'LuckiestGuy', 'MajorMonoDisplay', 'Metrophobic', 'Michroma',
      'Milker', 'NCLNeovibes', 'NewRocker', 'NewTegomin', 'ProtestRevolution',
      'RELIGATH', 'akony', 'modernline', 'modernline bold'
    ];

    return Column(
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
              crossAxisCount: 2,
              childAspectRatio: 2.2,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
            ),
            itemCount: customFonts.length,
            itemBuilder: (context, index) {
              final font = customFonts[index];
              final isSelected = widget.clip.fontFamily == font.family;
              return GestureDetector(
                onTap: () => widget.onUpdate(fontFamily: font.family),
                onLongPress: () => _confirmDelete(font),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: isSelected ? Colors.deepPurpleAccent.withOpacity(0.1) : Colors.white.withOpacity(0.04),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: isSelected ? Colors.deepPurpleAccent : Colors.white10),
                  ),
                  child: Center(
                    child: Text(
                      font.family,
                      textAlign: TextAlign.center,
                      style: TextStyle(fontFamily: font.family, color: Colors.white70, fontSize: 11),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              );
            },
          ),
        const SizedBox(height: 20),
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
