import 'package:flutter/material.dart';

class FaqPage extends StatefulWidget {
  const FaqPage({super.key});

  @override
  State<FaqPage> createState() => _FaqPageState();
}

class _FaqPageState extends State<FaqPage> {
  String? _selectedTitle;
  String? _selectedDescription;
  IconData? _selectedIcon;
  Color? _selectedColor;

  final List<Map<String, dynamic>> _bottomTabs = [
    {'name': 'Project', 'icon': Icons.folder_rounded, 'desc': 'Manage project settings, save/load, import media, and export your final video.'},
    {'name': 'Text', 'icon': Icons.text_fields_rounded, 'desc': 'Edit the actual text content of the selected subtitle clip, change case, and adjust letter spacing.'},
    {'name': 'Font', 'icon': Icons.font_download_rounded, 'desc': 'Select custom fonts for your text.'},
    {'name': 'Style', 'icon': Icons.palette_rounded, 'desc': 'Change text colors, opacity, apply gradients, and set basic entrance/exit animations.'},
    {'name': 'Effects', 'icon': Icons.auto_awesome_rounded, 'desc': 'Add advanced styling like neon glows, deep drop shadows, background text boxes, text strokes (outlines), and reflections.'},
    {'name': 'Layout', 'icon': Icons.grid_view_rounded, 'desc': 'Select and apply automatic positioning layouts (like Stack, Hero, Wave) to group multiple subtitle clips visually.'},
    {'name': 'Animation', 'icon': Icons.animation_rounded, 'desc': 'Browse and apply advanced, pre-made kinetic text animations.'},
    {'name': 'Keyframes', 'icon': Icons.diamond_rounded, 'desc': 'Add precise keyframes to manually animate translation (X/Y), rotation, and scale over time.'},
    {'name': 'Transform', 'icon': Icons.transform_rounded, 'desc': 'Manually adjust scale and rotation properties for the selected clip.'},
    {'name': 'Position', 'icon': Icons.location_on_rounded, 'desc': 'Fine-tune the exact X and Y coordinates of the clip on the screen.'},
    {'name': 'Timing', 'icon': Icons.more_time_rounded, 'desc': 'Manually edit the exact start and end millisecond timestamps of the clip.'},
    {'name': 'Overlay', 'icon': Icons.add_photo_alternate_rounded, 'desc': 'Import and edit image overlays or picture-in-picture (PiP) elements.'},
    {'name': 'Background', 'icon': Icons.wallpaper_rounded, 'desc': 'Set the main scene background (solid colors, stock images, or looping videos).'},
    {'name': 'Audio', 'icon': Icons.audiotrack_rounded, 'desc': 'Import background music, sound effects (SFX), or manage volume levels.'},
    {'name': 'Aspect', 'icon': Icons.aspect_ratio_rounded, 'desc': 'Change the global video resolution/aspect ratio (e.g., 9:16 for Shorts, 16:9 for YouTube).'},
    {'name': 'Remove BG', 'icon': Icons.auto_awesome_rounded, 'desc': 'Use Chroma Key tools to remove green screen backgrounds from overlays.'},
  ];

  final List<Map<String, dynamic>> _timelineTools = [
    {'name': 'UNDO', 'icon': Icons.undo_rounded, 'desc': 'Reverts your last timeline action or edit.'},
    {'name': 'REDO', 'icon': Icons.redo_rounded, 'desc': 'Restores the action you just undid.'},
    {'name': 'SPLIT', 'icon': Icons.content_cut_rounded, 'desc': 'Cuts the selected clip exactly where the white playhead line is positioned.'},
    {'name': 'MERGE', 'icon': Icons.link_rounded, 'desc': 'Combines two or more selected text clips into a single clip.'},
    {'name': 'DEL', 'icon': Icons.delete_outline_rounded, 'desc': 'Deletes the selected clip(s) from the timeline entirely.'},
    {'name': 'DIVIDE', 'icon': Icons.format_list_bulleted_rounded, 'desc': 'Splits a long subtitle clip automatically into individual words or smaller chunks.'},
    {'name': 'BURST', 'icon': Icons.flare_rounded, 'desc': 'Applies a dynamic, staggered pop-in animation effect to multiple selected words.'},
    {'name': 'TOGETHER', 'icon': Icons.splitscreen_rounded, 'desc': 'Forces multiple selected text clips to appear on screen at the exact same time.'},
    {'name': 'STACK', 'icon': Icons.layers_outlined, 'desc': 'Automatically stacks selected clips vertically on the screen like a neat column.'},
    {'name': 'AUTO AI', 'icon': Icons.auto_awesome_rounded, 'color': Colors.amberAccent, 'desc': 'The Magic Button! Opens the Kinetic Preset Sheet to instantly apply gorgeous animations, styles, and layouts to all text.'},
    {'name': 'RESET', 'icon': Icons.history_rounded, 'desc': 'Strips all styles, animations, and keyframes from the selected clip, returning it to default text.'},
    {'name': 'ADD TXT', 'icon': Icons.text_fields_rounded, 'color': Colors.deepPurpleAccent, 'desc': 'Manually spawns a brand new text layer at the current playhead position.'},
    {'name': 'BULK SFX', 'icon': Icons.library_music_rounded, 'desc': 'Automatically adds quick "whoosh" or "pop" sound effects to multiple text reveals.'},
    {'name': 'ALL', 'isSwitch': true, 'desc': 'Selects absolutely every single clip on the timeline at once for bulk editing.'},
    {'name': 'PUSH', 'isSwitch': true, 'desc': 'Toggles Collision Adjustment. When enabled, the editor acts like a physics engine and forcefully pushes overlapping texts apart so they don\'t sit on top of each other.'},
    {'name': 'LOCK', 'icon': Icons.lock_clock_rounded, 'desc': 'Locks the playhead to the center of the screen during playback.'},
    {'name': 'MULTI', 'isSwitch': true, 'desc': 'Enables Multi-Select Mode, allowing you to tap and highlight several clips to edit them simultaneously.'},
    {'name': 'LP START', 'icon': Icons.keyboard_double_arrow_right_rounded, 'color': Colors.cyanAccent, 'desc': 'Sets the starting point for a playback loop. Useful for focusing on a specific edit.'},
    {'name': 'TEXT', 'icon': Icons.visibility_rounded, 'desc': 'Toggles the visibility of all text tracks on the timeline.'},
    {'name': 'MARK', 'icon': Icons.bookmark_add_rounded, 'color': Colors.amberAccent, 'desc': 'Places a visual marker on the timeline at the current playhead to help you sync to beats.'},
    {'name': 'KEYFRAME', 'icon': Icons.diamond_rounded, 'desc': 'Drops a manual animation keyframe at the playhead.'},
  ];

  void _selectTool(String title, String desc, IconData? icon, [Color? color]) {
    setState(() {
      _selectedTitle = title;
      _selectedDescription = desc;
      _selectedIcon = icon ?? Icons.touch_app_rounded;
      _selectedColor = color ?? Colors.deepPurpleAccent;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F13),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'FAQ & Interface Guide',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18, fontFamily: 'KleeOne'),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          // Fixed display card at the top
          Padding(
            padding: const EdgeInsets.all(20),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOutCubic,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: _selectedTitle == null ? Colors.white.withOpacity(0.02) : (_selectedColor ?? Colors.deepPurpleAccent).withOpacity(0.05),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: _selectedTitle == null ? Colors.white.withOpacity(0.05) : (_selectedColor ?? Colors.deepPurpleAccent).withOpacity(0.2),
                  width: 2,
                ),
                boxShadow: _selectedTitle != null ? [
                  BoxShadow(
                    color: (_selectedColor ?? Colors.deepPurpleAccent).withOpacity(0.1),
                    blurRadius: 30,
                    spreadRadius: -5,
                  )
                ] : [],
              ),
              child: _selectedTitle == null
                  ? const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.ads_click_rounded, color: Colors.white38, size: 28),
                        SizedBox(width: 16),
                        Text(
                          'Tap any button below to see\nwhat it does.',
                          style: TextStyle(color: Colors.white54, fontSize: 14, height: 1.5, fontFamily: 'KleeOne'),
                        ),
                      ],
                    )
                  : Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: (_selectedColor ?? Colors.deepPurpleAccent).withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(_selectedIcon, color: _selectedColor ?? Colors.deepPurpleAccent, size: 32),
                        ),
                        const SizedBox(width: 20),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _selectedTitle!.toUpperCase(),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1.5,
                                  fontFamily: 'KleeOne',
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                _selectedDescription!,
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.7),
                                  fontSize: 13,
                                  height: 1.6,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
            ),
          ),
          
          const Divider(height: 1, color: Colors.white10),
          
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionLabel('TIMELINE TOOL PANEL REPLICA'),
                  const SizedBox(height: 12),
                  _buildTimelineToolbarReplica(),
                  const SizedBox(height: 40),
                  _buildSectionLabel('BOTTOM CONTROL PANEL REPLICA'),
                  const SizedBox(height: 12),
                  _buildBottomTabsReplica(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionLabel(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white38,
          fontSize: 10,
          fontWeight: FontWeight.w900,
          letterSpacing: 1.5,
          fontFamily: 'KleeOne',
        ),
      ),
    );
  }

  Widget _buildTimelineToolbarReplica() {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF1F1F29),
        border: Border(
          top: BorderSide(color: Colors.white10),
          bottom: BorderSide(color: Colors.white10),
        ),
      ),
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: _timelineTools.map((tool) {
            final isSwitch = tool['isSwitch'] ?? false;
            final isSelected = _selectedTitle == tool['name'];
            
            return Padding(
              padding: const EdgeInsets.only(right: 16),
              child: InkWell(
                onTap: () => _selectTool(tool['name'], tool['desc'], tool['icon'], tool['color']),
                borderRadius: BorderRadius.circular(4),
                child: Container(
                  color: isSelected ? Colors.white.withOpacity(0.05) : Colors.transparent,
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        height: 18,
                        width: 32,
                        child: Center(
                          child: isSwitch
                              ? FittedBox(
                                  fit: BoxFit.contain,
                                  child: IgnorePointer(
                                    child: Switch(
                                      value: false,
                                      onChanged: (_) {},
                                      activeColor: Colors.deepPurpleAccent,
                                      inactiveThumbColor: Colors.white24,
                                      inactiveTrackColor: Colors.white10,
                                    ),
                                  ),
                                )
                              : Icon(tool['icon'], size: 16, color: tool['color'] ?? Colors.white70),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        tool['name'],
                        style: TextStyle(
                          fontFamily: 'KleeOne',
                          fontSize: 7,
                          fontWeight: FontWeight.w900,
                          color: tool['color'] ?? Colors.white38,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildBottomTabsReplica() {
    return Container(
      height: 52,
      decoration: const BoxDecoration(
        color: Colors.black26,
        border: Border(
          top: BorderSide(color: Colors.white10),
          bottom: BorderSide(color: Colors.white10),
        ),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Row(
          children: _bottomTabs.map((tab) {
            final isSelected = _selectedTitle == tab['name'];
            return InkWell(
              onTap: () => _selectTool(tab['name'], tab['desc'], tab['icon']),
              child: Container(
                width: 72,
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected ? Colors.white.withOpacity(0.02) : Colors.transparent,
                  border: Border(
                    bottom: BorderSide(
                      color: isSelected ? Colors.deepPurpleAccent : Colors.transparent,
                      width: 2,
                    ),
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(tab['icon'], size: 16, color: isSelected ? Colors.deepPurpleAccent : Colors.white24),
                    const SizedBox(height: 4),
                    Text(
                      tab['name'].toUpperCase(),
                      style: TextStyle(
                        fontSize: 6.5,
                        letterSpacing: 0.5,
                        fontFamily: 'KleeOne',
                        color: isSelected ? Colors.white : Colors.white24,
                        fontWeight: isSelected ? FontWeight.w900 : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}
