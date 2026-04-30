import 'package:flutter/material.dart';
import '../../../models/editor_models.dart';
import 'common/common_controls.dart';

class TextTab extends StatefulWidget {
  final SubtitleClip clip;
  final Function({
    String? text, 
    TextCase? textCase, 
    double? fontSize, 
    double? letterSpacing,
    CustomBlendMode? blendMode,
  }) onUpdate;

  const TextTab({
    super.key,
    required this.clip,
    required this.onUpdate,
  });

  @override
  State<TextTab> createState() => _TextTabState();
}

class _TextTabState extends State<TextTab> {
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('EDIT CONTENT', style: TextStyle(fontSize: 8, color: Colors.white38, fontWeight: FontWeight.w900, letterSpacing: 1.0)),
          const SizedBox(height: 12),
          CommonControls.buildTextField(widget.clip.text, (v) => widget.onUpdate(text: v)),
          const SizedBox(height: 20),
          _buildCasingRow(),
          const SizedBox(height: 24),
          const Text('BLENDING MODE', style: TextStyle(fontSize: 8, color: Colors.white38, fontWeight: FontWeight.w900, letterSpacing: 1.0)),
          const SizedBox(height: 12),
          _buildBlendModeChips(),
          const SizedBox(height: 24),
          const Text('TYPOGRAPHY', style: TextStyle(fontSize: 8, color: Colors.white38, fontWeight: FontWeight.w900, letterSpacing: 1.0)),
          const SizedBox(height: 16),
          CommonControls.buildSlider(context, 'Font Size', widget.clip.fontSize, 10, 200, (v) => widget.onUpdate(fontSize: v), onReset: () => widget.onUpdate(fontSize: 60)),
          const SizedBox(height: 12),
          CommonControls.buildSlider(context, 'Letter Spacing', widget.clip.letterSpacing, -5, 40, (v) => widget.onUpdate(letterSpacing: v), onReset: () => widget.onUpdate(letterSpacing: 0)),
        ],
      ),
    );
  }

  Widget _buildBlendModeChips() {
    final modes = [
      {'mode': CustomBlendMode.normal, 'label': 'NORMAL'},
      {'mode': CustomBlendMode.multiply, 'label': 'MULTIPLY'},
      {'mode': CustomBlendMode.screen, 'label': 'SCREEN'},
      {'mode': CustomBlendMode.overlay, 'label': 'OVERLAY'},
      {'mode': CustomBlendMode.colorDodge, 'label': 'DODGE'},
      {'mode': CustomBlendMode.colorBurn, 'label': 'BURN'},
    ];

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: modes.map((m) {
        final isSelected = widget.clip.blendMode == m['mode'];
        return GestureDetector(
          onTap: () => widget.onUpdate(blendMode: m['mode'] as CustomBlendMode),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: isSelected ? Colors.deepPurpleAccent : Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: isSelected ? Colors.deepPurpleAccent : Colors.white10),
            ),
            child: Text(
              m['label'] as String,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.white60,
                fontSize: 9,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildCasingRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        const Text('CASING', style: TextStyle(fontSize: 8, color: Colors.white38, fontWeight: FontWeight.w900, letterSpacing: 1.0)),
        const SizedBox(width: 12),
        _buildCasingButton('AA', () => widget.onUpdate(textCase: TextCase.upper)),
        const SizedBox(width: 8),
        _buildCasingButton('aa', () => widget.onUpdate(textCase: TextCase.lower)),
        const SizedBox(width: 8),
        _buildCasingButton('Aa', () => widget.onUpdate(textCase: TextCase.title)),
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
}
