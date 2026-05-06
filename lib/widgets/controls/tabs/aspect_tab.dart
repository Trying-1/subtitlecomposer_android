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
            const SizedBox(width: 12),
            _buildCustomRatioButton(context, provider),
          ],
        ),
        if (provider.customAspectRatios.isNotEmpty) ...[
          const SizedBox(height: 24),
          const Text('SAVED CUSTOM RATIOS', style: TextStyle(fontSize: 8, color: Colors.deepPurpleAccent, fontWeight: FontWeight.w900, letterSpacing: 1.0)),
          const SizedBox(height: 12),
          SizedBox(
            height: 48,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: provider.customAspectRatios.length,
              separatorBuilder: (context, index) => const SizedBox(width: 10),
              itemBuilder: (context, index) {
                final ratio = provider.customAspectRatios[index];
                return _buildSavedRatioItem(context, ratio, provider);
              },
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildSavedRatioItem(BuildContext context, double ratio, EditorProvider provider) {
    final isSelected = (provider.aspectRatio - ratio).abs() < 0.01;
    String label = ratio.toStringAsFixed(2);
    
    // Try to find common labels
    if ((ratio - 4/5).abs() < 0.01) label = '4:5';
    else if ((ratio - 21/9).abs() < 0.01) label = '21:9';
    else if ((ratio - 2/3).abs() < 0.01) label = '2:3';

    return InkWell(
      onLongPress: () => provider.removeCustomAspectRatio(ratio),
      onTap: () => provider.setAspectRatio(ratio),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: 80,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isSelected ? Colors.deepPurpleAccent.withOpacity(0.1) : Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: isSelected ? Colors.deepPurpleAccent : Colors.white10),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.bold,
            color: isSelected ? Colors.white : Colors.white60,
          ),
        ),
      ),
    );
  }

  Widget _buildCustomRatioButton(BuildContext context, EditorProvider provider) {
    return Expanded(
      child: InkWell(
        onTap: () => _showCustomRatioDialog(context, provider),
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.white10),
          ),
          child: const Column(
            children: [
              Icon(Icons.settings_overscan_rounded, size: 18, color: Colors.white38),
              SizedBox(height: 4),
              Text('CUSTOM', style: TextStyle(fontSize: 9, color: Colors.white24, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      ),
    );
  }

  void _showCustomRatioDialog(BuildContext context, EditorProvider provider) {
    final widthController = TextEditingController(text: '1080');
    final heightController = TextEditingController(text: '1920');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A23),
        title: const Text('Custom Aspect Ratio', style: TextStyle(color: Colors.white, fontSize: 16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: widthController,
              keyboardType: TextInputType.number,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: 'Width',
                labelStyle: TextStyle(color: Colors.white38),
                enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white10)),
                focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.deepPurpleAccent)),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: heightController,
              keyboardType: TextInputType.number,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: 'Height',
                labelStyle: TextStyle(color: Colors.white38),
                enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white10)),
                focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.deepPurpleAccent)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CANCEL', style: TextStyle(color: Colors.white38)),
          ),
          TextButton(
            onPressed: () {
              final w = double.tryParse(widthController.text);
              final h = double.tryParse(heightController.text);
              if (w != null && h != null && h != 0) {
                final ratio = w / h;
                provider.setAspectRatio(ratio);
                provider.addCustomAspectRatio(ratio);
              }
              Navigator.pop(context);
            },
            child: const Text('APPLY', style: TextStyle(color: Colors.deepPurpleAccent)),
          ),
        ],
      ),
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
