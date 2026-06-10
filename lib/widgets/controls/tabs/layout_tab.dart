import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../models/editor_models.dart';
import '../../../providers/editor_provider.dart';

class LayoutTab extends StatelessWidget {
  final Function(LayoutPreset) onApplyPreset;
  final int selectedClipCount;

  const LayoutTab({
    super.key,
    required this.onApplyPreset,
    required this.selectedClipCount,
  });

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<EditorProvider>();
    final customLayouts = provider.customLayouts;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'LAYOUT PRESETS',
              style: TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
              ),
            ),
            if (selectedClipCount > 1)
              TextButton.icon(
                onPressed: () => _showSaveLayoutDialog(context, provider),
                icon: const Icon(Icons.add_task_rounded, size: 14, color: Colors.greenAccent),
                label: const Text('SAVE CURRENT', style: TextStyle(color: Colors.greenAccent, fontSize: 10, fontWeight: FontWeight.bold)),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  backgroundColor: Colors.greenAccent.withOpacity(0.1),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                ),
              ),
          ],
        ),
        const SizedBox(height: 16),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 4,
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          childAspectRatio: 1.1,
          children: [
            _buildPresetCard(context, 'Column', Icons.view_column_rounded, LayoutPreset.column),
            _buildPresetCard(context, 'Grid', Icons.grid_view_rounded, LayoutPreset.grid),
            _buildPresetCard(context, 'Bento', Icons.dashboard_rounded, LayoutPreset.bento),
            _buildPresetCard(context, 'Stairs', Icons.stairs_rounded, LayoutPreset.stairs),
            _buildPresetCard(context, 'Wave', Icons.waves_rounded, LayoutPreset.wave),
            _buildPresetCard(context, 'Circle', Icons.blur_circular_rounded, LayoutPreset.circle),
            _buildPresetCard(context, 'Spiral', Icons.cyclone_rounded, LayoutPreset.spiral),
            _buildPresetCard(context, 'Staggered', Icons.waterfall_chart_rounded, LayoutPreset.staggered),
            _buildPresetCard(context, 'Masonry', Icons.dashboard_customize_rounded, LayoutPreset.masonry),
            _buildPresetCard(context, 'Collage', Icons.auto_awesome_mosaic_rounded, LayoutPreset.collage),
            _buildPresetCard(context, 'Diagonal', Icons.trending_down_rounded, LayoutPreset.diagonal),
            _buildPresetCard(context, 'Target', Icons.gps_fixed_rounded, LayoutPreset.target),
            _buildPresetCard(context, 'Explosion', Icons.flare_rounded, LayoutPreset.explosion),
            _buildPresetCard(context, 'Perspective', Icons.view_in_ar_rounded, LayoutPreset.perspective),
            _buildPresetCard(context, 'Hero', Icons.star_border_rounded, LayoutPreset.hero),
            _buildPresetCard(context, 'Random', Icons.shuffle_rounded, LayoutPreset.random),
            _buildPresetCard(context, 'Reset', Icons.refresh_rounded, LayoutPreset.none),
          ],
        ),
        
        if (customLayouts.isNotEmpty) ...[
          const SizedBox(height: 24),
          const Text(
            'MY PRESETS',
            style: TextStyle(
              color: Colors.white38,
              fontSize: 10,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 60,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: customLayouts.length,
              separatorBuilder: (context, _) => const SizedBox(width: 10),
              itemBuilder: (context, index) {
                final layout = customLayouts[index];
                return _buildCustomLayoutCard(context, provider, layout);
              },
            ),
          ),
        ],

        if (selectedClipCount <= 1)
          Padding(
            padding: const EdgeInsets.only(top: 20),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.amberAccent.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.amberAccent.withOpacity(0.2)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, color: Colors.amberAccent, size: 16),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Select multiple stacked segments to use layout presets effectively.',
                      style: TextStyle(color: Colors.white70, fontSize: 10),
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildPresetCard(BuildContext context, String label, IconData icon, LayoutPreset preset) {
    return InkWell(
      onTap: () => onApplyPreset(preset),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.white.withOpacity(0.05)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 18, color: Colors.white70),
            const SizedBox(height: 4),
            Text(
              label.toUpperCase(),
              style: const TextStyle(
                color: Colors.white38,
                fontSize: 7.5,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCustomLayoutCard(BuildContext context, EditorProvider provider, CustomLayout layout) {
    return Stack(
      children: [
        InkWell(
          onTap: () => provider.applyCustomLayout(layout),
          borderRadius: BorderRadius.circular(8),
          child: Container(
            width: 100,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.deepPurpleAccent.withOpacity(0.2), Colors.deepPurpleAccent.withOpacity(0.1)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.deepPurpleAccent.withOpacity(0.3)),
            ),
            padding: const EdgeInsets.all(8),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.star_rounded, size: 16, color: Colors.amberAccent),
                const SizedBox(height: 4),
                Text(
                  layout.name.toUpperCase(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        ),
        Positioned(
          top: 2,
          right: 2,
          child: GestureDetector(
            onTap: () => provider.deleteCustomLayout(layout.id),
            child: Container(
              padding: const EdgeInsets.all(2),
              decoration: const BoxDecoration(color: Colors.black45, shape: BoxShape.circle),
              child: const Icon(Icons.close_rounded, size: 10, color: Colors.white38),
            ),
          ),
        ),
      ],
    );
  }

  void _showSaveLayoutDialog(BuildContext context, EditorProvider provider) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Save Layout Preset', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
        content: TextField(
          controller: controller,
          autofocus: true,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: 'Layout name (e.g. My Style 1)',
            hintStyle: TextStyle(color: Colors.white.withOpacity(0.2)),
            filled: true,
            fillColor: Colors.white.withOpacity(0.05),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CANCEL', style: TextStyle(color: Colors.white38)),
          ),
          ElevatedButton(
            onPressed: () {
              if (controller.text.trim().isNotEmpty) {
                provider.saveCurrentLayoutAsPreset(controller.text.trim());
                Navigator.pop(context);
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.deepPurpleAccent),
            child: const Text('SAVE', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
