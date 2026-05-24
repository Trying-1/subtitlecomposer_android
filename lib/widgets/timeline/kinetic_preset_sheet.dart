import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/editor_models.dart';
import '../../providers/asset_provider.dart';
import '../../utils/palette_presets.dart';
import '../../services/kinetic/kinetic_style.dart';
import '../common/custom_color_picker.dart';
import '../../services/ads/ad_service.dart';

class KineticPresetSheet extends StatefulWidget {
  final List<String> allFonts;
  final Function(List<KineticStyle>, bool, int) onApply;

  const KineticPresetSheet({
    super.key,
    required this.allFonts,
    required this.onApply,
  });

  @override
  State<KineticPresetSheet> createState() => _KineticPresetSheetState();
}

class _KineticPresetSheetState extends State<KineticPresetSheet> {
  static Set<int>? _rememberedPresetIndices;
  static bool? _rememberedMixedMode;
  static bool? _rememberedDoBurst;
  static Set<String>? _rememberedFonts;
  static bool? _rememberedStroke;
  static bool? _rememberedGlow;
  static Set<int>? _rememberedTextColors;
  static int? _rememberedBgColor;
  static Set<AnimationType>? _rememberedEntrancePool;
  static Set<AnimationType>? _rememberedExitPool;
  static bool? _rememberedEnableEntrance;
  static bool? _rememberedEnableExit;
  static double? _rememberedMinFontSize;
  static double? _rememberedMaxFontSize;
  static RotationMode? _rememberedRotationMode;
  static double? _rememberedMinScale;
  static double? _rememberedMaxScale;

  static final List<KineticStyle> _customPresets = [];

  Set<int> _selectedPresetIndices = {0};
  bool _isMixedMode = false;
  bool _doBurst = true;
  late Set<String> _selectedFonts;
  late bool _enableStroke;
  late bool _enableGlow;
  late Set<int> _selectedTextColors;
  late int _selectedBgColor;
  late Set<AnimationType> _selectedEntrancePool;
  late Set<AnimationType> _selectedExitPool;
  late bool _enableEntranceAnimation;
  late bool _enableExitAnimation;
  late double _minFontSize;
  late double _maxFontSize;
  late RotationMode _rotationMode;
  late double _minScale;
  late double _maxScale;

  // Available animation subsets for the UI picker
  final List<AnimationType> _availableEntranceAnimations = const [
    AnimationType.fadeIn, AnimationType.slideUp, AnimationType.smoothSlideUp,
    AnimationType.bounceIn, AnimationType.zoomIn, AnimationType.elasticDrop,
    AnimationType.glitch, AnimationType.typewriter, AnimationType.throwback,
    AnimationType.spin3D, AnimationType.flip3D_X, AnimationType.scaleUp,
  ];

  final List<AnimationType> _availableExitAnimations = const [
    AnimationType.fadeOut, AnimationType.slideDown, AnimationType.zoomOut, AnimationType.scaleDown,
  ];

  @override
  void initState() {
    super.initState();
    _selectedPresetIndices = _rememberedPresetIndices ?? {0};
    _isMixedMode = _rememberedMixedMode ?? false;
    _doBurst = _rememberedDoBurst ?? true;

    final presets = [...KineticPresets.all, ..._customPresets];
    final firstIndex = _selectedPresetIndices.isNotEmpty ? _selectedPresetIndices.first : 0;
    final preset = presets[firstIndex.clamp(0, presets.length - 1)];
    
    // User manual selections default to the initial preset's settings if not remembered
    _selectedFonts = _rememberedFonts ?? {'Poppins', 'Michroma', 'LuckiestGuy'};
    _enableStroke = _rememberedStroke ?? preset.enableStroke;
    _enableGlow = _rememberedGlow ?? preset.enableGlow;
    
    _selectedEntrancePool = _rememberedEntrancePool ?? preset.entrancePool.toSet();
    _selectedExitPool = _rememberedExitPool ?? preset.exitPool.toSet();
    _enableEntranceAnimation = _rememberedEnableEntrance ?? preset.enableEntranceAnimation;
    _enableExitAnimation = _rememberedEnableExit ?? preset.enableExitAnimation;
    _minFontSize = _rememberedMinFontSize ?? preset.minFontSize;
    _maxFontSize = _rememberedMaxFontSize ?? preset.maxFontSize;
    _rotationMode = _rememberedRotationMode ?? preset.rotationMode;
    _minScale = _rememberedMinScale ?? preset.minScale;
    _maxScale = _rememberedMaxScale ?? preset.maxScale;

    // Default complementary text colors
    _selectedTextColors = _rememberedTextColors ?? {0xFFFFFFFF, 0xFFFF0054, 0xFF00FFFF};

    // Default background color
    _selectedBgColor = _rememberedBgColor ?? 0xFF07040B;
  }

  void _showCustomColorPicker(BuildContext context, Color initial, ValueChanged<Color> onColorChanged) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.transparent, // Disable background dimming
      elevation: 0,
      isScrollControlled: true,
      builder: (context) => CustomColorPicker(
        initialColor: initial,
        onColorChanged: onColorChanged,
      ),
    );
  }

  void _promptCreatePreset(BuildContext context, List<KineticStyle> currentPresets) {
    final textController = TextEditingController();
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: const Color(0xFF0F0F16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text(
            'Save Custom Preset',
            style: TextStyle(
              fontFamily: 'KleeOne',
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Create a reusable preset containing your current custom color palette and font selections.',
                style: TextStyle(
                  fontFamily: 'KleeOne',
                  color: Colors.white.withValues(alpha: 0.5),
                  fontSize: 11,
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: textController,
                autofocus: true,
                style: const TextStyle(
                  fontFamily: 'KleeOne',
                  color: Colors.white,
                  fontSize: 13,
                ),
                decoration: InputDecoration(
                  hintText: 'Preset Name (e.g. My Branding Style)',
                  hintStyle: const TextStyle(color: Colors.white24, fontSize: 12),
                  filled: true,
                  fillColor: Colors.white.withValues(alpha: 0.05),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text(
                'Cancel',
                style: TextStyle(
                  fontFamily: 'KleeOne',
                  color: Colors.white38,
                  fontSize: 12,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                final name = textController.text.trim();
                if (name.isNotEmpty) {
                  final firstIdx = _selectedPresetIndices.isNotEmpty ? _selectedPresetIndices.first : 0;
                  final baseStyle = currentPresets[firstIdx.clamp(0, currentPresets.length - 1)];
                  final customStyle = baseStyle.copyWith(
                    name: name,
                    icon: '🎨',
                    colorPalette: _selectedTextColors.toList(),
                    fontPool: _selectedFonts.toList(),
                    enableStroke: _enableStroke,
                    enableGlow: _enableGlow,
                    enableShadow: _enableGlow,
                    entrancePool: _selectedEntrancePool.toList(),
                    exitPool: _selectedExitPool.toList(),
                    enableEntranceAnimation: _selectedEntrancePool.isNotEmpty,
                    enableExitAnimation: _selectedExitPool.isNotEmpty,
                  );
                  setState(() {
                    _customPresets.add(customStyle);
                    _selectedPresetIndices = {currentPresets.length}; // Select the newly created custom preset
                  });
                  Navigator.pop(dialogContext);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepPurpleAccent,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text(
                'Save',
                style: TextStyle(
                  fontFamily: 'KleeOne',
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _promptRenamePreset(BuildContext context, KineticStyle preset) {
    final textController = TextEditingController(text: preset.name);
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: const Color(0xFF0F0F16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text(
            'Rename Custom Preset',
            style: TextStyle(
              fontFamily: 'KleeOne',
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: textController,
                autofocus: true,
                style: const TextStyle(
                  fontFamily: 'KleeOne',
                  color: Colors.white,
                  fontSize: 13,
                ),
                decoration: InputDecoration(
                  hintText: 'New Preset Name',
                  hintStyle: const TextStyle(color: Colors.white24, fontSize: 12),
                  filled: true,
                  fillColor: Colors.white.withValues(alpha: 0.05),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text(
                'Cancel',
                style: TextStyle(
                  fontFamily: 'KleeOne',
                  color: Colors.white38,
                  fontSize: 12,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                final name = textController.text.trim();
                if (name.isNotEmpty) {
                  final customIndex = _customPresets.indexOf(preset);
                  if (customIndex != -1) {
                    setState(() {
                      _customPresets[customIndex] = _customPresets[customIndex].copyWith(name: name);
                    });
                  }
                  Navigator.pop(dialogContext);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepPurpleAccent,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text(
                'Rename',
                style: TextStyle(
                  fontFamily: 'KleeOne',
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showUpdateConfirmation(BuildContext context, KineticStyle preset) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: const Color(0xFF0F0F16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text(
            'Update Preset Settings',
            style: TextStyle(
              fontFamily: 'KleeOne',
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Text(
            'This will overwrite "${preset.name}" with your current custom color palette, font pool, background, text stroke, and glow selections. Proceed?',
            style: TextStyle(
              fontFamily: 'KleeOne',
              color: Colors.white.withValues(alpha: 0.6),
              fontSize: 12,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text(
                'Cancel',
                style: TextStyle(
                  fontFamily: 'KleeOne',
                  color: Colors.white38,
                  fontSize: 12,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                final customIndex = _customPresets.indexOf(preset);
                if (customIndex != -1) {
                  setState(() {
                    _customPresets[customIndex] = _customPresets[customIndex].copyWith(
                      colorPalette: _selectedTextColors.toList(),
                      fontPool: _selectedFonts.toList(),
                      enableStroke: _enableStroke,
                      enableGlow: _enableGlow,
                      enableShadow: _enableGlow,
                      entrancePool: _selectedEntrancePool.toList(),
                      exitPool: _selectedExitPool.toList(),
                      enableEntranceAnimation: _selectedEntrancePool.isNotEmpty,
                      enableExitAnimation: _selectedExitPool.isNotEmpty,
                    );
                  });
                }
                Navigator.pop(dialogContext);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    backgroundColor: const Color(0xFF1E1E2A),
                    content: Text(
                      'Successfully updated "${preset.name}" settings!',
                      style: const TextStyle(fontFamily: 'KleeOne', color: Colors.white, fontSize: 12),
                    ),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepPurpleAccent,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text(
                'Update',
                style: TextStyle(
                  fontFamily: 'KleeOne',
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showDeleteConfirmation(BuildContext context, KineticStyle preset) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: const Color(0xFF0F0F16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text(
            'Delete Preset',
            style: TextStyle(
              fontFamily: 'KleeOne',
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Text(
            'Are you sure you want to permanently delete "${preset.name}"?',
            style: TextStyle(
              fontFamily: 'KleeOne',
              color: Colors.white.withValues(alpha: 0.6),
              fontSize: 12,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text(
                'Cancel',
                style: TextStyle(
                  fontFamily: 'KleeOne',
                  color: Colors.white38,
                  fontSize: 12,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                final customIndex = _customPresets.indexOf(preset);
                if (customIndex != -1) {
                  setState(() {
                    _customPresets.removeAt(customIndex);
                    _selectedPresetIndices = {0}; // fallback to first layout
                    
                    // Don't reset manual colors/fonts when deleting a preset
                  });
                }
                Navigator.pop(dialogContext);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text(
                'Delete',
                style: TextStyle(
                  fontFamily: 'KleeOne',
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final presets = [...KineticPresets.all, ..._customPresets];
    final firstIdx = _selectedPresetIndices.isNotEmpty ? _selectedPresetIndices.first : 0;
    final selectedPreset = presets[firstIdx.clamp(0, presets.length - 1)];

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.88,
      ),
      decoration: const BoxDecoration(
        color: Color(0xFF0A0A0F),
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag Handle & Header Section
          Container(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white12,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          
          // Header with elegant KleeOne typography
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
            child: Row(
              children: [
                // Glowing Icon
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.deepPurpleAccent.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.auto_awesome_rounded,
                    color: Colors.deepPurpleAccent,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Auto-Kinetic Typography',
                        style: TextStyle(
                          fontFamily: 'KleeOne',
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Sequential staggering, aesthetic layout & design automation',
                        style: TextStyle(
                          fontFamily: 'KleeOne',
                          color: Colors.white38,
                          fontSize: 10,
                          fontWeight: FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close_rounded, color: Colors.white24, size: 20),
                ),
              ],
            ),
          ),

          const Divider(color: Colors.white10, height: 1),

          // Scrollable Content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // PRESETS TITLE with dynamic Custom presets toolbar
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'CHOOSE BASE PRESET STYLE',
                        style: TextStyle(
                          fontFamily: 'KleeOne',
                          color: Colors.white38,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.0,
                        ),
                      ),
                      if (_selectedPresetIndices.isNotEmpty && _selectedPresetIndices.first >= KineticPresets.all.length) ...[
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Rename Button
                            GestureDetector(
                              onTap: () => _promptRenamePreset(context, selectedPreset),
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                margin: const EdgeInsets.only(right: 8),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.05),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: const Icon(Icons.edit_rounded, color: Colors.white70, size: 12),
                              ),
                            ),
                            // Update Button
                            GestureDetector(
                              onTap: () => _showUpdateConfirmation(context, selectedPreset),
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                margin: const EdgeInsets.only(right: 8),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.05),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: const Icon(Icons.save_rounded, color: Colors.deepPurpleAccent, size: 12),
                              ),
                            ),
                            // Delete Button
                            GestureDetector(
                              onTap: () => _showDeleteConfirmation(context, selectedPreset),
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: Colors.red.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: const Icon(Icons.delete_rounded, color: Colors.redAccent, size: 12),
                              ),
                            ),
                          ],
                        ),
                      ] else ...[
                        Text(
                          '${presets.length} options',
                          style: const TextStyle(
                            fontFamily: 'KleeOne',
                            color: Colors.white24,
                            fontSize: 9,
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 12),
                  
                  // Horizontal Preset Cards (including custom preset creator)
                  SizedBox(
                    height: 110,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: presets.length + 1,
                      itemBuilder: (context, index) {
                        if (index == 0) {
                          // The first card is "Save Preset Creator" card
                          return Padding(
                            padding: const EdgeInsets.only(right: 12),
                            child: GestureDetector(
                              onTap: () => _promptCreatePreset(context, presets),
                              child: Container(
                                width: 130,
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.01),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: Colors.white.withValues(alpha: 0.05),
                                    width: 1.5,
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(
                                      Icons.add_circle_outline_rounded,
                                      color: Colors.deepPurpleAccent,
                                      size: 20,
                                    ),
                                    const SizedBox(height: 8),
                                    const Text(
                                      'Save Selection As Preset',
                                      style: TextStyle(
                                        fontFamily: 'KleeOne',
                                        color: Colors.white,
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Store colors & fonts',
                                      style: TextStyle(
                                        fontFamily: 'KleeOne',
                                        color: Colors.white.withValues(alpha: 0.3),
                                        fontSize: 8.5,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        }

                        // Presets Cards
                        final presetIndex = index - 1;
                        final preset = presets[presetIndex];
                        final isSelected = _selectedPresetIndices.contains(presetIndex);
                        final baseColor = Color(preset.colorPalette.first);
                        
                        return Padding(
                          padding: const EdgeInsets.only(right: 12),
                          child: GestureDetector(
                            onTap: () {
                              setState(() {
                                if (_isMixedMode) {
                                  if (_selectedPresetIndices.contains(presetIndex)) {
                                    if (_selectedPresetIndices.length > 1) {
                                      _selectedPresetIndices.remove(presetIndex);
                                    }
                                  } else {
                                    _selectedPresetIndices.add(presetIndex);
                                  }
                                } else {
                                  _selectedPresetIndices = {presetIndex};
                                  _selectedEntrancePool = preset.entrancePool.toSet();
                                  _selectedExitPool = preset.exitPool.toSet();
                                  _enableEntranceAnimation = preset.enableEntranceAnimation;
                                  _enableExitAnimation = preset.enableExitAnimation;
                                  _minFontSize = preset.minFontSize;
                                  _maxFontSize = preset.maxFontSize;
                                  _rotationMode = preset.rotationMode;
                                  _minScale = preset.minScale;
                                  _maxScale = preset.maxScale;
                                  _enableStroke = preset.enableStroke;
                                  _enableGlow = preset.enableGlow;
                                }
                              });
                            },
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              width: 130,
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: isSelected ? baseColor.withValues(alpha: 0.12) : const Color(0xFF13131A),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: isSelected
                                      ? baseColor.withValues(alpha: 0.5)
                                      : Colors.white.withValues(alpha: 0.03),
                                  width: 1.5,
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        preset.icon,
                                        style: const TextStyle(fontSize: 16),
                                      ),
                                      if (isSelected)
                                        Icon(
                                          Icons.check_circle_rounded,
                                          size: 14,
                                          color: baseColor,
                                        ),
                                    ],
                                  ),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        preset.name,
                                        style: const TextStyle(
                                          fontFamily: 'KleeOne',
                                          color: Colors.white,
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  
                  const SizedBox(height: 16),

                  // Mixed Mode Toggle
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFF13131A),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: _isMixedMode ? Colors.deepPurpleAccent.withValues(alpha: 0.3) : Colors.white.withValues(alpha: 0.03)),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.shuffle_rounded,
                          color: _isMixedMode ? Colors.deepPurpleAccent : Colors.white38,
                          size: 18,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Mixed Layout Mode',
                                style: TextStyle(
                                  fontFamily: 'KleeOne',
                                  color: _isMixedMode ? Colors.white : Colors.white70,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                _isMixedMode ? 'Select multiple presets to alternate styles across sentences.' : 'Apply same selected style to all target sentences.',
                                style: const TextStyle(
                                  fontFamily: 'KleeOne',
                                  color: Colors.white38,
                                  fontSize: 10,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Switch(
                          value: _isMixedMode,
                          onChanged: (val) {
                            setState(() {
                              _isMixedMode = val;
                              if (!val && _selectedPresetIndices.length > 1) {
                                // If disabled, retain only the first selection
                                _selectedPresetIndices = {_selectedPresetIndices.first};
                              }
                            });
                          },
                          activeColor: Colors.deepPurpleAccent,
                          activeTrackColor: Colors.deepPurpleAccent.withValues(alpha: 0.3),
                          inactiveThumbColor: Colors.white38,
                          inactiveTrackColor: Colors.white10,
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 24),

                  // Stagger & Stack Timing Card
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFF13131A),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.03)),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.speed_rounded,
                          color: Colors.white38,
                          size: 18,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Burst & Stagger Timing',
                                style: TextStyle(
                                  fontFamily: 'KleeOne',
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Stack words inside the sentence duration limits.',
                                style: TextStyle(
                                  fontFamily: 'KleeOne',
                                  color: Colors.white38,
                                  fontSize: 9.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Switch.adaptive(
                          value: _doBurst,
                          onChanged: (val) => setState(() => _doBurst = val),
                          activeColor: Colors.deepPurpleAccent,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // STYLE OVERRIDES SWITCHES (Separate Row, No Card Wrapping!)
                  const Text(
                    'STYLE OVERRIDES',
                    style: TextStyle(
                      fontFamily: 'KleeOne',
                      color: Colors.white38,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.0,
                    ),
                  ),
                  const SizedBox(height: 10),
                  
                  // Text Stroke Override Row
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.border_color_rounded,
                          size: 16,
                          color: Colors.white54,
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Text(
                            'Apply Text Border / Outline',
                            style: TextStyle(
                              fontFamily: 'KleeOne',
                              color: Colors.white70,
                              fontSize: 12.5,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        Switch.adaptive(
                          value: _enableStroke,
                          onChanged: (val) => setState(() => _enableStroke = val),
                          activeColor: Colors.deepPurpleAccent,
                        ),
                      ],
                    ),
                  ),
                  const Divider(color: Colors.white10, height: 12),
                  
                  // Neon Glow Override Row
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.blur_on_rounded,
                          size: 16,
                          color: Colors.white54,
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Text(
                            'Apply Neon Glow / Outer Shadow',
                            style: TextStyle(
                              fontFamily: 'KleeOne',
                              color: Colors.white70,
                              fontSize: 12.5,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        Switch.adaptive(
                          value: _enableGlow,
                          onChanged: (val) => setState(() => _enableGlow = val),
                          activeColor: Colors.deepPurpleAccent,
                        ),
                      ],
                    ),
                  ),
                  const Divider(color: Colors.white10, height: 12),

                  // Entrance Animation Override Row
                  _buildAnimationPoolSelector(
                    'ENTRANCE ANIMATION POOL',
                    Icons.login_rounded,
                    _enableEntranceAnimation,
                    (val) => setState(() => _enableEntranceAnimation = val),
                    _availableEntranceAnimations,
                    _selectedEntrancePool,
                    () {
                      setState(() {
                        _selectedEntrancePool = selectedPreset.entrancePool.toSet();
                      });
                    },
                  ),
                  const Divider(color: Colors.white10, height: 24),
                  
                  // Exit Animation Override Row
                  _buildAnimationPoolSelector(
                    'EXIT ANIMATION POOL',
                    Icons.logout_rounded,
                    _enableExitAnimation,
                    (val) => setState(() => _enableExitAnimation = val),
                    _availableExitAnimations,
                    _selectedExitPool,
                    () {
                      setState(() {
                        _selectedExitPool = selectedPreset.exitPool.toSet();
                      });
                    },
                  ),

                  const SizedBox(height: 24),

                  // UNIFIED COLOR PALETTE & ROLES SELECTION
                  Row(
                    children: [
                      const Text(
                        'COLOR PALETTE & ROLES',
                        style: TextStyle(
                          fontFamily: 'KleeOne',
                          color: Colors.white38,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.0,
                        ),
                      ),
                      const Spacer(),
                      const Text(
                        'Unified Theme Active',
                        style: TextStyle(
                          fontFamily: 'KleeOne',
                          color: Colors.deepPurpleAccent,
                          fontSize: 9.5,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Consumer<AssetProvider>(
                    builder: (context, assetProvider, child) {
                      // Gather all custom and preset palettes
                      final List<ColorPalette> allPalettes = [];
                      
                      // Custom saved palettes first
                      allPalettes.addAll(assetProvider.palettes);
                      
                      // Preset categories next
                      for (var cat in PalettePresets.categories) {
                        allPalettes.addAll(cat.palettes);
                      }

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            physics: const BouncingScrollPhysics(),
                            child: Row(
                              children: allPalettes.map((palette) {
                                final isSelected = _selectedTextColors.length == palette.colors.length && 
                                                   _selectedTextColors.every((c) => palette.colors.contains(c)) &&
                                                   _selectedBgColor == palette.colors[0];
                                
                                return Padding(
                                  padding: const EdgeInsets.only(right: 12),
                                  child: GestureDetector(
                                    onTap: () {
                                      setState(() {
                                        // Assign background color (slot 0)
                                        if (palette.colors.isNotEmpty) {
                                          _selectedBgColor = palette.colors[0];
                                        }
                                        // Assign text colors (slots 0, 1, 2, 3)
                                        _selectedTextColors = palette.colors.toSet();
                                      });
                                    },
                                    child: AnimatedContainer(
                                      duration: const Duration(milliseconds: 200),
                                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                      decoration: BoxDecoration(
                                        color: isSelected
                                            ? Colors.deepPurpleAccent.withValues(alpha: 0.12)
                                            : Colors.white.withValues(alpha: 0.02),
                                        borderRadius: BorderRadius.circular(16),
                                        border: Border.all(
                                          color: isSelected
                                              ? Colors.deepPurpleAccent
                                              : Colors.white.withValues(alpha: 0.06),
                                          width: isSelected ? 1.8 : 1.0,
                                        ),
                                        boxShadow: [
                                          if (isSelected)
                                            BoxShadow(
                                              color: Colors.deepPurpleAccent.withValues(alpha: 0.15),
                                              blurRadius: 8,
                                              offset: const Offset(0, 3),
                                            ),
                                        ],
                                      ),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            palette.name.toUpperCase(),
                                            style: TextStyle(
                                              fontFamily: 'KleeOne',
                                              fontSize: 8,
                                              fontWeight: FontWeight.w900,
                                              color: isSelected ? Colors.white : Colors.white38,
                                              letterSpacing: 0.5,
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          Row(
                                            children: palette.colors.asMap().entries.map((entry) {
                                              final idx = entry.key;
                                              final c = entry.value;
                                              // Render tiny circle for each role
                                              return Container(
                                                margin: const EdgeInsets.only(right: 5),
                                                width: 14,
                                                height: 14,
                                                decoration: BoxDecoration(
                                                  color: Color(c),
                                                  shape: BoxShape.circle,
                                                  border: Border.all(
                                                    color: idx == 0 ? Colors.white30 : Colors.transparent,
                                                    width: 0.5,
                                                  ),
                                                ),
                                              );
                                            }).toList(),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                          ),
                          const SizedBox(height: 16),
                          // Active Palette Roles Detail Card
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.015),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: Colors.white.withValues(alpha: 0.04)),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'SEMANTIC ROLES MAPPING (TAP TO EDIT)',
                                  style: TextStyle(
                                    fontFamily: 'KleeOne',
                                    fontSize: 7.5,
                                    fontWeight: FontWeight.w900,
                                    color: Colors.white38,
                                    letterSpacing: 0.8,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: List.generate(4, (index) {
                                    // Slot colors:
                                    // Slot 0: Background (_selectedBgColor)
                                    // Slot 1, 2, 3: Text colors (_selectedTextColors)
                                    final textColorsList = _selectedTextColors.toList();
                                    final Color currentColor;
                                    if (index == 0) {
                                      currentColor = Color(_selectedBgColor);
                                    } else {
                                      // Ensure index matches a valid text color slot
                                      final listIdx = index;
                                      if (listIdx < textColorsList.length) {
                                        currentColor = Color(textColorsList[listIdx]);
                                      } else {
                                        currentColor = Colors.white;
                                      }
                                    }

                                    final String roleLabel;
                                    switch (index) {
                                      case 0:
                                        roleLabel = 'BACKGROUND';
                                        break;
                                      case 1:
                                        roleLabel = 'MAIN TEXT';
                                        break;
                                      case 2:
                                        roleLabel = 'SUB MAIN';
                                        break;
                                      case 3:
                                        roleLabel = 'NORMAL TEXT';
                                        break;
                                      default:
                                        roleLabel = 'EXTRA';
                                    }

                                    return Expanded(
                                      child: GestureDetector(
                                        onTap: () {
                                          _showCustomColorPicker(
                                            context,
                                            currentColor,
                                            (newColor) {
                                              setState(() {
                                                if (index == 0) {
                                                  _selectedBgColor = newColor.value;
                                                  // Synchronize the first index of text colors if it exists
                                                  final list = _selectedTextColors.toList();
                                                  if (list.isNotEmpty) {
                                                    list[0] = newColor.value;
                                                    _selectedTextColors = list.toSet();
                                                  }
                                                } else {
                                                  final list = _selectedTextColors.toList();
                                                  while (list.length <= index) {
                                                    list.add(Colors.white.value);
                                                  }
                                                  list[index] = newColor.value;
                                                  _selectedTextColors = list.toSet();
                                                }
                                              });
                                            },
                                          );
                                        },
                                        child: Container(
                                          margin: EdgeInsets.only(
                                            left: index == 0 ? 0 : 3,
                                            right: index == 3 ? 0 : 3,
                                          ),
                                          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
                                          decoration: BoxDecoration(
                                            color: Colors.white.withValues(alpha: 0.02),
                                            borderRadius: BorderRadius.circular(12),
                                            border: Border.all(color: Colors.white.withValues(alpha: 0.04)),
                                          ),
                                          child: Column(
                                            children: [
                                              Container(
                                                width: 32,
                                                height: 32,
                                                decoration: BoxDecoration(
                                                  color: currentColor,
                                                  shape: BoxShape.circle,
                                                  border: Border.all(
                                                    color: index == 0 ? Colors.white30 : Colors.transparent,
                                                    width: 0.8,
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(height: 6),
                                              Text(
                                                roleLabel,
                                                style: const TextStyle(
                                                  fontFamily: 'KleeOne',
                                                  fontSize: 6.8,
                                                  fontWeight: FontWeight.w900,
                                                  color: Colors.white38,
                                                  letterSpacing: 0.3,
                                                ),
                                                textAlign: TextAlign.center,
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    );
                                  }),
                                ),
                              ],
                            ),
                          ),
                        ],
                      );
                    },
                  ),

                  const SizedBox(height: 24),

                  // FONT POOL
                  Row(
                    children: [
                      const Text(
                        'FONT POOL',
                        style: TextStyle(
                          fontFamily: 'KleeOne',
                          color: Colors.white38,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.0,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${_selectedFonts.length} active',
                        style: TextStyle(
                          fontFamily: 'KleeOne',
                          color: Colors.deepPurpleAccent.withValues(alpha: 0.7),
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Spacer(),
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            if (_selectedFonts.length == widget.allFonts.length) {
                              _selectedFonts = selectedPreset.fontPool.toSet();
                            } else {
                              _selectedFonts = widget.allFonts.toSet();
                            }
                          });
                        },
                        child: Text(
                          _selectedFonts.length == widget.allFonts.length ? 'RESET' : 'SELECT ALL',
                          style: const TextStyle(
                            fontFamily: 'KleeOne',
                            color: Colors.deepPurpleAccent,
                            fontSize: 9.5,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  
                  // Font Chips Wrap
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF13131A),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.03)),
                    ),
                    child: Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: widget.allFonts.map((font) {
                        final isSelected = _selectedFonts.contains(font);
                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              if (isSelected && _selectedFonts.length > 1) {
                                _selectedFonts.remove(font);
                              } else {
                                _selectedFonts.add(font);
                              }
                            });
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 150),
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? Colors.deepPurpleAccent.withValues(alpha: 0.15)
                                  : Colors.white.withValues(alpha: 0.02),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: isSelected
                                    ? Colors.deepPurpleAccent.withValues(alpha: 0.4)
                                    : Colors.white10,
                              ),
                            ),
                            child: Text(
                              font,
                              style: TextStyle(
                                fontFamily: font,
                                color: isSelected ? Colors.white : Colors.white54,
                                fontSize: 10.5,
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // FONT SIZE RANGE SLIDER
                  Row(
                    children: [
                      const Text(
                        'FONT SIZE RANGE',
                        style: TextStyle(
                          fontFamily: 'KleeOne',
                          color: Colors.white38,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.0,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        '${_minFontSize.toInt()}px - ${_maxFontSize.toInt()}px',
                        style: const TextStyle(
                          fontFamily: 'KleeOne',
                          color: Colors.deepPurpleAccent,
                          fontSize: 9.5,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      trackHeight: 2,
                      rangeThumbShape: const RoundRangeSliderThumbShape(enabledThumbRadius: 6),
                      overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
                    ),
                    child: RangeSlider(
                      values: RangeValues(_minFontSize, _maxFontSize),
                      min: 10.0,
                      max: 150.0,
                      divisions: 140,
                      activeColor: Colors.deepPurpleAccent,
                      inactiveColor: Colors.white10,
                      onChanged: (values) {
                        setState(() {
                          _minFontSize = values.start;
                          _maxFontSize = values.end;
                        });
                      },
                    ),
                  ),


                  const SizedBox(height: 24),
                  
                  // SCALE RANGE SLIDER
                  Row(
                    children: [
                      const Text(
                        'SCALE RANGE',
                        style: TextStyle(
                          fontFamily: 'KleeOne',
                          color: Colors.white38,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.0,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        '${_minScale.toStringAsFixed(2)}x - ${_maxScale.toStringAsFixed(2)}x',
                        style: const TextStyle(
                          fontFamily: 'KleeOne',
                          color: Colors.deepPurpleAccent,
                          fontSize: 9.5,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      trackHeight: 2,
                      rangeThumbShape: const RoundRangeSliderThumbShape(enabledThumbRadius: 6),
                      overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
                    ),
                    child: RangeSlider(
                      values: RangeValues(_minScale, _maxScale),
                      min: 0.1,
                      max: 4.0,
                      divisions: 39,
                      activeColor: Colors.deepPurpleAccent,
                      inactiveColor: Colors.white10,
                      onChanged: (values) {
                        setState(() {
                          _minScale = values.start;
                          _maxScale = values.end;
                        });
                      },
                    ),
                  ),

                  const SizedBox(height: 24),

                  
                  // ROTATION MODE
                  Row(
                    children: [
                      const Text(
                        'ROTATION MODE',
                        style: TextStyle(
                          fontFamily: 'KleeOne',
                          color: Colors.white38,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.0,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      _buildRotationModeChip(RotationMode.none, 'NONE', Icons.block),
                      const SizedBox(width: 8),
                      _buildRotationModeChip(RotationMode.random, 'RANDOM', Icons.shuffle),
                      const SizedBox(width: 8),
                      _buildRotationModeChip(RotationMode.orthogonal, 'ORTHOGONAL', Icons.screen_rotation),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // TECHNICAL PRESET DETAILS MATRIX
                  const Text(
                    'PRESET TECHNICAL MATRIX',
                    style: TextStyle(
                      fontFamily: 'KleeOne',
                      color: Colors.white38,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.0,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF13131A),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.03)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              selectedPreset.icon,
                              style: const TextStyle(fontSize: 14),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              selectedPreset.name.toUpperCase(),
                              style: const TextStyle(
                                fontFamily: 'KleeOne',
                                color: Colors.white,
                                fontSize: 11.5,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.0,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        const Divider(color: Colors.white10, height: 1),
                        const SizedBox(height: 12),
                        
                        _matrixDetail(Icons.layers_rounded, 'Layout', selectedPreset.layoutPreset.name.toUpperCase()),
                        _matrixDetail(Icons.text_fields_rounded, 'Font Size', '${_minFontSize.toInt()}-${_maxFontSize.toInt()}px'),
                        _matrixDetail(Icons.zoom_out_map_rounded, 'Scale Range', '${_minScale.toStringAsFixed(1)}x - ${_maxScale.toStringAsFixed(1)}x'),
                        _matrixDetail(Icons.rotate_right_rounded, 'Max Rotate', selectedPreset.maxRotation > 0 ? '±${selectedPreset.maxRotation}°' : '0°'),
                        _matrixDetail(Icons.star_half_rounded, 'FX Layer', [
                          if (_enableStroke) 'Stroke',
                          if (selectedPreset.enableShadow) 'Shadow',
                          if (_enableGlow) 'Glow',
                        ].join(', ')),
                        _matrixDetail(Icons.movie_filter_rounded, 'Animations', '${selectedPreset.entrancePool.length} Entrance / ${selectedPreset.exitPool.length} Exit'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 80),
                ],
              ),
            ),
          ),

          // Floating Apply Action Button Area
          Container(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
            decoration: BoxDecoration(
              color: const Color(0xFF0A0A0F),
              border: Border(top: BorderSide(color: Colors.white.withValues(alpha: 0.05))),
            ),
            child: SafeArea(
              child: Container(
                width: double.infinity,
                height: 48,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  gradient: const LinearGradient(
                    colors: [
                      Colors.deepPurple,
                      Colors.indigoAccent,
                    ],
                  ),
                ),
                child: ElevatedButton(
                  onPressed: () {
                    AdService.instance.showAutoKineticRewardAd(
                      onRewardEarned: () {
                        // Persist session parameters
                        _rememberedPresetIndices = _selectedPresetIndices;
                        _rememberedMixedMode = _isMixedMode;
                        _rememberedDoBurst = _doBurst;
                        _rememberedFonts = _selectedFonts;
                        _rememberedStroke = _enableStroke;
                        _rememberedGlow = _enableGlow;
                        _rememberedEntrancePool = _selectedEntrancePool;
                        _rememberedExitPool = _selectedExitPool;
                        _rememberedEnableEntrance = _enableEntranceAnimation;
                        _rememberedEnableExit = _enableExitAnimation;
                        _rememberedMinFontSize = _minFontSize;
                        _rememberedMaxFontSize = _maxFontSize;
                        _rememberedRotationMode = _rotationMode;
                        _rememberedMinScale = _minScale;
                        _rememberedMaxScale = _maxScale;
                        _rememberedTextColors = _selectedTextColors;
                        _rememberedBgColor = _selectedBgColor;

                        final styles = _selectedPresetIndices.map((idx) {
                          final p = presets[idx.clamp(0, presets.length - 1)];
                          return p.copyWith(
                            fontPool: _selectedFonts.toList(),
                            minFontSize: _minFontSize,
                            maxFontSize: _maxFontSize,
                            minScale: _minScale,
                            maxScale: _maxScale,
                            rotationMode: _rotationMode,
                            enableStroke: _enableStroke,
                            enableGlow: _enableGlow,
                            enableShadow: _enableGlow,
                            enableEntranceAnimation: _enableEntranceAnimation,
                            enableExitAnimation: _enableExitAnimation,
                            entrancePool: _selectedEntrancePool.isNotEmpty ? _selectedEntrancePool.toList() : p.entrancePool,
                            exitPool: _selectedExitPool.isNotEmpty ? _selectedExitPool.toList() : p.exitPool,
                            colorPalette: _selectedTextColors.toList(),
                          );
                        }).toList();
                        
                        widget.onApply(styles, _doBurst, _selectedBgColor);
                      },
                      onAdDismissed: () {
                        // ad closed
                      },
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.auto_awesome_rounded, size: 18, color: Colors.white),
                      const SizedBox(width: 8),
                      const Text(
                        'APPLY KINETIC AUTOMATION',
                        style: TextStyle(
                          fontFamily: 'KleeOne',
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                          letterSpacing: 1.0,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _matrixDetail(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 13, color: Colors.white30),
          const SizedBox(width: 8),
          SizedBox(
            width: 90,
            child: Text(
              label,
              style: const TextStyle(
                fontFamily: 'KleeOne',
                color: Colors.white38,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontFamily: 'KleeOne',
                color: Colors.white70,
                fontSize: 10,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRotationModeChip(RotationMode mode, String label, IconData icon) {
    final isSelected = _rotationMode == mode;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _rotationMode = mode),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? Colors.deepPurpleAccent.withValues(alpha: 0.15) : Colors.white.withValues(alpha: 0.02),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isSelected ? Colors.deepPurpleAccent.withValues(alpha: 0.5) : Colors.white10,
            ),
          ),
          child: Column(
            children: [
              Icon(icon, size: 16, color: isSelected ? Colors.deepPurpleAccent : Colors.white54),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontFamily: 'KleeOne',
                  color: isSelected ? Colors.white : Colors.white54,
                  fontSize: 9.5,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAnimationPoolSelector(
    String title,
    IconData icon,
    bool isEnabled,
    ValueChanged<bool> onToggle,
    List<AnimationType> availablePool,
    Set<AnimationType> selectedPool,
    VoidCallback onReset,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 16, color: Colors.white54),
            const SizedBox(width: 8),
            Text(
              title,
              style: const TextStyle(
                fontFamily: 'KleeOne',
                color: Colors.white38,
                fontSize: 10,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.0,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '${selectedPool.length} active',
              style: TextStyle(
                fontFamily: 'KleeOne',
                color: Colors.deepPurpleAccent.withValues(alpha: 0.7),
                fontSize: 9,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Spacer(),
            Switch.adaptive(
              value: isEnabled,
              onChanged: onToggle,
              activeColor: Colors.deepPurpleAccent,
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: onReset,
              child: const Text(
                'RESET',
                style: TextStyle(
                  fontFamily: 'KleeOne',
                  color: Colors.deepPurpleAccent,
                  fontSize: 9.5,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFF13131A),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withValues(alpha: 0.03)),
          ),
          child: Wrap(
            spacing: 6,
            runSpacing: 6,
            children: availablePool.map((anim) {
              final isSelected = selectedPool.contains(anim);
              final name = anim.name.replaceAllMapped(RegExp(r'[A-Z]'), (match) => ' ${match.group(0)}').trim();
              return GestureDetector(
                onTap: () {
                  setState(() {
                    if (isSelected) {
                      selectedPool.remove(anim);
                    } else {
                      selectedPool.add(anim);
                    }
                  });
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? Colors.deepPurpleAccent.withValues(alpha: 0.15)
                        : Colors.white.withValues(alpha: 0.02),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isSelected
                          ? Colors.deepPurpleAccent.withValues(alpha: 0.4)
                          : Colors.white10,
                    ),
                  ),
                  child: Text(
                    name.toUpperCase(),
                    style: TextStyle(
                      fontFamily: 'KleeOne',
                      color: isSelected ? Colors.white : Colors.white54,
                      fontSize: 9.5,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}
