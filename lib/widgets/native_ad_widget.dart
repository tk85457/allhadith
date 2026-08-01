import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../core/ads/ad_service.dart';
import '../theme/app_theme.dart';

class NativeAdCardWidget extends StatefulWidget {
  final String? adUnitId;

  const NativeAdCardWidget({
    super.key,
    this.adUnitId,
  });

  @override
  State<NativeAdCardWidget> createState() => _NativeAdCardWidgetState();
}

class _NativeAdCardWidgetState extends State<NativeAdCardWidget> {
  BannerAd? _inlineAd;
  bool _isAdLoaded = false;
  Timer? _retryTimer;

  @override
  void initState() {
    super.initState();
    _loadAd();
  }

  void _loadAd() {
    if (!AdService.isSupported) return;

    _inlineAd?.dispose();
    _inlineAd = null;

    final unitId = widget.adUnitId ?? AdService.nativeAdUnitId;

    _inlineAd = BannerAd(
      adUnitId: unitId,
      request: const AdRequest(),
      size: AdSize.mediumRectangle, // 300x250 in-feed ad format
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          if (mounted) {
            setState(() {
              _isAdLoaded = true;
            });
          }
        },
        onAdFailedToLoad: (ad, err) {
          debugPrint('InFeed Native BannerAd failed to load: ${err.message}');
          ad.dispose();
          if (mounted) {
            setState(() {
              _isAdLoaded = false;
              _inlineAd = null;
            });
            _retryTimer?.cancel();
            _retryTimer = Timer(const Duration(seconds: 25), () {
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
    _inlineAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!AdService.isSupported || !_isAdLoaded || _inlineAd == null) {
      return const SizedBox.shrink();
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.cardDark : Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isDark ? Colors.grey.shade800 : Colors.grey.shade300,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.amber.shade700,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  'Ad / اشتہار',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Icon(
                Icons.info_outline,
                size: 14,
                color: isDark ? Colors.grey.shade500 : Colors.grey.shade400,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Center(
            child: SizedBox(
              width: _inlineAd!.size.width.toDouble(),
              height: _inlineAd!.size.height.toDouble(),
              child: AdWidget(ad: _inlineAd!),
            ),
          ),
        ],
      ),
    );
  }
}
