import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

class AssetProvider extends ChangeNotifier {
  List<String> _assets = [];
  bool _isInitialized = false;

  List<String> get assets => _assets;

  AssetProvider();

  Future<void> init() async {
    if (_isInitialized) return;
    try {
      final box = await Hive.openBox('asset_box');
      final data = box.get('overlay_assets');
      if (data != null) {
        _assets = List<String>.from(data);
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
      if (!_assets.contains(path)) {
        _assets.add(path);
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
    
    if (_assets.contains(path)) {
      _assets.remove(path);
      _persistAssets();
      notifyListeners();
    }
  }

  void _persistAssets() {
    try {
      final box = Hive.box('asset_box');
      box.put('overlay_assets', _assets);
    } catch (e) {
      print("Error persisting assets: $e");
    }
  }
}
