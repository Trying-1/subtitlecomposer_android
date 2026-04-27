import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class CustomColorPicker extends StatefulWidget {
  final Color initialColor;
  final ValueChanged<Color> onColorChanged;

  const CustomColorPicker({
    super.key,
    required this.initialColor,
    required this.onColorChanged,
  });

  @override
  State<CustomColorPicker> createState() => _CustomColorPickerState();
}

class _CustomColorPickerState extends State<CustomColorPicker> {
  late HSVColor _hsvColor;
  late TextEditingController _hexController;
  late TextEditingController _rController;
  late TextEditingController _gController;
  late TextEditingController _bController;
  late TextEditingController _aController;

  @override
  void initState() {
    super.initState();
    _hsvColor = HSVColor.fromColor(widget.initialColor);
    _hexController = TextEditingController(text: _colorToHex(widget.initialColor));
    _rController = TextEditingController(text: widget.initialColor.red.toString());
    _gController = TextEditingController(text: widget.initialColor.green.toString());
    _bController = TextEditingController(text: widget.initialColor.blue.toString());
    _aController = TextEditingController(text: widget.initialColor.alpha.toString());
  }

  @override
  void dispose() {
    _hexController.dispose();
    _rController.dispose();
    _gController.dispose();
    _bController.dispose();
    _aController.dispose();
    super.dispose();
  }

  String _colorToHex(Color color) {
    return color.value.toRadixString(16).padLeft(8, '0').toUpperCase();
  }

  void _updateFromColor(Color color, {bool updateControllers = true}) {
    setState(() {
      _hsvColor = HSVColor.fromColor(color);
      if (updateControllers) {
        _hexController.text = _colorToHex(color);
        _rController.text = color.red.toString();
        _gController.text = color.green.toString();
        _bController.text = color.blue.toString();
        _aController.text = color.alpha.toString();
      }
    });
    widget.onColorChanged(color);
  }

  void _onHexChanged(String value) {
    if (value.length == 8) {
      try {
        final color = Color(int.parse(value, radix: 16));
        _updateFromColor(color, updateControllers: false);
        _rController.text = color.red.toString();
        _gController.text = color.green.toString();
        _bController.text = color.blue.toString();
        _aController.text = color.alpha.toString();
      } catch (_) {}
    }
  }

  void _onRGBAChanged() {
    final r = int.tryParse(_rController.text) ?? 0;
    final g = int.tryParse(_gController.text) ?? 0;
    final b = int.tryParse(_bController.text) ?? 0;
    final a = int.tryParse(_aController.text) ?? 255;
    final color = Color.fromARGB(a.clamp(0, 255), r.clamp(0, 255), g.clamp(0, 255), b.clamp(0, 255));
    _updateFromColor(color, updateControllers: false);
    _hexController.text = _colorToHex(color);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: const BoxDecoration(
        color: Color(0xFF111116),
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Visual Selection (Left)
              Expanded(
                flex: 4,
                child: Column(
                  children: [
                    _buildSaturationValueBoxBetter(),
                    const SizedBox(height: 12),
                    _buildHueSliderHorizontal(),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              // Inputs (Right)
              Expanded(
                flex: 3,
                child: Column(
                  children: [
                    _buildCompactField('HEX', _hexController, isHex: true),
                    const SizedBox(height: 6),
                    _buildCompactField('R', _rController, isNumeric: true),
                    const SizedBox(height: 6),
                    _buildCompactField('G', _gController, isNumeric: true),
                    const SizedBox(height: 6),
                    _buildCompactField('B', _bController, isNumeric: true),
                    const SizedBox(height: 6),
                    _buildCompactField('A', _aController, isNumeric: true),
                  ],
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 12),
          // Actions
          Row(
            children: [
              Expanded(
                child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('CANCEL', style: TextStyle(fontSize: 10, color: Colors.white24)),
                ),
              ),
              Expanded(
                flex: 2,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepPurpleAccent,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                  ),
                  child: const Text('CONFIRM', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSaturationValueBoxBetter() {
    return AspectRatio(
      aspectRatio: 1.0, // More compact square
      child: LayoutBuilder(
        builder: (context, constraints) {
          final size = Size(constraints.maxWidth, constraints.maxHeight);
          return GestureDetector(
            onPanUpdate: (details) => _updateSaturationValue(details.localPosition, size),
            onPanDown: (details) => _updateSaturationValue(details.localPosition, size),
            child: Stack(
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: HSVColor.fromAHSV(1.0, _hsvColor.hue, 1.0, 1.0).toColor(),
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    gradient: const LinearGradient(
                      colors: [Colors.white, Colors.transparent],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    ),
                  ),
                ),
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    gradient: const LinearGradient(
                      colors: [Colors.transparent, Colors.black],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                ),
                Positioned(
                  left: (_hsvColor.saturation * size.width).clamp(0, size.width) - 8,
                  top: ((1 - _hsvColor.value) * size.height).clamp(0, size.height) - 8,
                  child: Container(
                    width: 16,
                    height: 16,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.5), blurRadius: 4)],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildHueSliderHorizontal() {
    return LayoutBuilder(builder: (context, constraints) {
      const margin = 8.0;
      final width = constraints.maxWidth - (margin * 2);
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: margin),
        child: GestureDetector(
          onPanUpdate: (details) => _updateHueHorizontal(details.localPosition.dx, width),
          onPanDown: (details) => _updateHueHorizontal(details.localPosition.dx, width),
          child: Container(
            height: 12,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(6),
              gradient: const LinearGradient(
                colors: [
                  Color(0xFFFF0000), Color(0xFFFFFF00), Color(0xFF00FF00),
                  Color(0xFF00FFFF), Color(0xFF0000FF), Color(0xFFFF00FF),
                  Color(0xFFFF0000)
                ],
              ),
            ),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Positioned(
                  left: (_hsvColor.hue / 360 * width).clamp(0, width) - 6,
                  child: Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 4)],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    });
  }

  void _updateHueHorizontal(double dx, double width) {
    final h = (dx / width).clamp(0.0, 1.0) * 360;
    _updateFromColor(_hsvColor.withHue(h).toColor());
  }

  void _updateSaturationValue(Offset pos, Size size) {
    final s = (pos.dx / size.width).clamp(0.0, 1.0);
    final v = (1.0 - (pos.dy / size.height)).clamp(0.0, 1.0);
    _updateFromColor(_hsvColor.withSaturation(s).withValue(v).toColor());
  }

  Widget _buildCompactField(String label, TextEditingController controller, {bool isHex = false, bool isNumeric = false}) {
    return Row(
      children: [
        SizedBox(
          width: 24,
          child: Text(label, style: const TextStyle(color: Colors.white24, fontSize: 8, fontWeight: FontWeight.bold)),
        ),
        const SizedBox(width: 4),
        Expanded(
          child: TextField(
            controller: controller,
            onChanged: (v) => isHex ? _onHexChanged(v) : _onRGBAChanged(),
            keyboardType: isNumeric ? TextInputType.number : TextInputType.text,
            maxLines: 1,
            inputFormatters: [
              if (isNumeric) FilteringTextInputFormatter.digitsOnly,
              if (isNumeric) LengthLimitingTextInputFormatter(3),
              if (isHex) LengthLimitingTextInputFormatter(8),
              if (isHex) FilteringTextInputFormatter.allow(RegExp(r'[0-9a-fA-F]')),
            ],
            style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
            decoration: InputDecoration(
              filled: true,
              fillColor: Colors.white.withOpacity(0.05),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(4), borderSide: BorderSide.none),
              contentPadding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
              isDense: true,
            ),
          ),
        ),
      ],
    );
  }
}
