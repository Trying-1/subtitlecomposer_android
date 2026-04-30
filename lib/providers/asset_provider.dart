import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

class AssetProvider extends ChangeNotifier {
  List<String> _overlayAssets = [];
  List<String> _backgroundAssets = [];
  List<String> _audioAssets = [];
  Map<String, String> _customNames = {};
  bool _isInitialized = false;

  List<String> get assets => _overlayAssets; 
  List<String> get overlayAssets => _overlayAssets;
  List<String> get backgroundAssets => _backgroundAssets;
  List<String> get audioAssets => _audioAssets;

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
      await box.put('custom_names', _customNames);
    } catch (e) {
      print("Error persisting assets: $e");
    }
  }
}
