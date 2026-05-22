import 'dart:io';

class AdConfig {
  // Master toggle for all ads
  static const bool areAdsEnabled = false;

  // Individual ad unit toggles
  static const bool isAppOpenAdEnabled = false;
  static const bool isInterstitialAdEnabled = false;

  static String get appOpenAdUnitId {
    if (Platform.isAndroid) {
      return 'ca-app-pub-3940256099942544/9257395921'; // Test ID
    } else if (Platform.isIOS) {
      return 'ca-app-pub-3940256099942544/5575463023'; // Test ID
    }
    throw UnsupportedError('Unsupported platform');
  }

  static String get interstitialAdUnitId {
    if (Platform.isAndroid) {
      return 'ca-app-pub-3940256099942544/1033173712'; // Test ID
    } else if (Platform.isIOS) {
      return 'ca-app-pub-3940256099942544/4411468910'; // Test ID
    }
    throw UnsupportedError('Unsupported platform');
  }
}
