import 'package:flutter/foundation.dart';

class AdHelper {
  static void logAdEvent(String eventName, {Map<String, dynamic>? parameters}) {
    // This can be connected to analytics later
    if (kDebugMode) {
      print('AdEvent: $eventName, Parameters: $parameters');
    }
  }
}
