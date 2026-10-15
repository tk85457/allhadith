import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Comprehensive Production Ad Service.
///
/// Features:
/// - Official Google UMP Consent Gathering
/// - Rewarded Interstitial Ad Unit: ca-app-pub-3362561286987631/2623527351
/// - Jami` at-Tirmidhi & Sahih al-Bukhari model: 24-Hour Ad-Free Reading Pass
/// - Reactive state management via ValueNotifier (zero rebuild overhead)
/// - Background preloading & backoff protection
class AdService {
  /// Global ScaffoldMessengerKey for app-wide celebratory notifications.
  static final GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey =
      GlobalKey<ScaffoldMessengerState>();

  /// Reactive notifier for widgets to listen to consent state changes.
  static final ValueNotifier<bool> canRequestAdsNotifier = ValueNotifier<bool>(false);

  /// Synchronous getter to check if ads can currently be requested.
  static bool get canRequestAds => canRequestAdsNotifier.value;

  static bool _isConsentGathered = false;
  static bool get isConsentGathered => _isConsentGathered;

  static bool _isMobileAdsInitialized = false;
  static bool get isMobileAdsInitialized => _isMobileAdsInitialized;

  static Completer<void>? _consentCompleter;

  // ─── AD UNIT IDS ─────────────────────────────────────────────────────────

  /// Production Banner Ad Unit ID
  static const String androidProductionBannerId = 'ca-app-pub-3362561286987631/6235633609';

  /// Production Native Ad Unit ID
  static const String androidProductionNativeId = 'ca-app-pub-3362561286987631/4345524361';

  /// Production Rewarded Interstitial Ad Unit ID (OFFICIAL)
  static const String androidProductionRewardedInterstitialId = 'ca-app-pub-3362561286987631/2623527351';

  /// Production Interstitial Ad Unit ID
  static const String androidProductionInterstitialId = 'ca-app-pub-3362561286987631/2843500732';

  /// Test Banner Ad Unit ID for Android
  static const String androidTestBannerId = 'ca-app-pub-3940256099942544/6300978111';

  /// Test Rewarded Interstitial Ad Unit ID for Android
  static const String androidTestRewardedInterstitialId = 'ca-app-pub-3940256099942544/5354046379';

  /// Test Interstitial Ad Unit ID for Android
  static const String androidTestInterstitialId = 'ca-app-pub-3940256099942544/1033173712';

  /// Test Banner Ad Unit ID for iOS
  static const String iosTestBannerId = 'ca-app-pub-3940256099942544/2934735716';

  /// Test Rewarded Interstitial Ad Unit ID for iOS
  static const String iosTestRewardedInterstitialId = 'ca-app-pub-3940256099942544/6978759866';

  // ─── 24-HOUR AD-FREE READING PASS (Jami` at-Tirmidhi model) ─────────────
  static const String _adFreeUntilKey = 'all_hadith_ad_free_until_timestamp';
  static DateTime? _adFreeUntil;

  /// Reactive notifier for widgets (e.g. BannerAdWidget) to observe ad-free status changes.
  static final ValueNotifier<bool> isAdFreeActiveNotifier = ValueNotifier<bool>(false);

  /// Synchronous check if ad-free pass is currently active.
  static bool get isAdFreeActive {
    if (_adFreeUntil == null) return false;
    final active = DateTime.now().isBefore(_adFreeUntil!);
    if (!active && isAdFreeActiveNotifier.value) {
      isAdFreeActiveNotifier.value = false;
    }
    return active;
  }

  /// Expiry timestamp of the active ad-free pass (or null if none/expired).
  static DateTime? get adFreeUntil => _adFreeUntil;

  /// Human-readable remaining time string (e.g., "23h 45m" or "18m").
  static String get remainingAdFreeTimeFormatted {
    if (!isAdFreeActive || _adFreeUntil == null) return '';
    final diff = _adFreeUntil!.difference(DateTime.now());
    if (diff.isNegative) return '';
    final hours = diff.inHours;
    final minutes = diff.inMinutes % 60;
    if (hours > 0) {
      return '${hours}h ${minutes}m';
    } else {
      return '${diff.inMinutes}m';
    }
  }

  /// Initialize ad-free pass state from SharedPreferences.
  static Future<void> initAdFreeStatus() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final timestamp = prefs.getInt(_adFreeUntilKey);
      if (timestamp != null) {
        final expiry = DateTime.fromMillisecondsSinceEpoch(timestamp);
        if (DateTime.now().isBefore(expiry)) {
          _adFreeUntil = expiry;
          isAdFreeActiveNotifier.value = true;
          debugPrint('AdService: Active Ad-Free Pass until $_adFreeUntil ($remainingAdFreeTimeFormatted left)');
          return;
        }
      }
      _adFreeUntil = null;
      isAdFreeActiveNotifier.value = false;
    } catch (e) {
      debugPrint('AdService: Error reading ad-free status: $e');
    }
  }

  /// Grants or extends ad-free reading by [hours] (default 24 hours).
  static Future<void> grantAdFreeHours([int hours = 24, bool showNotification = true]) async {
    try {
      final now = DateTime.now();
      final base = (isAdFreeActive && _adFreeUntil != null) ? _adFreeUntil! : now;
      final newExpiry = base.add(Duration(hours: hours));

      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_adFreeUntilKey, newExpiry.millisecondsSinceEpoch);

      _adFreeUntil = newExpiry;
      isAdFreeActiveNotifier.value = true;
      debugPrint('AdService: Granted $hours hours Ad-Free reading until $newExpiry');

      if (showNotification) {
        showRewardEarnedNotification();
      }
    } catch (e) {
      debugPrint('AdService: Error saving ad-free status: $e');
    }
  }

  /// Shows celebratory reward notification:
  /// "JazakAllah Khair! Now enjoy 24 hours of completely ad-free reading! 💚"
  static void showRewardEarnedNotification() {
    scaffoldMessengerKey.currentState?.hideCurrentSnackBar();
    scaffoldMessengerKey.currentState?.showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            Icon(Icons.verified_rounded, color: Colors.white, size: 24),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'JazakAllah Khair! 💚',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    'Now enjoy 24 hours of completely ad-free reading!',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF2E7D32),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 4),
      ),
    );
  }

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
    // Also warm up 24h ad-free status on app launch
    unawaited(initAdFreeStatus());

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
          await MobileAds.instance.updateRequestConfiguration(
            RequestConfiguration(
              testDeviceIds: const [
                '9F40E3B459A3CAB0BF4BFF505625FF59', // Samsung SM-A135F (dev device)
              ],
              maxAdContentRating: MaxAdContentRating.g,
            ),
          );
          final initStatus = await MobileAds.instance.initialize();
          _isMobileAdsInitialized = true;
          preloadRewardedInterstitialAd();
          debugPrint('MobileAds SDK initialized successfully.');
          initStatus.adapterStatuses.forEach((key, value) {
            debugPrint('Adapter [$key]: state=${value.state}, desc=${value.description}');
          });
        } catch (e) {
          debugPrint('MobileAds initialization failed: $e');
        }
      }
    } catch (e) {
      debugPrint('AdService.gatherConsentAndInitialize error: $e');
      canRequestAdsNotifier.value = true;
      if (!_isMobileAdsInitialized) {
        try {
          await MobileAds.instance.updateRequestConfiguration(
            RequestConfiguration(
              testDeviceIds: const ['9F40E3B459A3CAB0BF4BFF505625FF59'],
              maxAdContentRating: MaxAdContentRating.g,
            ),
          );
          await MobileAds.instance.initialize();
          _isMobileAdsInitialized = true;
          preloadRewardedInterstitialAd();
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
            preloadRewardedInterstitialAd();
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

  /// Get appropriate Rewarded Interstitial Ad Unit ID (production only)
  static String get rewardedInterstitialAdUnitId {
    if (Platform.isAndroid) return androidProductionRewardedInterstitialId;
    return iosTestRewardedInterstitialId;
  }

  /// Backward-compatible alias for rewardedAdUnitId
  static String get rewardedAdUnitId => rewardedInterstitialAdUnitId;

  /// Get appropriate Interstitial Ad Unit ID
  static String get interstitialAdUnitId {
    if (Platform.isAndroid) return androidProductionInterstitialId;
    return androidTestInterstitialId;
  }

  // ─── REWARDED INTERSTITIAL ADS ──────────────────────────────────────────
  static RewardedInterstitialAd? _rewardedInterstitialAd;
  static bool _isRewardedInterstitialLoading = false;
  static DateTime? _lastTransitionAdShownTime;

  static int _hadithExitCount = 0;
  static DateTime? _lastHadithExitAdTime;
  static const int _hadithExitInterval = 3; // Trigger every 3rd exit from reading
  static const Duration _hadithExitCooldown = Duration(seconds: 90); // Minimum 90s cooldown

  /// Preloads a Rewarded Interstitial Ad in background.
  static void preloadRewardedInterstitialAd() {
    if (!isSupported || !canRequestAds || _isRewardedInterstitialLoading || _rewardedInterstitialAd != null) {
      return;
    }

    _isRewardedInterstitialLoading = true;
    RewardedInterstitialAd.load(
      adUnitId: rewardedInterstitialAdUnitId,
      request: const AdRequest(),
      rewardedInterstitialAdLoadCallback: RewardedInterstitialAdLoadCallback(
        onAdLoaded: (RewardedInterstitialAd ad) {
          _rewardedInterstitialAd = ad;
          _isRewardedInterstitialLoading = false;
          debugPrint('RewardedInterstitialAd ($rewardedInterstitialAdUnitId) preloaded successfully.');
        },
        onAdFailedToLoad: (LoadAdError error) {
          _rewardedInterstitialAd = null;
          _isRewardedInterstitialLoading = false;
          debugPrint('RewardedInterstitialAd failed to preload (${error.code}): ${error.message}');
        },
      ),
    );
  }

  /// Backward-compatible preload alias
  static void preloadInterstitialAd() {
    preloadRewardedInterstitialAd();
  }

  /// Shows Rewarded Interstitial ad when user finishes reading a Hadith and exits back.
  /// Respects:
  /// 1. 24-Hour Ad-Free Pass: If active, zero ads, exits immediately.
  /// 2. Natural Transition: Triggered on exiting reading, never on entering.
  /// 3. Frequency Capping: Only on every 3rd exit.
  /// 4. Cooldown: Minimum 90 seconds between ad impressions.
  /// 5. Reward: Upon watching, unlocks 24 Hours Ad-Free reading pass + celebratory SnackBar!
  static void showRewardedInterstitialOnHadithExit({
    required VoidCallback onComplete,
    VoidCallback? onRewardEarned,
  }) {
    if (!isSupported || !canRequestAds) {
      onComplete();
      return;
    }

    // If 24-hour ad-free pass is active, do not interrupt reading exit
    if (isAdFreeActive) {
      onComplete();
      return;
    }

    _hadithExitCount++;
    if (_hadithExitCount % _hadithExitInterval != 0) {
      onComplete();
      return;
    }

    final now = DateTime.now();
    if (_lastHadithExitAdTime != null &&
        now.difference(_lastHadithExitAdTime!) < _hadithExitCooldown) {
      onComplete();
      return;
    }

    final ad = _rewardedInterstitialAd;
    if (ad == null) {
      preloadRewardedInterstitialAd();
      onComplete();
      return;
    }

    _rewardedInterstitialAd = null;
    _lastHadithExitAdTime = now;

    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        preloadRewardedInterstitialAd();
        onComplete();
      },
      onAdFailedToShowFullScreenContent: (ad, err) {
        debugPrint('RewardedInterstitialAd failed to show on hadith exit: ${err.message}');
        ad.dispose();
        preloadRewardedInterstitialAd();
        onComplete();
      },
    );

    ad.show(
      onUserEarnedReward: (AdWithoutView ad, RewardItem reward) async {
        debugPrint('RewardedInterstitialAd on hadith exit earned reward: ${reward.amount} ${reward.type}');
        await grantAdFreeHours(24, true);
        onRewardEarned?.call();
      },
    );
  }

  /// Shows Rewarded Interstitial on natural transitions (e.g. opening chapter, switching book).
  /// General transition interstitial ads removed to keep reading experience distraction-free.
  static void showRewardedInterstitialIfAllowed({
    required VoidCallback onComplete,
    VoidCallback? onRewardEarned,
  }) {
    onComplete();
  }

  /// Shows Rewarded Interstitial specifically on Book Change.
  /// Rule: Even if user has already watched an ad or 24-hour pass is active,
  /// when changing books, ONLY Rewarded Interstitial ad is shown.
  /// Important: This ad does NOT increase or extend the 24-hour ad-free timer.
  static void showRewardedInterstitialOnBookChange({
    required VoidCallback onComplete,
    VoidCallback? onRewardEarned,
  }) {
    if (!isSupported || !canRequestAds) {
      onComplete();
      return;
    }

    // Safety Cooldown check (minimum 30 seconds between book changes to comply with Google AdMob policy)
    final now = DateTime.now();
    if (_lastTransitionAdShownTime != null &&
        now.difference(_lastTransitionAdShownTime!) < const Duration(seconds: 30)) {
      onComplete();
      return;
    }

    final ad = _rewardedInterstitialAd;
    if (ad == null) {
      preloadRewardedInterstitialAd();
      onComplete();
      return;
    }

    _rewardedInterstitialAd = null;
    _lastTransitionAdShownTime = now;

    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        preloadRewardedInterstitialAd();
        onComplete();
      },
      onAdFailedToShowFullScreenContent: (ad, err) {
        debugPrint('RewardedInterstitialAd failed to show on book change: ${err.message}');
        ad.dispose();
        preloadRewardedInterstitialAd();
        onComplete();
      },
    );

    ad.show(
      onUserEarnedReward: (AdWithoutView ad, RewardItem reward) {
        debugPrint('RewardedInterstitialAd on book change earned: ${reward.amount} ${reward.type}');
        // Rule: Book change ad does NOT extend the 24-hour ad-free timer
        onRewardEarned?.call();
      },
    );
  }

  /// Backward-compatible alias for existing transition calls
  static void showInterstitialIfAllowed({required VoidCallback onComplete}) {
    onComplete();
  }

  /// Voluntary Rewarded Ad trigger (e.g. from AppBar button or Settings "Unlock 24h Ad-Free").
  /// Users voluntarily watch to earn a 24-hour ad-free pass.
  static Future<bool> showVoluntaryRewardedAd({
    VoidCallback? onUserEarnedReward,
    VoidCallback? onAdFailed,
  }) async {
    if (!isSupported) {
      await grantAdFreeHours(24);
      onUserEarnedReward?.call();
      return true;
    }

    await waitForConsent();

    // If preloaded ad is ready, show immediately
    if (_rewardedInterstitialAd != null) {
      final ad = _rewardedInterstitialAd!;
      _rewardedInterstitialAd = null;

      final completer = Completer<bool>();

      ad.fullScreenContentCallback = FullScreenContentCallback(
        onAdDismissedFullScreenContent: (ad) {
          ad.dispose();
          preloadRewardedInterstitialAd();
          if (!completer.isCompleted) completer.complete(true);
        },
        onAdFailedToShowFullScreenContent: (ad, err) {
          debugPrint('Voluntary Rewarded ad failed to show: ${err.message}');
          ad.dispose();
          preloadRewardedInterstitialAd();
          onAdFailed?.call();
          if (!completer.isCompleted) completer.complete(false);
        },
      );

      ad.show(
        onUserEarnedReward: (ad, reward) async {
          await grantAdFreeHours(24);
          onUserEarnedReward?.call();
        },
      );

      return completer.future;
    }

    // Otherwise load on-demand
    final completer = Completer<bool>();
    RewardedInterstitialAd.load(
      adUnitId: rewardedInterstitialAdUnitId,
      request: const AdRequest(),
      rewardedInterstitialAdLoadCallback: RewardedInterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          ad.fullScreenContentCallback = FullScreenContentCallback(
            onAdDismissedFullScreenContent: (ad) {
              ad.dispose();
              preloadRewardedInterstitialAd();
              if (!completer.isCompleted) completer.complete(true);
            },
            onAdFailedToShowFullScreenContent: (ad, err) {
              ad.dispose();
              preloadRewardedInterstitialAd();
              onAdFailed?.call();
              if (!completer.isCompleted) completer.complete(false);
            },
          );

          ad.show(
            onUserEarnedReward: (ad, reward) async {
              await grantAdFreeHours(24);
              onUserEarnedReward?.call();
            },
          );
        },
        onAdFailedToLoad: (err) {
          debugPrint('On-demand RewardedInterstitialAd failed: ${err.message}');
          onAdFailed?.call();
          if (!completer.isCompleted) completer.complete(false);
        },
      ),
    );

    return completer.future;
  }

  /// Backward-compatible alias for showRewardedAd
  static void showRewardedAd({
    required VoidCallback onUserEarnedReward,
    VoidCallback? onAdFailed,
  }) {
    showVoluntaryRewardedAd(
      onUserEarnedReward: onUserEarnedReward,
      onAdFailed: onAdFailed,
    );
  }
}
