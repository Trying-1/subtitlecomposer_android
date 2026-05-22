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

  InterstitialAd? _interstitialAd;
  bool _isShowingInterstitialAd = false;

  final Duration maxCacheDuration = const Duration(hours: 4);

  Future<void> init() async {
    await MobileAds.instance.initialize();
    WidgetsBinding.instance.addObserver(this);
    loadAppOpenAd();
    loadInterstitialAd();
  }

  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _appOpenAd?.dispose();
    _interstitialAd?.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
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
        AdHelper.logAdEvent('InterstitialAd_Showed');
      },
      onAdDismissedFullScreenContent: (ad) {
        _isShowingInterstitialAd = false;
        ad.dispose();
        _interstitialAd = null;
        AdHelper.logAdEvent('InterstitialAd_Dismissed');
        loadInterstitialAd();
        onAdDismissed();
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        _isShowingInterstitialAd = false;
        ad.dispose();
        _interstitialAd = null;
        AdHelper.logAdEvent('InterstitialAd_FailedToShow', parameters: {'error': error.message});
        loadInterstitialAd();
        onAdDismissed();
      },
    );

    await _interstitialAd!.show();
  }
}
