import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/editor_models.dart';
import 'package:uuid/uuid.dart';

class AssetProvider extends ChangeNotifier {
  List<String> _overlayAssets = [];
  List<String> _backgroundAssets = [];
  List<String> _audioAssets = [];
  List<String> _musicAssets = [];
  List<String> _sfxAssets = [];
  List<ColorPalette> _palettes = [];
  Map<String, String> _customNames = {};
  bool _isInitialized = false;

  List<String> get assets => _overlayAssets; 
  List<String> get overlayAssets => _overlayAssets;
  List<String> get backgroundAssets => _backgroundAssets;
  List<String> get audioAssets => _audioAssets;
  List<String> get musicAssets => _musicAssets;
  List<String> get sfxAssets => _sfxAssets;
  List<ColorPalette> get palettes => _palettes;

  AssetProvider();

  String getAssetName(String path) {
    return _customNames[path] ?? path.split('/').last;
  }

  Future<void> init() async {
    if (_isInitialized) return;
    try {
      final box = await Hive.openBox('asset_box');
      
      final overlayData = box.get('overlay_assets');
      if (overlayData != null) _overlayAssets = List<String>.from(overlayData);

      final backgroundData = box.get('background_assets');
      if (backgroundData != null) _backgroundAssets = List<String>.from(backgroundData);

      final audioData = box.get('audio_assets');
      if (audioData != null) _audioAssets = List<String>.from(audioData);

      final musicData = box.get('music_assets');
      if (musicData != null) _musicAssets = List<String>.from(musicData);

      final sfxData = box.get('sfx_assets');
      if (sfxData != null) _sfxAssets = List<String>.from(sfxData);

      // Migrating old flat audio list to music/sfx split
      if (_musicAssets.isEmpty && _sfxAssets.isEmpty && _audioAssets.isNotEmpty) {
        for (var path in _audioAssets) {
          final pathLower = path.toLowerCase();
          if (pathLower.contains('/sfx/') || pathLower.contains('/effects/') || pathLower.contains('sfx_') || pathLower.contains('sfx')) {
            _sfxAssets.add(path);
          } else {
            _musicAssets.add(path);
          }
        }
        _persistAssets();
      }

      final palettesData = box.get('palettes');
      if (palettesData != null) {
        _palettes = (palettesData as List).map((p) => ColorPalette.fromJson(Map<String, dynamic>.from(p))).toList();
      }

      final namesData = box.get('custom_names');
      if (namesData != null) {
        _customNames = Map<String, String>.from(namesData);
      }
    } catch (e) {
      print("Error loading assets: $e");
    } finally {
      _isInitialized = true;
      notifyListeners();
    }
  }

  void renameAsset(String path, String newName) {
    if (!_isInitialized) return;
    _customNames[path] = newName;
    _persistAssets();
    notifyListeners();
  }

  void updateAssetPath(String oldPath, String newPath) {
    if (!_isInitialized) return;
    final index = _overlayAssets.indexOf(oldPath);
    if (index != -1) {
      _overlayAssets[index] = newPath;
      if (_customNames.containsKey(oldPath)) {
        _customNames[newPath] = _customNames.remove(oldPath)!;
      }
      _persistAssets();
      notifyListeners();
    }
  }

  void addAssets(List<String> paths) {
    if (!_isInitialized) return;
    bool changed = false;
    for (var path in paths) {
      if (!_overlayAssets.contains(path)) {
        _overlayAssets.add(path);
        changed = true;
      }
    }
    if (changed) {
      _persistAssets();
      notifyListeners();
    }
  }

  void addBackgroundAssets(List<String> paths) {
    if (!_isInitialized) return;
    bool changed = false;
    for (var path in paths) {
      if (!_backgroundAssets.contains(path)) {
        _backgroundAssets.add(path);
        changed = true;
      }
    }
    if (changed) {
      _persistAssets();
      notifyListeners();
    }
  }

  void addAudioAssets(List<String> paths) {
    if (!_isInitialized) return;
    bool changed = false;
    for (var path in paths) {
      if (!_audioAssets.contains(path)) {
        _audioAssets.add(path);
        changed = true;
      }
    }
    if (changed) {
      _persistAssets();
      notifyListeners();
    }
  }

  void addMusicAssets(List<String> paths) {
    if (!_isInitialized) return;
    bool changed = false;
    for (var path in paths) {
      if (!_musicAssets.contains(path)) {
        _musicAssets.add(path);
        changed = true;
      }
      // Also update master list for backward compatibility
      if (!_audioAssets.contains(path)) {
        _audioAssets.add(path);
      }
    }
    if (changed) {
      _persistAssets();
      notifyListeners();
    }
  }

  void addSfxAssets(List<String> paths) {
    if (!_isInitialized) return;
    bool changed = false;
    for (var path in paths) {
      if (!_sfxAssets.contains(path)) {
        _sfxAssets.add(path);
        changed = true;
      }
      // Also update master list for backward compatibility
      if (!_audioAssets.contains(path)) {
        _audioAssets.add(path);
      }
    }
    if (changed) {
      _persistAssets();
      notifyListeners();
    }
  }

  void savePalette(String name, List<int> colors) {
    if (!_isInitialized) return;
    final palette = ColorPalette(
      id: const Uuid().v4(),
      name: name,
      colors: colors,
    );
    _palettes.add(palette);
    _persistAssets();
    notifyListeners();
  }

  int importPalettes(List<ColorPalette> imported) {
    if (!_isInitialized) return 0;
    int importedCount = 0;
    for (var palette in imported) {
      final bool exists = _palettes.any((p) {
        if (p.name.toLowerCase() != palette.name.toLowerCase()) return false;
        if (p.colors.length != palette.colors.length) return false;
        for (int i = 0; i < p.colors.length; i++) {
          if (p.colors[i] != palette.colors[i]) return false;
        }
        return true;
      });

      if (!exists) {
        _palettes.add(ColorPalette(
          id: const Uuid().v4(),
          name: palette.name,
          colors: palette.colors,
        ));
        importedCount++;
      }
    }
    if (importedCount > 0) {
      _persistAssets();
      notifyListeners();
    }
    return importedCount;
  }

  void deletePalette(String id) {
    if (!_isInitialized) return;
    _palettes.removeWhere((p) => p.id == id);
    _persistAssets();
    notifyListeners();
  }

  void updatePalette(String id, {String? name, List<int>? colors}) {
    if (!_isInitialized) return;
    final index = _palettes.indexWhere((p) => p.id == id);
    if (index != -1) {
      _palettes[index] = ColorPalette(
        id: id,
        name: name ?? _palettes[index].name,
        colors: colors ?? _palettes[index].colors,
      );
      _persistAssets();
      notifyListeners();
    }
  }

  void removeAsset(String path) {
    if (!_isInitialized) return;
    if (_overlayAssets.contains(path)) {
      _overlayAssets.remove(path);
      _customNames.remove(path);
      _persistAssets();
      notifyListeners();
    }
  }

  void removeBackgroundAsset(String path) {
    if (!_isInitialized) return;
    if (_backgroundAssets.contains(path)) {
      _backgroundAssets.remove(path);
      _customNames.remove(path);
      _persistAssets();
      notifyListeners();
    }
  }

  void removeAudioAsset(String path) {
    if (!_isInitialized) return;
    if (_audioAssets.contains(path)) {
      _audioAssets.remove(path);
      _musicAssets.remove(path);
      _sfxAssets.remove(path);
      _customNames.remove(path);
      _persistAssets();
      notifyListeners();
    }
  }

  void removeMusicAsset(String path) {
    if (!_isInitialized) return;
    if (_musicAssets.contains(path)) {
      _musicAssets.remove(path);
      _audioAssets.remove(path);
      _customNames.remove(path);
      _persistAssets();
      notifyListeners();
    }
  }

  void removeSfxAsset(String path) {
    if (!_isInitialized) return;
    if (_sfxAssets.contains(path)) {
      _sfxAssets.remove(path);
      _audioAssets.remove(path);
      _customNames.remove(path);
      _persistAssets();
      notifyListeners();
    }
  }

  void _persistAssets() async {
    try {
      final box = Hive.isBoxOpen('asset_box') ? Hive.box('asset_box') : await Hive.openBox('asset_box');
      await box.put('overlay_assets', _overlayAssets);
      await box.put('background_assets', _backgroundAssets);
      await box.put('audio_assets', _audioAssets);
      await box.put('music_assets', _musicAssets);
      await box.put('sfx_assets', _sfxAssets);
      await box.put('palettes', _palettes.map((p) => p.toJson()).toList());
      await box.put('custom_names', _customNames);
    } catch (e) {
      print("Error persisting assets: $e");
    }
  }
}
