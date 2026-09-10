import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../core/ads/ad_service.dart';

class BannerAdWidget extends StatefulWidget {
  final String? adUnitId;
  final AdSize adSize;

  const BannerAdWidget({
    super.key,
    this.adUnitId,
    this.adSize = AdSize.banner,
  });

  @override
  State<BannerAdWidget> createState() => _BannerAdWidgetState();
}

class _BannerAdWidgetState extends State<BannerAdWidget> {
  BannerAd? _bannerAd;
  bool _isAdLoaded = false;
  Timer? _retryTimer;
  Timer? _refreshTimer;

  /// Google AdMob Policy: Minimum allowed refresh rate is exactly 30 seconds.
  /// Anything faster violates AdMob invalid traffic / spam policies.
  static const Duration _adRefreshDuration = Duration(seconds: 30);

  /// Quick retry if an ad fails (4-5 seconds) so a fresh real ad is requested fast
  static const Duration _adRetryDuration = Duration(seconds: 5);

  @override
  void initState() {
    super.initState();
    AdService.canRequestAdsNotifier.addListener(_onConsentChanged);
    _checkConsentAndLoad();
  }

  void _onConsentChanged() {
    if (!mounted) return;
    if (_bannerAd == null && !_isAdLoaded) {
      _loadAd();
    }
  }

  Future<void> _checkConsentAndLoad() async {
    if (!AdService.isSupported) return;

    // Wait for the consent flow if it is still ongoing (e.g. app startup)
    if (!AdService.isConsentGathered) {
      await AdService.waitForConsent();
      if (!mounted) return;
    }

    _loadAd();
  }

  void _cancelTimers() {
    _retryTimer?.cancel();
    _refreshTimer?.cancel();
  }

  void _loadAd() {
    if (!AdService.isSupported) return;

    _cancelTimers();
    _bannerAd?.dispose();
    _bannerAd = null;

    final unitId = widget.adUnitId ?? AdService.bannerAdUnitId;

    _bannerAd = BannerAd(
      adUnitId: unitId,
      request: const AdRequest(),
      size: widget.adSize,
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          if (mounted) {
            setState(() {
              _isAdLoaded = true;
            });
            // Fastest policy-compliant auto-refresh (30s) to maximize impressions & eCPM
            _refreshTimer?.cancel();
            _refreshTimer = Timer(_adRefreshDuration, () {
              if (mounted) {
                _loadAd();
              }
            });
          }
        },
        onAdFailedToLoad: (ad, err) {
          debugPrint('BannerAd ($unitId) failed to load: ${err.message}');
          ad.dispose();
          if (mounted) {
            setState(() {
              _isAdLoaded = false;
              _bannerAd = null;
            });
            // Cooldown before retrying the real production ad
            _retryTimer?.cancel();
            _retryTimer = Timer(_adRetryDuration, () {
              if (mounted && !_isAdLoaded) {
                _loadAd();
              }
            });
          }
        },
      ),
    )..load();
  }

  @override
  void dispose() {
    AdService.canRequestAdsNotifier.removeListener(_onConsentChanged);
    _cancelTimers();
    _bannerAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!AdService.isSupported || !_isAdLoaded || _bannerAd == null) {
      return const SizedBox.shrink();
    }

    return Container(
      alignment: Alignment.center,
      width: _bannerAd!.size.width.toDouble(),
      height: _bannerAd!.size.height.toDouble(),
      margin: const EdgeInsets.symmetric(vertical: 6.0),
      child: AdWidget(ad: _bannerAd!),
    );
  }
}
