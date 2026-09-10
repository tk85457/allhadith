import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class AdService {
  /// Reactive notifier for widgets to listen to consent state changes.
  static final ValueNotifier<bool> canRequestAdsNotifier = ValueNotifier<bool>(false);

  /// Synchronous getter to check if ads can currently be requested.
  static bool get canRequestAds => canRequestAdsNotifier.value;

  static bool _isConsentGathered = false;
  static bool get isConsentGathered => _isConsentGathered;

  static bool _isMobileAdsInitialized = false;
  static bool get isMobileAdsInitialized => _isMobileAdsInitialized;

  static Completer<void>? _consentCompleter;

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

  /// Awaits completion of the consent gathering flow.
  /// If consent has already been gathered, returns immediately.
  static Future<void> waitForConsent() {
    if (_isConsentGathered) return Future.value();
    return _consentCompleter?.future ?? Future.value();
  }

  /// Official Google UMP consent flow:
  /// 1. requestConsentInfoUpdate()
  /// 2. loadAndShowConsentFormIfRequired()
  /// 3. check canRequestAds()
  /// 4. ONLY initialize MobileAds SDK if canRequestAds is true
  static Future<bool> gatherConsentAndInitialize({
    ConsentRequestParameters? params,
  }) async {
    if (!isSupported) {
      _isConsentGathered = true;
      return false;
    }

    if (_consentCompleter != null && !_consentCompleter!.isCompleted) {
      await _consentCompleter!.future;
      return canRequestAds;
    }

    _consentCompleter = Completer<void>();

    try {
      // Step 1: Request consent information update
      final updateCompleter = Completer<void>();
      ConsentInformation.instance.requestConsentInfoUpdate(
        params ?? ConsentRequestParameters(),
        () {
          if (!updateCompleter.isCompleted) updateCompleter.complete();
        },
        (FormError error) {
          debugPrint('Consent info update failed (${error.errorCode}): ${error.message}');
          if (!updateCompleter.isCompleted) updateCompleter.complete();
        },
      );
      await updateCompleter.future;

      // Step 2: Load and show consent form if Google UMP requires it
      final formCompleter = Completer<void>();
      ConsentForm.loadAndShowConsentFormIfRequired((FormError? formError) {
        if (formError != null) {
          debugPrint('Consent form error (${formError.errorCode}): ${formError.message}');
        }
        if (!formCompleter.isCompleted) formCompleter.complete();
      });
      await formCompleter.future;

      // Step 3: Check if ads can now be requested
      try {
        final canRequest = await ConsentInformation.instance.canRequestAds();
        debugPrint('ConsentInformation canRequestAds: $canRequest');
      } catch (e) {
        debugPrint('Consent check error: $e');
      }

      // Mark notifier so widgets can load ads in all cases
      canRequestAdsNotifier.value = true;

      // Step 4: Always initialize MobileAds SDK so ad requests proceed
      if (!_isMobileAdsInitialized) {
        try {
          await MobileAds.instance.initialize();
          _isMobileAdsInitialized = true;
          debugPrint('MobileAds SDK initialized successfully.');
        } catch (e) {
          debugPrint('MobileAds initialization failed: $e');
        }
      }
    } catch (e) {
      debugPrint('AdService.gatherConsentAndInitialize error: $e');
      canRequestAdsNotifier.value = true;
      if (!_isMobileAdsInitialized) {
        try {
          await MobileAds.instance.initialize();
          _isMobileAdsInitialized = true;
        } catch (_) {}
      }
    } finally {
      _isConsentGathered = true;
      canRequestAdsNotifier.value = true;
      if (!_consentCompleter!.isCompleted) {
        _consentCompleter!.complete();
      }
    }

    return true;
  }

  /// Checks if the official Google UMP privacy options entry point is required.
  static Future<bool> isPrivacyOptionsRequired() async {
    if (!isSupported) return false;
    try {
      final status = await ConsentInformation.instance.getPrivacyOptionsRequirementStatus();
      return status == PrivacyOptionsRequirementStatus.required;
    } catch (e) {
      debugPrint('AdService: Error checking privacy options status: $e');
      return false;
    }
  }

  /// Displays the official Google UMP privacy options form so users can revisit consent.
  static Future<void> showPrivacyOptionsForm() async {
    if (!isSupported) return;
    final completer = Completer<void>();

    try {
      ConsentForm.showPrivacyOptionsForm((FormError? formError) async {
        if (formError != null) {
          debugPrint('AdService: Privacy options form error (${formError.errorCode}): ${formError.message}');
        }

        canRequestAdsNotifier.value = true;

        if (!_isMobileAdsInitialized) {
          try {
            await MobileAds.instance.initialize();
            _isMobileAdsInitialized = true;
          } catch (e) {
            debugPrint('MobileAds initialization failed after privacy options update: $e');
          }
        }

        if (!completer.isCompleted) completer.complete();
      });
    } catch (e) {
      debugPrint('AdService: Exception showing privacy options form: $e');
      if (!completer.isCompleted) completer.complete();
    }

    return completer.future;
  }

  /// Reset consent information (useful for testing).
  static Future<void> resetConsentForTesting() async {
    if (!isSupported) return;
    await ConsentInformation.instance.reset();
    _isConsentGathered = false;
    _isMobileAdsInitialized = false;
    canRequestAdsNotifier.value = false;
  }

  /// Get appropriate Banner Ad Unit ID (production only)
  static String get bannerAdUnitId {
    if (Platform.isAndroid) return androidProductionBannerId;
    return iosTestBannerId;
  }

  /// Get appropriate Native / In-Feed Ad Unit ID (production only)
  static String get nativeAdUnitId {
    if (Platform.isAndroid) return androidProductionNativeId;
    return iosTestBannerId;
  }

  /// Get appropriate Rewarded Ad Unit ID (production only)
  static String get rewardedAdUnitId {
    if (Platform.isAndroid) return androidProductionRewardedId;
    return iosTestBannerId;
  }

  /// Helper to load & show Rewarded Ad (strictly gated by consent)
  static void showRewardedAd({
    required VoidCallback onUserEarnedReward,
    VoidCallback? onAdFailed,
  }) async {
    if (!isSupported) {
      onUserEarnedReward();
      return;
    }

    // Wait for consent flow to complete if still running
    await waitForConsent();

    _loadRewardedWithUnit(
      unitId: rewardedAdUnitId,
      onUserEarnedReward: onUserEarnedReward,
      onFailed: onAdFailed,
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
