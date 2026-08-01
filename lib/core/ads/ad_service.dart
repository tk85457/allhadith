import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class AdService {
  static bool _isInitialized = false;

  /// Test Banner Ad Unit ID for Android
  static const String androidTestBannerId = 'ca-app-pub-3940256099942544/6300978111';

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

  /// Get appropriate Banner Ad Unit ID (Test or Production)
  static String get bannerAdUnitId {
    if (kDebugMode) {
      if (Platform.isAndroid) return androidTestBannerId;
      if (Platform.isIOS) return iosTestBannerId;
    }
    // Production Banner Ad Unit ID fallback (if not set in debug)
    if (Platform.isAndroid) return androidTestBannerId;
    return iosTestBannerId;
  }
}
