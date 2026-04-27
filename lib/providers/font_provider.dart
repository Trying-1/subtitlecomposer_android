import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path/path.dart' as p;
import '../services/native_bridge.dart';

class CustomFont {
  final String family;
  final String path;

  CustomFont({required this.family, required this.path});

  Map<String, dynamic> toJson() => {'family': family, 'path': path};
  factory CustomFont.fromJson(Map<dynamic, dynamic> json) => CustomFont(
    family: json['family'] as String,
    path: json['path'] as String,
  );
}

class FontProvider extends ChangeNotifier {
  final List<CustomFont> _customFonts = [];
  final NativeBridge _bridge = NativeBridge();
  late Box _fontBox;
  bool _isInitialized = false;

  List<CustomFont> get customFonts => List.unmodifiable(_customFonts);
  bool get isInitialized => _isInitialized;

  Future<void> init() async {
    if (_isInitialized) return;
    
    _fontBox = Hive.box('font_box');
    final savedFonts = _fontBox.get('fonts', defaultValue: []) as List;
    
    for (var f in savedFonts) {
      final font = CustomFont.fromJson(f as Map);
      if (File(font.path).existsSync()) {
        _customFonts.add(font);
        await _loadFontToFlutter(font);
        await _bridge.registerFont(font.family, font.path);
      }
    }
    
    _isInitialized = true;
    notifyListeners();
  }

  Future<void> importFont(String sourcePath) async {
    final fileName = p.basename(sourcePath);
    final family = p.basenameWithoutExtension(sourcePath).replaceAll(RegExp(r'[^a-zA-Z0-9]'), '');
    
    // Check if already exists
    if (_customFonts.any((f) => f.family == family)) {
      return; // Already imported or same family name
    }

    final appDocDir = await getApplicationDocumentsDirectory();
    final fontsDir = Directory(p.join(appDocDir.path, 'fonts'));
    if (!fontsDir.existsSync()) {
      fontsDir.createSync();
    }

    final targetPath = p.join(fontsDir.path, fileName);
    await File(sourcePath).copy(targetPath);

    final newFont = CustomFont(family: family, path: targetPath);
    _customFonts.add(newFont);
    
    await _loadFontToFlutter(newFont);
    await _bridge.registerFont(newFont.family, newFont.path);
    await _persistFonts();
    
    notifyListeners();
  }

  Future<void> _loadFontToFlutter(CustomFont font) async {
    final fontData = await File(font.path).readAsBytes();
    final fontLoader = FontLoader(font.family);
    fontLoader.addFont(Future.value(ByteData.view(fontData.buffer)));
    await fontLoader.load();
  }

  Future<void> _persistFonts() async {
    await _fontBox.put('fonts', _customFonts.map((f) => f.toJson()).toList());
  }

  Future<void> deleteFont(CustomFont font) async {
    _customFonts.removeWhere((f) => f.family == font.family);
    final file = File(font.path);
    if (file.existsSync()) {
      await file.delete();
    }
    await _persistFonts();
    notifyListeners();
    // Note: Flutter doesn't support easy "unloading" of fonts, but it won't be in our list.
  }
}
