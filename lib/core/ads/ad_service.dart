import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class AdService {
  static bool _isInitialized = false;

  /// Production Banner Ad Unit ID
  static const String androidProductionBannerId = 'ca-app-pub-3362561286987631/2534015179';

  /// Production Native Ad Unit ID
  static String androidProductionNativeId = 'ca-app-pub-3362561286987631/2534015179';

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

  /// Get appropriate Banner Ad Unit ID (Test in debug, Production in release)
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
}
