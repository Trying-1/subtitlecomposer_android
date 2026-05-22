import 'package:in_app_review/in_app_review.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter/foundation.dart';

class AppReviewService {
  static final InAppReview _inAppReview = InAppReview.instance;
  static const String _reviewKey = 'has_requested_review';
  static const String _exportCountKey = 'export_count_for_review';

  static Future<void> requestReviewIfNeeded() async {
    if (kIsWeb || (defaultTargetPlatform != TargetPlatform.android && defaultTargetPlatform != TargetPlatform.iOS)) {
      return;
    }

    try {
      final box = Hive.box('settings');
      final hasRequested = box.get(_reviewKey, defaultValue: false) as bool;
      int exportCount = box.get(_exportCountKey, defaultValue: 0) as int;
      
      exportCount++;
      box.put(_exportCountKey, exportCount);

      // Request review if not requested yet, and after 2 successful exports
      // Or every 10 exports after that. (Google Play handles actual rate limiting)
      if (!hasRequested && exportCount >= 2) {
        if (await _inAppReview.isAvailable()) {
          await _inAppReview.requestReview();
          box.put(_reviewKey, true);
        }
      } else if (hasRequested && exportCount % 10 == 0) {
        if (await _inAppReview.isAvailable()) {
          await _inAppReview.requestReview();
        }
      }
    } catch (e) {
      debugPrint("Error requesting in-app review: $e");
    }
  }
}
