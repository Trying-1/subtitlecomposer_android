import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/editor_provider.dart';

class AspectTab extends StatelessWidget {
  const AspectTab({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<EditorProvider>();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('ASPECT RATIO', style: TextStyle(fontSize: 8, color: Colors.deepPurpleAccent, fontWeight: FontWeight.w900, letterSpacing: 1.0)),
        const SizedBox(height: 16),
        Row(
          children: [
            _buildRatioOption(context, 9/16, '9:16', Icons.smartphone_rounded, provider),
            const SizedBox(width: 12),
            _buildRatioOption(context, 1, '1:1', Icons.crop_din_rounded, provider),
            const SizedBox(width: 12),
            _buildRatioOption(context, 16/9, '16:9', Icons.tv_rounded, provider),
          ],
        ),
      ],
    );
  }

  Widget _buildRatioOption(BuildContext context, double ratio, String label, IconData icon, EditorProvider provider) {
    final isSelected = (provider.aspectRatio - ratio).abs() < 0.01;
    return Expanded(
      child: InkWell(
        onTap: () => provider.setAspectRatio(ratio),
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? Colors.deepPurpleAccent.withOpacity(0.1) : Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: isSelected ? Colors.deepPurpleAccent : Colors.white10),
          ),
          child: Column(
            children: [
              Icon(icon, size: 18, color: isSelected ? Colors.deepPurpleAccent : Colors.white38),
              const SizedBox(height: 4),
              Text(label, style: TextStyle(fontSize: 9, color: isSelected ? Colors.white : Colors.white24, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      ),
    );
  }
}
