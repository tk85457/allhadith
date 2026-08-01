import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class AdService {
  static bool _isInitialized = false;

  /// Production Banner Ad Unit ID
  static const String androidProductionBannerId = 'ca-app-pub-3362561286987631/2534015179';

  /// Production Native Ad Unit ID
  static const String androidProductionNativeId = 'ca-app-pub-3362561286987631/4345524361';

  /// Production Rewarded Ad Unit ID
  static const String androidProductionRewardedId = 'ca-app-pub-3362561286987631/8907851839';

  /// Test Banner Ad Unit ID for Android
  static const String androidTestBannerId = 'ca-app-pub-3940256099942544/6300978111';

  /// Test Rewarded Ad Unit ID for Android
  static const String androidTestRewardedId = 'ca-app-pub-3940256099942544/5224354917';

  /// Test Banner Ad Unit ID for iOS
  static const String iosTestBannerId = 'ca-app-pub-3940256099942544/2934735716';

  /// Check if ads are supported on the current platform
  static bool get isSupported {
    if (kIsWeb) return false;
    return Platform.isAndroid || Platform.isIOS;
  }

  /// Initialize Mobile Ads SDK safely
  static Future<void> initialize() async {
    if (!isSupported || _isInitialized) return;
    try {
      await MobileAds.instance.initialize();
      _isInitialized = true;
    } catch (e) {
      debugPrint('AdService initialization failed: $e');
    }
  }

  /// Get appropriate Banner Ad Unit ID
  static String get bannerAdUnitId {
    if (kDebugMode) {
      if (Platform.isAndroid) return androidTestBannerId;
      if (Platform.isIOS) return iosTestBannerId;
    }
    if (Platform.isAndroid) return androidProductionBannerId;
    return iosTestBannerId;
  }

  /// Get appropriate Native / In-Feed Ad Unit ID
  static String get nativeAdUnitId {
    if (kDebugMode) {
      if (Platform.isAndroid) return androidTestBannerId;
      if (Platform.isIOS) return iosTestBannerId;
    }
    if (Platform.isAndroid) return androidProductionNativeId;
    return iosTestBannerId;
  }

  /// Get appropriate Rewarded Ad Unit ID
  static String get rewardedAdUnitId {
    if (kDebugMode) {
      if (Platform.isAndroid) return androidTestRewardedId;
      if (Platform.isIOS) return iosTestBannerId;
    }
    if (Platform.isAndroid) return androidProductionRewardedId;
    return iosTestBannerId;
  }

  /// Helper to load & show Rewarded Ad with fallback
  static void showRewardedAd({
    required VoidCallback onUserEarnedReward,
    VoidCallback? onAdFailed,
  }) {
    if (!isSupported) {
      onUserEarnedReward();
      return;
    }

    _loadRewardedWithUnit(
      unitId: rewardedAdUnitId,
      onUserEarnedReward: onUserEarnedReward,
      onFailed: () {
        // Fallback to test ID if primary production ID is still propagating
        if (rewardedAdUnitId != androidTestRewardedId) {
          _loadRewardedWithUnit(
            unitId: androidTestRewardedId,
            onUserEarnedReward: onUserEarnedReward,
            onFailed: onAdFailed,
          );
        } else {
          onAdFailed?.call();
        }
      },
    );
  }

  static void _loadRewardedWithUnit({
    required String unitId,
    required VoidCallback onUserEarnedReward,
    VoidCallback? onFailed,
  }) {
    RewardedAd.load(
      adUnitId: unitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          ad.fullScreenContentCallback = FullScreenContentCallback(
            onAdDismissedFullScreenContent: (ad) {
              ad.dispose();
            },
            onAdFailedToShowFullScreenContent: (ad, err) {
              ad.dispose();
              onFailed?.call();
            },
          );

          ad.show(
            onUserEarnedReward: (ad, reward) {
              onUserEarnedReward();
            },
          );
        },
        onAdFailedToLoad: (err) {
          debugPrint('RewardedAd ($unitId) failed to load: ${err.message}');
          onFailed?.call();
        },
      ),
    );
  }
}
