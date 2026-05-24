import 'dart:io';

class AdConfig {
  // Master toggle for all ads
  static const bool areAdsEnabled = false;

  // Individual ad unit toggles
  static const bool isAppOpenAdEnabled = true;
  static const bool isInterstitialAdEnabled = true;
  static const bool isTypoExportRewardAdEnabled = true;
  static const bool isImageTextInterAdEnabled = true;
  static const bool isImageSequenceExportAdEnabled = true;
  static const bool isFontSequenceExportAdEnabled = true;
  static const bool isAutoKineticRewardAdEnabled = true;

  static String get appOpenAdUnitId {
    if (Platform.isAndroid) {
      return 'ca-app-pub-5829296907403264/5047088367'; // Real Production App Open Ad Unit ID
    } else if (Platform.isIOS) {
      return 'ca-app-pub-3940256099942544/5575463023'; // Test ID fallback
    }
    throw UnsupportedError('Unsupported platform');
  }

  static String get interstitialAdUnitId {
    if (Platform.isAndroid) {
      return 'ca-app-pub-5829296907403264/8997941664'; // Real Ad Unit ID
    } else if (Platform.isIOS) {
      return 'ca-app-pub-3940256099942544/4411468910'; // Test ID fallback
    }
    throw UnsupportedError('Unsupported platform');
  }

  static String get typoExportRewardAdUnitId {
    if (Platform.isAndroid) {
      return 'ca-app-pub-5829296907403264/6196518507'; // Real Rewarded Ad Unit ID
    } else if (Platform.isIOS) {
      return 'ca-app-pub-3940256099942544/5224354917'; // Test ID fallback
    }
    throw UnsupportedError('Unsupported platform');
  }

  static String get imageTextInterAdUnitId {
    if (Platform.isAndroid) {
      return 'ca-app-pub-5829296907403264/6004946814'; // Real Image Text Interstitial Ad Unit ID
    } else if (Platform.isIOS) {
      return 'ca-app-pub-3940256099942544/4411468910'; // Test ID fallback
    }
    throw UnsupportedError('Unsupported platform');
  }

  static String get imageSequenceExportAdUnitId {
    if (Platform.isAndroid) {
      return 'ca-app-pub-5829296907403264/2833885779'; // Real Image Sequence Interstitial Ad Unit ID
    } else if (Platform.isIOS) {
      return 'ca-app-pub-3940256099942544/4411468910'; // Test ID fallback
    }
    throw UnsupportedError('Unsupported platform');
  }

  static String get fontSequenceExportAdUnitId {
    if (Platform.isAndroid) {
      return 'ca-app-pub-5829296907403264/2111831047'; // Real Font Sequence Interstitial Ad Unit ID
    } else if (Platform.isIOS) {
      return 'ca-app-pub-3940256099942544/4411468910'; // Test ID fallback
    }
    throw UnsupportedError('Unsupported platform');
  }

  static String get autoKineticRewardAdUnitId {
    if (Platform.isAndroid) {
      return 'ca-app-pub-5829296907403264/8794761686'; // Real Auto Kinetic Rewarded Ad Unit ID
    } else if (Platform.isIOS) {
      return 'ca-app-pub-3940256099942544/5224354917'; // Test ID fallback
    }
    throw UnsupportedError('Unsupported platform');
  }
}
