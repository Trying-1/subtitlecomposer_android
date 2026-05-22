import 'package:in_app_update/in_app_update.dart';
import 'package:flutter/foundation.dart';

class AppUpdateService {
  static Future<void> checkForUpdates() async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) return;
    
    try {
      final info = await InAppUpdate.checkForUpdate();
      if (info.updateAvailability == UpdateAvailability.updateAvailable) {
        if (info.immediateUpdateAllowed) {
          await InAppUpdate.performImmediateUpdate();
        } else if (info.flexibleUpdateAllowed) {
          await InAppUpdate.startFlexibleUpdate();
          await InAppUpdate.completeFlexibleUpdate();
        }
      }
    } catch (e) {
      debugPrint("Error checking for updates: $e");
    }
  }
}
