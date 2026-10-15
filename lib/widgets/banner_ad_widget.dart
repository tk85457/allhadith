import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../core/ads/ad_service.dart';

/// Production-ready banner ad widget.
///
/// Features:
/// - Adaptive banner size (better CPM than fixed 320×50)
/// - Smart backoff retry: 3 s → 10 s → 30 s → 60 s
/// - Zero UI impact when no ad — returns SizedBox.shrink()
/// - Properly disposes ad on widget removal (low memory)
/// - Pauses retry when app is backgrounded
/// - Safe against mount/unmount races
class BannerAdWidget extends StatefulWidget {
  /// Override the ad unit ID (leave null to use AdService default).
  final String? adUnitId;

  const BannerAdWidget({super.key, this.adUnitId});

  @override
  State<BannerAdWidget> createState() => _BannerAdWidgetState();
}

class _BannerAdWidgetState extends State<BannerAdWidget>
    with WidgetsBindingObserver {
  BannerAd? _bannerAd;
  bool _isAdLoaded = false;
  bool _isLoadingAd = false;
  Timer? _retryTimer;
  int _retryAttempt = 0;

  // Cached adaptive size — resolved once per widget instance.
  AdSize? _resolvedSize;

  // ─── Lifecycle ────────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    AdService.canRequestAdsNotifier.addListener(_onConsentChanged);
    AdService.isAdFreeActiveNotifier.addListener(_onAdFreeChanged);
    _checkConsentAndLoad();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (AdService.isAdFreeActive) {
      _retryTimer?.cancel();
      return;
    }

    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      // Pause retries while app is in background — saves battery / network.
      _retryTimer?.cancel();
    } else if (state == AppLifecycleState.resumed) {
      // Resume: request a fresh ad if none is showing.
      if (!_isAdLoaded || _bannerAd == null) {
        _retryAttempt = 0;
        _loadAd();
      }
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _retryTimer?.cancel();
    AdService.canRequestAdsNotifier.removeListener(_onConsentChanged);
    AdService.isAdFreeActiveNotifier.removeListener(_onAdFreeChanged);
    _bannerAd?.dispose();
    super.dispose();
  }

  // ─── Consent & Load ───────────────────────────────────────────────────────

  /// Fires when 24-hour ad-free state toggles.
  void _onAdFreeChanged() {
    if (!mounted) return;
    if (AdService.isAdFreeActive) {
      _retryTimer?.cancel();
      _bannerAd?.dispose();
      setState(() {
        _bannerAd = null;
        _isAdLoaded = false;
        _isLoadingAd = false;
      });
    } else {
      _loadAd();
    }
  }

  /// Fires when AdService consent state changes (e.g. UMP form completed).
  void _onConsentChanged() {
    if (!mounted) return;
    if (AdService.isAdFreeActive) return;
    if (_bannerAd == null && !_isAdLoaded && !_isLoadingAd) {
      _loadAd();
    }
  }

  /// Entry point called from initState — waits for consent then loads.
  Future<void> _checkConsentAndLoad() async {
    if (!AdService.isSupported || AdService.isAdFreeActive) return;
    if (!AdService.isConsentGathered) {
      await AdService.waitForConsent();
      if (!mounted) return;
    }
    _loadAd();
  }

  /// Resolves adaptive banner size once, then creates and loads the BannerAd.
  Future<void> _loadAd() async {
    if (!AdService.isSupported || _isLoadingAd || AdService.isAdFreeActive) return;
    _isLoadingAd = true;
    _retryTimer?.cancel();

    // Resolve adaptive size once per widget instance (cached).
    if (_resolvedSize == null && mounted) {
      final screenWidth = MediaQuery.of(context).size.width.truncate();
      final adaptive = await AdSize
          .getCurrentOrientationAnchoredAdaptiveBannerAdSize(screenWidth);
      // Fallback to standard banner if platform call fails.
      _resolvedSize = adaptive ?? AdSize.banner;
    }

    if (!mounted) {
      _isLoadingAd = false;
      return;
    }

    // Network check: agar internet band ho toh bekaar me request na bheje
    try {
      final lookup = await InternetAddress.lookup('google.com')
          .timeout(const Duration(seconds: 3));
      if (lookup.isEmpty || lookup[0].rawAddress.isEmpty) {
        _isLoadingAd = false;
        _scheduleRetry();
        return;
      }
    } catch (_) {
      _isLoadingAd = false;
      _scheduleRetry();
      return;
    }

    if (!mounted) {
      _isLoadingAd = false;
      return;
    }

    final unitId = widget.adUnitId ?? AdService.bannerAdUnitId;
    final size = _resolvedSize ?? AdSize.banner;

    BannerAd(
      adUnitId: unitId,
      request: const AdRequest(),
      size: size,
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          if (!mounted) {
            ad.dispose();
            return;
          }
          final old = _bannerAd;
          setState(() {
            _bannerAd = ad as BannerAd;
            _isAdLoaded = true;
            _isLoadingAd = false;
          });
          old?.dispose();

          // Rule: Jab ad fill ho jaye, toh saara retry completely BAND!
          _retryAttempt = 0;
          _retryTimer?.cancel();
          _retryTimer = null;
        },
        onAdFailedToLoad: (ad, err) {
          debugPrint('BannerAd ($unitId) failed [${err.code}]: ${err.message}');
          ad.dispose();
          if (!mounted) return;
          _isLoadingAd = false;

          // Agar pehle se koi ad visible hai, usse rehne dein
          if (_bannerAd != null && _isAdLoaded) return;

          setState(() {
            _isAdLoaded = false;
            _bannerAd = null;
          });

          // Rule: Agar ad na dikhe ya no-fill ho, toh 5 second baad retry kare
          _scheduleRetry();
        },
      ),
    ).load();
  }

  /// 5 second fixed retry: sirf tab chale jab koi ad loaded NA ho
  void _scheduleRetry() {
    _retryTimer?.cancel();
    if (_isAdLoaded && _bannerAd != null) return;

    _retryAttempt++;
    // Smart backoff to save battery & CPU on low-end phones
    final delaySec = _retryAttempt <= 2 ? 15 : 45;
    _retryTimer = Timer(Duration(seconds: delaySec), () {
      if (mounted && !_isAdLoaded) {
        _loadAd();
      }
    });
  }

  // ─── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    // Return zero-size widget while loading, when no fill, or when 24h Ad-Free pass is active —
    // UI layout remains completely unchanged.
    if (AdService.isAdFreeActive || !AdService.isSupported || !_isAdLoaded || _bannerAd == null) {
      return const SizedBox.shrink();
    }

    return SafeArea(
      top: false,
      child: RepaintBoundary(
        child: SizedBox(
          width: _bannerAd!.size.width.toDouble(),
          height: _bannerAd!.size.height.toDouble(),
          child: AdWidget(
            key: ValueKey(_bannerAd.hashCode),
            ad: _bannerAd!,
          ),
        ),
      ),
    );
  }
}
