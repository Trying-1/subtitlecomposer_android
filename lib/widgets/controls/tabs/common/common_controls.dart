import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../models/editor_models.dart';
import '../../../../utils/animation_presets.dart';
import '../../../../providers/asset_provider.dart';
import '../../../common/custom_color_picker.dart';

class CommonControls {
  static Widget buildSlider(BuildContext context, String label, double value, double min, double max, ValueChanged<double> onChanged, {VoidCallback? onReset}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Text(label, style: const TextStyle(fontSize: 10, color: Colors.white38)),
                if (onReset != null) ...[
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: onReset,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Icon(Icons.refresh_rounded, size: 10, color: Colors.deepPurpleAccent),
                    ),
                  ),
                ],
              ],
            ),
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
                      borderRadius: BorderRadius.circular(6),
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
                      borderRadius: BorderRadius.circular(6),
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

  static final List<ColorPalette> premiumPalettes = [
    ColorPalette(id: 'luxury_gold', name: 'Classic Gold & Black', colors: [0xFF000000, 0xFFD4AF37, 0xFFFFFFFF, 0xFFC5A028, 0xFF1A1A1A]),
    ColorPalette(id: 'royal_velvet', name: 'Royal Velvet', colors: [0xFF2D0A31, 0xFFFFFFFF, 0xFF8105D8, 0xFFC0C0C0, 0xFF4A0E4E]),
    ColorPalette(id: 'emerald_elite', name: 'Emerald & Gold', colors: [0xFF043927, 0xFFD4AF37, 0xFFFFFFFF, 0xFFF5F5F5, 0xFF0B6623]),
    ColorPalette(id: 'midnight_silver', name: 'Midnight Luxe', colors: [0xFF0F0F13, 0xFFFFFFFF, 0xFFBDBDBD, 0xFF4A4A4A, 0xFF1C1C21]),
    ColorPalette(id: 'rose_quartz', name: 'Champagne Rose', colors: [0xFF2D1B22, 0xFFF7E7CE, 0xFFB76E79, 0xFFFFFFFF, 0xFFD4AF37]),
    ColorPalette(id: 'ocean_pearl', name: 'Deep Sea Pearl', colors: [0xFF002366, 0xFFFFFFFF, 0xFFE0E0E0, 0xFF0055D4, 0xFF003399]),
  ];

  static Widget buildPalettesOnly(BuildContext context, int current, ValueChanged<int> onChanged) {
    return Consumer<AssetProvider>(
      builder: (context, assetProvider, child) {
        final allPalettes = [...premiumPalettes, ...assetProvider.palettes];

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('PREMIUM PALETTES', style: TextStyle(fontSize: 8, color: Colors.amberAccent, fontWeight: FontWeight.w900, letterSpacing: 0.8)),
            const SizedBox(height: 16),
            ...allPalettes.map((palette) {
              final isPremium = premiumPalettes.contains(palette);
              return Padding(
                padding: const EdgeInsets.only(bottom: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(palette.name.toUpperCase(), style: TextStyle(fontSize: 8, color: isPremium ? Colors.amberAccent.withOpacity(0.5) : Colors.white38, fontWeight: FontWeight.bold)),
                        if (isPremium) ...[
                          const SizedBox(width: 6),
                          const Icon(Icons.stars_rounded, size: 8, color: Colors.amberAccent),
                        ],
                      ],
                    ),
                    const SizedBox(height: 10),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: palette.colors.map((c) => Padding(
                          padding: const EdgeInsets.only(right: 12),
                          child: GestureDetector(
                            onTap: () => onChanged(c),
                            child: Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color: Color(c),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: current == c ? Colors.deepPurpleAccent : Colors.white10, 
                                  width: 2,
                                ),
                                boxShadow: [
                                  if (current == c) BoxShadow(color: Colors.deepPurpleAccent.withOpacity(0.3), blurRadius: 10)
                                ],
                              ),
                            ),
                          ),
                        )).toList(),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ],
        );
      }
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
      0xFFFFFFFF, 0xFF000000, 0xFFFF0000, 0xFF00FF00, 
      0xFF0000FF, 0xFFFFFF00, 0xFFFF00FF, 0xFF00FFFF,
    ];

    return Consumer<AssetProvider>(
      builder: (context, assetProvider, child) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(fontSize: 10, color: Colors.white38, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                   // Custom Color Picker Button
                  Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: GestureDetector(
                      onTap: () => _showCustomColorPicker(context, Color(current), (newColor) => onChanged(newColor.value)),
                      child: Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: Colors.white10, width: 1),
                        ),
                        child: const Icon(Icons.palette_rounded, size: 14, color: Colors.white70),
                      ),
                    ),
                  ),
                  ...colors.map((c) => Padding(
                    padding: const EdgeInsets.only(right: 10),
                    child: GestureDetector(
                      onTap: () => onChanged(c),
                      child: Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: Color(c),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: current == c ? Colors.deepPurpleAccent : Colors.white10, 
                            width: 1.5,
                          ),
                        ),
                      ),
                    ),
                  )).toList(),
                ],
              ),
            ),
            
            if (assetProvider.palettes.isNotEmpty) ...[
              const SizedBox(height: 16),
              const Text('PROJECT PALETTES', style: TextStyle(fontSize: 7, color: Colors.white24, fontWeight: FontWeight.w900)),
              const SizedBox(height: 10),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: assetProvider.palettes.expand((palette) => palette.colors.map((c) => Padding(
                    padding: const EdgeInsets.only(right: 10),
                    child: GestureDetector(
                      onTap: () => onChanged(c),
                      child: Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          color: Color(c),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: current == c ? Colors.deepPurpleAccent : Colors.white10, 
                            width: 1.5,
                          ),
                        ),
                      ),
                    ),
                  ))).toList(),
                ),
              ),
            ],
          ],
        );
      }
    );
  }

  static Widget buildSubTabBar(List<String> labels, int current, ValueChanged<int> onChanged) {
    return Container(
      width: double.infinity,
      height: 30,
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
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: EdgeInsets.only(right: index == labels.length - 1 ? 0 : 4),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: isSelected ? Colors.deepPurpleAccent : Colors.transparent,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  labels[index],
                  style: TextStyle(
                    fontSize: 8,
                    fontWeight: FontWeight.w900,
                    color: isSelected ? Colors.white : Colors.white38,
                    letterSpacing: 0.8,
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
    IconData? icon,
    required String label,
    required VoidCallback? onTap,
    Color color = Colors.white,
    bool isPrimary = false,
    Widget? child,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: isPrimary ? color.withOpacity(0.1) : Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: isPrimary ? color.withOpacity(0.4) : Colors.white.withOpacity(0.08),
                width: isPrimary ? 1.5 : 1,
              ),
            ),
            child: Center(
              child: child ?? (icon != null ? Icon(
                icon, 
                size: 18, 
                color: isPrimary ? color : color.withOpacity(0.8),
              ) : const SizedBox()),
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          label.toUpperCase(),
          style: TextStyle(
            fontSize: 6.5, 
            color: isPrimary ? Colors.white : Colors.white38, 
            fontWeight: FontWeight.w900,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }

  static Widget buildToggleRow(String label, bool value, ValueChanged<bool> onChanged) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 10, color: Colors.white38)),
          buildToggle(value, onChanged),
        ],
      ),
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
      {'val': 3, 'label': 'Width', 'icon': Icons.swap_horiz_rounded},
      {'val': 4, 'label': 'Height', 'icon': Icons.swap_vert_rounded},
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
    final values = [0.0, 15.0, 45.0];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: values.map((v) {
          final isReset = v == 0.0;
          final label = isReset ? '0°' : '+${v.toInt()}°';
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: InkWell(
              onTap: () {
                if (isReset) {
                  onChanged(0.0);
                } else {
                  var newVal = current + v;
                  // Wrap around logic
                  while (newVal > 180) newVal -= 360;
                  while (newVal < -180) newVal += 360;
                  onChanged(newVal);
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
  static Widget buildDialScrubber(BuildContext context, String label, double value, double min, double max, ValueChanged<double> onChanged, {VoidCallback? onReset}) {
    return _DialScrubber(
      label: label,
      value: value,
      min: min,
      max: max,
      onChanged: onChanged,
      onReset: onReset,
    );
  }
}

class _DialScrubber extends StatefulWidget {
  final String label;
  final double value;
  final double min;
  final double max;
  final ValueChanged<double> onChanged;
  final VoidCallback? onReset;

  const _DialScrubber({
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
    this.onReset,
  });

  @override
  State<_DialScrubber> createState() => _DialScrubberState();
}

class _DialScrubberState extends State<_DialScrubber> {
  double _dragStartValue = 0;
  double _dragStartX = 0;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Text(widget.label, style: const TextStyle(fontSize: 10, color: Colors.white38)),
                if (widget.onReset != null) ...[
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: widget.onReset,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Icon(Icons.refresh_rounded, size: 10, color: Colors.deepPurpleAccent),
                    ),
                  ),
                ],
              ],
            ),
            Text(widget.value.toStringAsFixed(2), style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white70)),
          ],
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onPanStart: (details) {
            _dragStartValue = widget.value;
            _dragStartX = details.localPosition.dx;
          },
          onPanUpdate: (details) {
            final dx = details.localPosition.dx - _dragStartX;
            // Sensitivity: 200px = full range or a fixed amount?
            // For scale, maybe 100px = 1.0 change
            final range = widget.max - widget.min;
            final delta = (dx / 150.0) * (range * 0.2); // 20% of range per 150px
            final newValue = (_dragStartValue + delta).clamp(widget.min, widget.max);
            widget.onChanged(newValue);
          },
          child: Container(
            height: 32,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.03),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: Colors.white.withOpacity(0.05)),
            ),
            child: CustomPaint(
              painter: DialPainter(
                value: widget.value,
                min: widget.min,
                max: widget.max,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class DialPainter extends CustomPainter {
  final double value;
  final double min;
  final double max;

  DialPainter({required this.value, required this.min, required this.max});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white24
      ..strokeWidth = 1;

    final double width = size.width;
    final double height = size.height;
    final double midX = width / 2;
    
    // We want to show ticks that "move" as the value changes
    // Calculate an offset based on the value
    final range = max - min;
    final normalizedValue = (value - min) / range;
    final offset = normalizedValue * 500; // 500 is an arbitrary factor for "scroll speed" of ticks

    final int tickCount = 40;
    final double spacing = 15.0;
    
    for (int i = -tickCount; i <= tickCount; i++) {
      final x = midX + (i * spacing) - (offset % spacing);
      if (x < 0 || x > width) continue;
      
      final isMajor = (i + (offset / spacing).floor()) % 5 == 0;
      final tickHeight = isMajor ? height * 0.5 : height * 0.25;
      paint.color = isMajor ? Colors.white38 : Colors.white10;
      
      canvas.drawLine(
        Offset(x, (height - tickHeight) / 2),
        Offset(x, (height + tickHeight) / 2),
        paint,
      );
    }

    // Center indicator
    final indicatorPaint = Paint()
      ..color = Colors.deepPurpleAccent
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    
    canvas.drawLine(
      Offset(midX, height * 0.1),
      Offset(midX, height * 0.9),
      indicatorPaint,
    );
  }

  @override
  bool shouldRepaint(covariant DialPainter oldDelegate) => oldDelegate.value != value;
}
