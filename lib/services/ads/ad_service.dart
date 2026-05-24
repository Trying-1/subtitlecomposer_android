import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../../config/ad_config.dart';
import 'ad_helper.dart';

class AdService extends WidgetsBindingObserver {
  static final AdService _instance = AdService._internal();
  static AdService get instance => _instance;

  AdService._internal();

  AppOpenAd? _appOpenAd;
  bool _isShowingAppOpenAd = false;
  DateTime? _appOpenLoadTime;
  DateTime? _appBackgroundTime;

  InterstitialAd? _interstitialAd;
  bool _isShowingInterstitialAd = false;

  RewardedAd? _rewardedAd;
  bool _isShowingRewardedAd = false;

  InterstitialAd? _imageTextInterAd;
  bool _isShowingImageTextInterAd = false;

  InterstitialAd? _imageSequenceExportAd;
  bool _isShowingImageSequenceExportAd = false;

  InterstitialAd? _fontSequenceExportAd;
  bool _isShowingFontSequenceExportAd = false;

  RewardedAd? _autoKineticRewardAd;
  bool _isShowingAutoKineticRewardAd = false;

  final Duration maxCacheDuration = const Duration(hours: 4);
  DateTime? _lastFullScreenAdDismissedTime;

  void _recordFullScreenAdInteraction() {
    _lastFullScreenAdDismissedTime = DateTime.now();
  }

  Future<void> init() async {
    await MobileAds.instance.initialize();
    WidgetsBinding.instance.addObserver(this);
    loadAppOpenAd();
    loadInterstitialAd();
    loadRewardedAd();
    loadImageTextInterAd();
    loadImageSequenceExportAd();
    loadFontSequenceExportAd();
    loadAutoKineticRewardAd();
  }

  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _appOpenAd?.dispose();
    _interstitialAd?.dispose();
    _rewardedAd?.dispose();
    _imageTextInterAd?.dispose();
    _imageSequenceExportAd?.dispose();
    _fontSequenceExportAd?.dispose();
    _autoKineticRewardAd?.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      _appBackgroundTime = DateTime.now();
    }
    if (state == AppLifecycleState.resumed) {
      if (_appBackgroundTime != null) {
        final duration = DateTime.now().difference(_appBackgroundTime!);
        if (duration < const Duration(seconds: 30)) {
          // Rapid resume (e.g., returning from file picker, share sheets, popups, other ads)
          return;
        }
      }
      showAppOpenAdIfAvailable();
    }
  }

  // App Open Ad
  void loadAppOpenAd() {
    if (!AdConfig.areAdsEnabled || !AdConfig.isAppOpenAdEnabled) return;

    AppOpenAd.load(
      adUnitId: AdConfig.appOpenAdUnitId,
      request: const AdRequest(),
      adLoadCallback: AppOpenAdLoadCallback(
        onAdLoaded: (ad) {
          _appOpenAd = ad;
          _appOpenLoadTime = DateTime.now();
          AdHelper.logAdEvent('AppOpenAd_Loaded');
        },
        onAdFailedToLoad: (error) {
          AdHelper.logAdEvent('AppOpenAd_FailedToLoad', parameters: {'error': error.message});
        },
      ),
    );
  }

  bool get isAppOpenAdAvailable {
    return _appOpenAd != null &&
        _appOpenLoadTime != null &&
        DateTime.now().subtract(maxCacheDuration).isBefore(_appOpenLoadTime!);
  }

  void showAppOpenAdIfAvailable() {
    if (!AdConfig.areAdsEnabled || !AdConfig.isAppOpenAdEnabled) return;

    // Prevent showing App Open ad if another full-screen ad is currently active or was recently active/dismissed
    if (_isShowingInterstitialAd ||
        _isShowingRewardedAd ||
        _isShowingImageTextInterAd ||
        _isShowingImageSequenceExportAd ||
        _isShowingFontSequenceExportAd ||
        _isShowingAutoKineticRewardAd) {
      return;
    }
    if (_lastFullScreenAdDismissedTime != null &&
        DateTime.now().difference(_lastFullScreenAdDismissedTime!) < const Duration(seconds: 15)) {
      return;
    }

    if (!isAppOpenAdAvailable) {
      loadAppOpenAd();
      return;
    }
    if (_isShowingAppOpenAd) {
      return;
    }

    _appOpenAd!.fullScreenContentCallback = FullScreenContentCallback(
      onAdShowedFullScreenContent: (ad) {
        _isShowingAppOpenAd = true;
        AdHelper.logAdEvent('AppOpenAd_Showed');
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        _isShowingAppOpenAd = false;
        ad.dispose();
        _appOpenAd = null;
        AdHelper.logAdEvent('AppOpenAd_FailedToShow', parameters: {'error': error.message});
        loadAppOpenAd();
      },
      onAdDismissedFullScreenContent: (ad) {
        _isShowingAppOpenAd = false;
        ad.dispose();
        _appOpenAd = null;
        AdHelper.logAdEvent('AppOpenAd_Dismissed');
        loadAppOpenAd();
      },
    );

    _appOpenAd!.show();
  }

  // Interstitial Ad
  void loadInterstitialAd() {
    if (!AdConfig.areAdsEnabled || !AdConfig.isInterstitialAdEnabled) return;

    InterstitialAd.load(
      adUnitId: AdConfig.interstitialAdUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _interstitialAd = ad;
          AdHelper.logAdEvent('InterstitialAd_Loaded');
        },
        onAdFailedToLoad: (error) {
          AdHelper.logAdEvent('InterstitialAd_FailedToLoad', parameters: {'error': error.message});
        },
      ),
    );
  }

  Future<void> showInterstitialAd({required VoidCallback onAdDismissed}) async {
    _recordFullScreenAdInteraction();
    if (!AdConfig.areAdsEnabled || !AdConfig.isInterstitialAdEnabled) {
      onAdDismissed();
      return;
    }

    if (_interstitialAd == null) {
      AdHelper.logAdEvent('InterstitialAd_NotReady');
      onAdDismissed();
      loadInterstitialAd();
      return;
    }

    _interstitialAd!.fullScreenContentCallback = FullScreenContentCallback(
      onAdShowedFullScreenContent: (ad) {
        _isShowingInterstitialAd = true;
        _recordFullScreenAdInteraction();
        AdHelper.logAdEvent('InterstitialAd_Showed');
      },
      onAdDismissedFullScreenContent: (ad) {
        _isShowingInterstitialAd = false;
        _recordFullScreenAdInteraction();
        ad.dispose();
        _interstitialAd = null;
        AdHelper.logAdEvent('InterstitialAd_Dismissed');
        loadInterstitialAd();
        onAdDismissed();
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        _isShowingInterstitialAd = false;
        _recordFullScreenAdInteraction();
        ad.dispose();
        _interstitialAd = null;
        AdHelper.logAdEvent('InterstitialAd_FailedToShow', parameters: {'error': error.message});
        loadInterstitialAd();
        onAdDismissed();
      },
    );

    await _interstitialAd!.show();
  }

  // Rewarded Ad
  void loadRewardedAd() {
    if (!AdConfig.areAdsEnabled || !AdConfig.isTypoExportRewardAdEnabled) return;

    RewardedAd.load(
      adUnitId: AdConfig.typoExportRewardAdUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          _rewardedAd = ad;
          AdHelper.logAdEvent('RewardedAd_Loaded');
        },
        onAdFailedToLoad: (error) {
          AdHelper.logAdEvent('RewardedAd_FailedToLoad', parameters: {'error': error.message});
        },
      ),
    );
  }

  Future<void> showRewardedAd({
    required VoidCallback onRewardEarned,
    required VoidCallback onAdDismissed,
  }) async {
    _recordFullScreenAdInteraction();
    if (!AdConfig.areAdsEnabled || !AdConfig.isTypoExportRewardAdEnabled) {
      onRewardEarned();
      onAdDismissed();
      return;
    }

    if (_rewardedAd == null) {
      AdHelper.logAdEvent('RewardedAd_NotReady');
      onRewardEarned(); // Bypass if ad is not ready so user is not blocked
      onAdDismissed();
      loadRewardedAd();
      return;
    }

    bool rewardEarned = false;

    _rewardedAd!.fullScreenContentCallback = FullScreenContentCallback(
      onAdShowedFullScreenContent: (ad) {
        _isShowingRewardedAd = true;
        _recordFullScreenAdInteraction();
        AdHelper.logAdEvent('RewardedAd_Showed');
      },
      onAdDismissedFullScreenContent: (ad) {
        _isShowingRewardedAd = false;
        _recordFullScreenAdInteraction();
        ad.dispose();
        _rewardedAd = null;
        AdHelper.logAdEvent('RewardedAd_Dismissed');
        loadRewardedAd();
        if (rewardEarned) {
          onRewardEarned();
        }
        onAdDismissed();
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        _isShowingRewardedAd = false;
        _recordFullScreenAdInteraction();
        ad.dispose();
        _rewardedAd = null;
        AdHelper.logAdEvent('RewardedAd_FailedToShow', parameters: {'error': error.message});
        loadRewardedAd();
        // Fallback: award the reward so we don't break the user experience
        onRewardEarned();
        onAdDismissed();
      },
    );

    await _rewardedAd!.show(
      onUserEarnedReward: (AdWithoutView ad, RewardItem reward) {
        rewardEarned = true;
        AdHelper.logAdEvent('RewardedAd_UserEarnedReward', parameters: {
          'amount': reward.amount,
          'type': reward.type,
        });
      },
    );
  }

  // Image Text Studio Interstitial Ad
  void loadImageTextInterAd() {
    if (!AdConfig.areAdsEnabled || !AdConfig.isImageTextInterAdEnabled) return;

    InterstitialAd.load(
      adUnitId: AdConfig.imageTextInterAdUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _imageTextInterAd = ad;
          AdHelper.logAdEvent('ImageTextInterAd_Loaded');
        },
        onAdFailedToLoad: (error) {
          AdHelper.logAdEvent('ImageTextInterAd_FailedToLoad', parameters: {'error': error.message});
        },
      ),
    );
  }

  Future<void> showImageTextInterAd({required VoidCallback onAdDismissed}) async {
    _recordFullScreenAdInteraction();
    if (!AdConfig.areAdsEnabled || !AdConfig.isImageTextInterAdEnabled) {
      onAdDismissed();
      return;
    }

    if (_imageTextInterAd == null) {
      AdHelper.logAdEvent('ImageTextInterAd_NotReady');
      onAdDismissed();
      loadImageTextInterAd();
      return;
    }

    _imageTextInterAd!.fullScreenContentCallback = FullScreenContentCallback(
      onAdShowedFullScreenContent: (ad) {
        _isShowingImageTextInterAd = true;
        _recordFullScreenAdInteraction();
        AdHelper.logAdEvent('ImageTextInterAd_Showed');
      },
      onAdDismissedFullScreenContent: (ad) {
        _isShowingImageTextInterAd = false;
        _recordFullScreenAdInteraction();
        ad.dispose();
        _imageTextInterAd = null;
        AdHelper.logAdEvent('ImageTextInterAd_Dismissed');
        loadImageTextInterAd();
        onAdDismissed();
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        _isShowingImageTextInterAd = false;
        _recordFullScreenAdInteraction();
        ad.dispose();
        _imageTextInterAd = null;
        AdHelper.logAdEvent('ImageTextInterAd_FailedToShow', parameters: {'error': error.message});
        loadImageTextInterAd();
        onAdDismissed();
      },
    );

    await _imageTextInterAd!.show();
  }

  // Image Sequence Studio Interstitial Ad
  void loadImageSequenceExportAd() {
    if (!AdConfig.areAdsEnabled || !AdConfig.isImageSequenceExportAdEnabled) return;

    InterstitialAd.load(
      adUnitId: AdConfig.imageSequenceExportAdUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _imageSequenceExportAd = ad;
          AdHelper.logAdEvent('ImageSequenceExportAd_Loaded');
        },
        onAdFailedToLoad: (error) {
          AdHelper.logAdEvent('ImageSequenceExportAd_FailedToLoad', parameters: {'error': error.message});
        },
      ),
    );
  }

  Future<void> showImageSequenceExportAd({required VoidCallback onAdDismissed}) async {
    _recordFullScreenAdInteraction();
    if (!AdConfig.areAdsEnabled || !AdConfig.isImageSequenceExportAdEnabled) {
      onAdDismissed();
      return;
    }

    if (_imageSequenceExportAd == null) {
      AdHelper.logAdEvent('ImageSequenceExportAd_NotReady');
      onAdDismissed();
      loadImageSequenceExportAd();
      return;
    }

    _imageSequenceExportAd!.fullScreenContentCallback = FullScreenContentCallback(
      onAdShowedFullScreenContent: (ad) {
        _isShowingImageSequenceExportAd = true;
        _recordFullScreenAdInteraction();
        AdHelper.logAdEvent('ImageSequenceExportAd_Showed');
      },
      onAdDismissedFullScreenContent: (ad) {
        _isShowingImageSequenceExportAd = false;
        _recordFullScreenAdInteraction();
        ad.dispose();
        _imageSequenceExportAd = null;
        AdHelper.logAdEvent('ImageSequenceExportAd_Dismissed');
        loadImageSequenceExportAd();
        onAdDismissed();
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        _isShowingImageSequenceExportAd = false;
        _recordFullScreenAdInteraction();
        ad.dispose();
        _imageSequenceExportAd = null;
        AdHelper.logAdEvent('ImageSequenceExportAd_FailedToShow', parameters: {'error': error.message});
        loadImageSequenceExportAd();
        onAdDismissed();
      },
    );

    await _imageSequenceExportAd!.show();
  }

  // Font Sequence Studio Interstitial Ad
  void loadFontSequenceExportAd() {
    if (!AdConfig.areAdsEnabled || !AdConfig.isFontSequenceExportAdEnabled) return;

    InterstitialAd.load(
      adUnitId: AdConfig.fontSequenceExportAdUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _fontSequenceExportAd = ad;
          AdHelper.logAdEvent('FontSequenceExportAd_Loaded');
        },
        onAdFailedToLoad: (error) {
          AdHelper.logAdEvent('FontSequenceExportAd_FailedToLoad', parameters: {'error': error.message});
        },
      ),
    );
  }

  Future<void> showFontSequenceExportAd({required VoidCallback onAdDismissed}) async {
    _recordFullScreenAdInteraction();
    if (!AdConfig.areAdsEnabled || !AdConfig.isFontSequenceExportAdEnabled) {
      onAdDismissed();
      return;
    }

    if (_fontSequenceExportAd == null) {
      AdHelper.logAdEvent('FontSequenceExportAd_NotReady');
      onAdDismissed();
      loadFontSequenceExportAd();
      return;
    }

    _fontSequenceExportAd!.fullScreenContentCallback = FullScreenContentCallback(
      onAdShowedFullScreenContent: (ad) {
        _isShowingFontSequenceExportAd = true;
        _recordFullScreenAdInteraction();
        AdHelper.logAdEvent('FontSequenceExportAd_Showed');
      },
      onAdDismissedFullScreenContent: (ad) {
        _isShowingFontSequenceExportAd = false;
        _recordFullScreenAdInteraction();
        ad.dispose();
        _fontSequenceExportAd = null;
        AdHelper.logAdEvent('FontSequenceExportAd_Dismissed');
        loadFontSequenceExportAd();
        onAdDismissed();
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        _isShowingFontSequenceExportAd = false;
        _recordFullScreenAdInteraction();
        ad.dispose();
        _fontSequenceExportAd = null;
        AdHelper.logAdEvent('FontSequenceExportAd_FailedToShow', parameters: {'error': error.message});
        loadFontSequenceExportAd();
        onAdDismissed();
      },
    );

    await _fontSequenceExportAd!.show();
  }

  // Auto Kinetic Layouts Rewarded Ad
  void loadAutoKineticRewardAd() {
    if (!AdConfig.areAdsEnabled || !AdConfig.isAutoKineticRewardAdEnabled) return;

    RewardedAd.load(
      adUnitId: AdConfig.autoKineticRewardAdUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          _autoKineticRewardAd = ad;
          AdHelper.logAdEvent('AutoKineticRewardAd_Loaded');
        },
        onAdFailedToLoad: (error) {
          AdHelper.logAdEvent('AutoKineticRewardAd_FailedToLoad', parameters: {'error': error.message});
        },
      ),
    );
  }

  Future<void> showAutoKineticRewardAd({
    required VoidCallback onRewardEarned,
    required VoidCallback onAdDismissed,
  }) async {
    _recordFullScreenAdInteraction();
    if (!AdConfig.areAdsEnabled || !AdConfig.isAutoKineticRewardAdEnabled) {
      onRewardEarned();
      onAdDismissed();
      return;
    }

    if (_autoKineticRewardAd == null) {
      AdHelper.logAdEvent('AutoKineticRewardAd_NotReady');
      loadAutoKineticRewardAd();
      onRewardEarned();
      onAdDismissed();
      return;
    }

    bool rewardEarned = false;

    _autoKineticRewardAd!.fullScreenContentCallback = FullScreenContentCallback(
      onAdShowedFullScreenContent: (ad) {
        _isShowingAutoKineticRewardAd = true;
        _recordFullScreenAdInteraction();
        AdHelper.logAdEvent('AutoKineticRewardAd_Showed');
      },
      onAdDismissedFullScreenContent: (ad) {
        _isShowingAutoKineticRewardAd = false;
        _recordFullScreenAdInteraction();
        ad.dispose();
        _autoKineticRewardAd = null;
        AdHelper.logAdEvent('AutoKineticRewardAd_Dismissed');
        loadAutoKineticRewardAd();
        if (rewardEarned) {
          onRewardEarned();
        }
        onAdDismissed();
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        _isShowingAutoKineticRewardAd = false;
        _recordFullScreenAdInteraction();
        ad.dispose();
        _autoKineticRewardAd = null;
        AdHelper.logAdEvent('AutoKineticRewardAd_FailedToShow', parameters: {'error': error.message});
        loadAutoKineticRewardAd();
        // Fallback: award the reward so we don't break the user experience
        onRewardEarned();
        onAdDismissed();
      },
    );

    await _autoKineticRewardAd!.show(
      onUserEarnedReward: (AdWithoutView ad, RewardItem reward) {
        rewardEarned = true;
        AdHelper.logAdEvent('AutoKineticRewardAd_UserEarnedReward', parameters: {
          'amount': reward.amount,
          'type': reward.type,
        });
      },
    );
  }
}
