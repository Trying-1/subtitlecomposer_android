import 'package:flutter/material.dart';
import '../../../../models/editor_models.dart';
import '../../../../utils/animation_presets.dart';
import '../../../common/custom_color_picker.dart';

class CommonControls {
  static Widget buildSlider(BuildContext context, String label, double value, double min, double max, ValueChanged<double> onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(fontSize: 10, color: Colors.white38)),
            Text(value.toStringAsFixed(value == value.roundToDouble() ? 0 : 2), style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white70)),
          ],
        ),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            trackHeight: 2,
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 5),
            overlayShape: const RoundSliderOverlayShape(overlayRadius: 10),
            activeTrackColor: Colors.deepPurpleAccent,
            inactiveTrackColor: Colors.white10,
            thumbColor: Colors.deepPurpleAccent,
          ),
          child: Slider(
            value: value.clamp(min, max),
            min: min,
            max: max,
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }

  static Widget buildColorPicker(BuildContext context, String label, int current, ValueChanged<int> onChanged) {
    final colors = [
      0xFFFFFFFF, 0xFF000000, 0xFFFF0000, 0xFF00FF00, 
      0xFF0000FF, 0xFFFFFF00, 0xFFFF00FF, 0xFF00FFFF,
      0xFFFF9800, 0xFF9C27B0,
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 10, color: Colors.white38)),
        const SizedBox(height: 12),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              // Custom Color Picker Button (Left-most)
              Padding(
                padding: const EdgeInsets.only(right: 12),
                child: GestureDetector(
                  onTap: () => _showCustomColorPicker(context, Color(current), (newColor) => onChanged(newColor.value)),
                  child: Container(
                    width: 26,
                    height: 26,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.05),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white10, width: 1),
                    ),
                    child: const Icon(Icons.palette_rounded, size: 14, color: Colors.white70),
                  ),
                ),
              ),
              ...colors.map((c) => Padding(
                padding: const EdgeInsets.only(right: 12),
                child: GestureDetector(
                  onTap: () => onChanged(c),
                  child: Container(
                    width: 26,
                    height: 26,
                    decoration: BoxDecoration(
                      color: Color(c),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: current == c ? Colors.deepPurpleAccent : Colors.transparent, 
                        width: 2,
                      ),
                      boxShadow: [
                        if (current == c) BoxShadow(color: Colors.deepPurpleAccent.withOpacity(0.3), blurRadius: 8)
                      ]
                    ),
                  ),
                ),
              )).toList(),
            ],
          ),
        ),
      ],
    );
  }

  static void _showCustomColorPicker(BuildContext context, Color initial, ValueChanged<Color> onColorChanged) {
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

  static Widget buildProjectColorPicker(BuildContext context, String label, int current, ValueChanged<int> onChanged) {
    final colors = [
      0xFFFFFFFF, 0xFF000000, 0xFFF5F5F5, 0xFFE0E0E0,
      0xFFFFEBEE, 0xFFE3F2FD, 0xFFF1F8E9, 0xFFFFF3E0,
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 10, color: Colors.white38)),
        const SizedBox(height: 12),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              // Custom Color Picker Button (Left-most)
              Padding(
                padding: const EdgeInsets.only(right: 12),
                child: GestureDetector(
                  onTap: () => _showCustomColorPicker(context, Color(current), (newColor) => onChanged(newColor.value)),
                  child: Container(
                    width: 26,
                    height: 26,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.05),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white10, width: 1),
                    ),
                    child: const Icon(Icons.palette_rounded, size: 14, color: Colors.white70),
                  ),
                ),
              ),
              ...colors.map((c) => Padding(
                padding: const EdgeInsets.only(right: 12),
                child: GestureDetector(
                  onTap: () => onChanged(c),
                  child: Container(
                    width: 26,
                    height: 26,
                    decoration: BoxDecoration(
                      color: Color(c),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: current == c ? Colors.deepPurpleAccent : Colors.white10, 
                        width: 2,
                      ),
                    ),
                  ),
                ),
              )).toList(),
            ],
          ),
        ),
      ],
    );
  }

  static Widget buildSubTabBar(List<String> labels, int current, ValueChanged<int> onChanged) {
    return Container(
      width: double.infinity,
      height: 28,
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.04),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: List.generate(labels.length, (index) {
          final isSelected = current == index;
          return Expanded(
            child: GestureDetector(
              onTap: () => onChanged(index),
              child: Container(
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: isSelected ? Colors.deepPurpleAccent : Colors.transparent,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  labels[index],
                  style: TextStyle(
                    fontSize: 8.5,
                    fontWeight: FontWeight.w900,
                    color: isSelected ? Colors.white : Colors.white38,
                    letterSpacing: 1.0,
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  static Widget buildSquareActionButton({
    required IconData icon,
    required String label,
    required VoidCallback? onTap,
    Color color = Colors.white,
    bool isPrimary = false,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: isPrimary ? color.withOpacity(0.1) : Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isPrimary ? color.withOpacity(0.4) : Colors.white.withOpacity(0.08),
                width: isPrimary ? 1.5 : 1,
              ),
            ),
            child: Icon(
              icon, 
              size: 22, 
              color: isPrimary ? color : color.withOpacity(0.8),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label.toUpperCase(),
          style: TextStyle(
            fontSize: 7, 
            color: isPrimary ? Colors.white : Colors.white38, 
            fontWeight: FontWeight.w900,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }

  static Widget buildToggle(bool value, ValueChanged<bool> onChanged) {
    return SizedBox(
      height: 20,
      width: 36,
      child: Switch(
        value: value,
        onChanged: onChanged,
        activeColor: Colors.deepPurpleAccent,
        activeTrackColor: Colors.deepPurpleAccent.withOpacity(0.3),
        inactiveThumbColor: Colors.white24,
        inactiveTrackColor: Colors.white10,
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
    );
  }

  static Widget buildTextField(String current, ValueChanged<String> onChanged) {
    return TextField(
      controller: TextEditingController(text: current)..selection = TextSelection.fromPosition(TextPosition(offset: current.length)),
      style: const TextStyle(fontSize: 13, color: Colors.white),
      maxLines: 1,
      onSubmitted: onChanged,
      decoration: InputDecoration(
        hintText: 'Enter text...',
        hintStyle: const TextStyle(color: Colors.white24),
        filled: true,
        fillColor: Colors.white.withOpacity(0.05),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      ),
    );
  }

  static Widget buildFontFamilyDropdown(String current, ValueChanged<String> onChanged, {List<String> customFonts = const []}) {
    final defaultFonts = [
      'Poppins', 'Bellota', 'BhuTukaExpandedOne', 'Bokor', 'BungeeHairline',
      'Caramel', 'Centralwell', 'Chalk Board', 'Eternal', 'Explora',
      'GrandifloraOne', 'KleeOne', 'Lacquer', 'LibreBarcode39Text',
      'LuckiestGuy', 'MajorMonoDisplay', 'Metrophobic', 'Michroma',
      'Milker', 'NCLNeovibes', 'NewRocker', 'NewTegomin', 'ProtestRevolution',
      'RELIGATH', 'akony', 'modernline', 'modernline bold'
    ];
    final allFonts = [...customFonts, ...defaultFonts];
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
      ),
      child: DropdownButton<String>(
        value: allFonts.contains(current) ? current : 'Poppins',
        isExpanded: true,
        dropdownColor: const Color(0xFF1E1E2A),
        style: const TextStyle(fontSize: 12, color: Colors.white70),
        underline: const SizedBox(),
        items: allFonts.map((font) => DropdownMenuItem(value: font, child: Text(font, style: TextStyle(fontFamily: font, fontSize: 11)))).toList(),
        onChanged: (v) => v != null ? onChanged(v) : null,
      ),
    );
  }

  static Widget buildAnimationTypeDropdown(String label, AnimationType current, ValueChanged<AnimationType> onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 10, color: Colors.white38)),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(color: Colors.white.withOpacity(0.05), borderRadius: BorderRadius.circular(8)),
          child: DropdownButton<AnimationType>(
            value: current,
            isExpanded: true,
            dropdownColor: const Color(0xFF1E1E2A),
            style: const TextStyle(fontSize: 12, color: Colors.white70),
            underline: const SizedBox(),
            items: AnimationType.values.map((type) => DropdownMenuItem(value: type, child: Text(AnimationPresets.animationTypeName(type)))).toList(),
            onChanged: (v) => v != null ? onChanged(v) : null,
          ),
        ),
      ],
    );
  }

  static Widget buildEasingDropdown(String label, EasingType current, ValueChanged<EasingType> onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 10, color: Colors.white38)),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(color: Colors.white.withOpacity(0.05), borderRadius: BorderRadius.circular(8)),
          child: DropdownButton<EasingType>(
            value: current,
            isExpanded: true,
            dropdownColor: const Color(0xFF1E1E2A),
            style: const TextStyle(fontSize: 12, color: Colors.white70),
            underline: const SizedBox(),
            items: EasingType.values.map((type) => DropdownMenuItem(value: type, child: Text(AnimationPresets.easingTypeName(type)))).toList(),
            onChanged: (v) => v != null ? onChanged(v) : null,
          ),
        ),
      ],
    );
  }

  static Widget buildFillModeSelector(int current, ValueChanged<int> onChanged) {
    final options = [
      {'val': 0, 'label': 'Cover', 'icon': Icons.fullscreen_rounded},
      {'val': 1, 'label': 'Fit', 'icon': Icons.fullscreen_exit_rounded},
      {'val': 2, 'label': 'Center', 'icon': Icons.center_focus_strong_rounded},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('FILL MODE', style: TextStyle(fontSize: 10, color: Colors.white38)),
        const SizedBox(height: 8),
        Row(
          children: options.map((opt) {
            final isSelected = current == opt['val'];
            return Expanded(
              child: GestureDetector(
                onTap: () => onChanged(opt['val'] as int),
                child: Container(
                  margin: const EdgeInsets.only(right: 8),
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    color: isSelected ? Colors.deepPurpleAccent : Colors.white.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: isSelected ? Colors.deepPurpleAccent : Colors.white10),
                  ),
                  child: Column(
                    children: [
                      Icon(opt['icon'] as IconData, size: 14, color: isSelected ? Colors.white : Colors.white38),
                      const SizedBox(height: 2),
                      Text(opt['label'] as String, style: TextStyle(fontSize: 8, color: isSelected ? Colors.white : Colors.white38, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  static Widget buildQuickRotationControls(double current, ValueChanged<double> onChanged) {
    final values = [-180.0, -90.0, -15.0, 0.0, 15.0, 90.0, 180.0];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: values.map((v) {
          final isIncremental = v.abs() == 15.0;
          final label = isIncremental ? (v > 0 ? '+15°' : '-15°') : '${v > 0 ? "+" : ""}${v.toInt()}°';
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: InkWell(
              onTap: () {
                if (isIncremental) {
                  var newVal = current + v;
                  if (newVal > 180) newVal = -180 + (newVal - 180);
                  if (newVal < -180) newVal = 180 + (newVal + 180);
                  onChanged(newVal.clamp(-180, 180));
                } else {
                  onChanged(v);
                }
              },
              borderRadius: BorderRadius.circular(6),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: Colors.white10),
                ),
                child: Text(
                  label,
                  style: const TextStyle(fontSize: 9, color: Colors.white70, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
