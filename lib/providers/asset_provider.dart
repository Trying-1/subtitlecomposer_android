import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

class AssetProvider extends ChangeNotifier {
  List<String> _overlayAssets = [];
  List<String> _backgroundAssets = [];
  bool _isInitialized = false;

  List<String> get assets => _overlayAssets; // For backward compatibility with OverlayTab
  List<String> get overlayAssets => _overlayAssets;
  List<String> get backgroundAssets => _backgroundAssets;

  AssetProvider();

  Future<void> init() async {
    if (_isInitialized) return;
    try {
      final box = await Hive.openBox('asset_box');
      
      final overlayData = box.get('overlay_assets');
      if (overlayData != null) {
        _overlayAssets = List<String>.from(overlayData);
      }

      final backgroundData = box.get('background_assets');
      if (backgroundData != null) {
        _backgroundAssets = List<String>.from(backgroundData);
      }
    } catch (e) {
      print("Error loading assets: $e");
    } finally {
      _isInitialized = true;
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

  void removeAsset(String path) {
    if (!_isInitialized) return;
    
    if (_overlayAssets.contains(path)) {
      _overlayAssets.remove(path);
      _persistAssets();
      notifyListeners();
    }
  }

  void removeBackgroundAsset(String path) {
    if (!_isInitialized) return;
    
    if (_backgroundAssets.contains(path)) {
      _backgroundAssets.remove(path);
      _persistAssets();
      notifyListeners();
    }
  }

  void _persistAssets() {
    try {
      final box = Hive.box('asset_box');
      box.put('overlay_assets', _overlayAssets);
      box.put('background_assets', _backgroundAssets);
    } catch (e) {
      print("Error persisting assets: $e");
    }
  }
}
