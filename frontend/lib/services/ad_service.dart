import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:flutter/foundation.dart';

class AdService {
  static final AdService _instance = AdService._internal();
  factory AdService() => _instance;
  AdService._internal();

  // Test Ad Unit IDs (Android)
  static const String _interstitialId = 'ca-app-pub-3940256099942544/1033173712';
  static const String _rewardedId = 'ca-app-pub-3940256099942544/5224354917';
  static const String _bannerId = 'ca-app-pub-3940256099942544/6300978111';

  InterstitialAd? _interstitialAd;
  RewardedAd? _rewardedAd;
  BannerAd? _bannerAd;

  // ... (keep init)

  // Banner Ad
  BannerAd? get bannerAd => _bannerAd;

  void loadBannerAd() {
    _bannerAd = BannerAd(
      adUnitId: _bannerId,
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdFailedToLoad: (ad, err) => ad.dispose(),
      ),
    );
    _bannerAd!.load();
  }

  Future<void> init() async {
    await MobileAds.instance.initialize();
  }

  void loadInterstitialAd() {
    InterstitialAd.load(
      adUnitId: _interstitialId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) => _interstitialAd = ad,
        onAdFailedToLoad: (err) => debugPrint('Failed to load interstitial: $err'),
      ),
    );
  }

  Future<void> showInterstitialAd() async {
    if (_interstitialAd == null) return;
    await _interstitialAd!.show();
    _interstitialAd = null;
    loadInterstitialAd();
  }

  void loadRewardedAd() {
    RewardedAd.load(
      adUnitId: _rewardedId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) => _rewardedAd = ad,
        onAdFailedToLoad: (err) => debugPrint('Failed to load rewarded: $err'),
      ),
    );
  }

  Future<void> showRewardedAd({required Function onEarned}) async {
    if (_rewardedAd == null) {
      onEarned();
      return;
    }
    _rewardedAd!.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        loadRewardedAd();
      },
    );
    await _rewardedAd!.show(onUserEarnedReward: (ad, reward) => onEarned());
    _rewardedAd = null;
  }
}
