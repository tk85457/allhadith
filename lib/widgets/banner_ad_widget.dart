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

  @override
  void initState() {
    super.initState();
    _loadAd();
  }

  void _loadAd() {
    if (!AdService.isSupported) return;

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
          }
        },
        onAdFailedToLoad: (ad, err) {
          debugPrint('BannerAd failed to load: ${err.message}');
          ad.dispose();
          if (mounted) {
            setState(() {
              _isAdLoaded = false;
              _bannerAd = null;
            });
            // Auto retry loading banner ad after 20 seconds if it failed
            _retryTimer?.cancel();
            _retryTimer = Timer(const Duration(seconds: 20), () {
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
    _retryTimer?.cancel();
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
