import 'package:flutter/material.dart';
import 'package:in_app_review/in_app_review.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

/// Official Google Play Native In-App Review Service:
/// 
/// 1. Native In-App Review (Automatic):
///    - Calls Google Play's official Native In-App Review dialog (`requestReview()`).
///    - User can give 1-5 stars & write review directly inside the app.
///    - Google Play automatically publishes the review.
///    - Triggers naturally after reading 3 Hadiths or saving a Bookmark.
/// 
/// 2. Direct Play Store Launch (Button tap):
///    - When user explicitly taps "Rate this App" in Settings, Menu, or About Screen,
///      it directly opens the official Google Play Store app page.
class InAppReviewService {
  static const String _keyHasRated = 'review_has_rated';
  static const String _keyHadithsReadCount = 'review_hadiths_read_count';
  static const String _keyLastPromptTime = 'review_last_prompt_timestamp';
  static const String _keyAppOpenCount = 'review_app_open_count';

  static const String packageName = 'com.taha.allhadithshahih';
  static final InAppReview _inAppReview = InAppReview.instance;

  // Fast in-memory session tracking
  static bool? _cachedHasRated;
  static int _sessionHadithsRead = 0;
  static bool _sessionPromptShown = false;

  /// Increment app launch count on startup
  static Future<void> recordAppOpen() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final count = prefs.getInt(_keyAppOpenCount) ?? 0;
      await prefs.setInt(_keyAppOpenCount, count + 1);
      _cachedHasRated = prefs.getBool(_keyHasRated) ?? false;
    } catch (_) {}
  }

  /// Mark rated permanently so automatic prompts don't repeat
  static Future<void> markRated() async {
    _cachedHasRated = true;
    _sessionPromptShown = true;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_keyHasRated, true);
    } catch (_) {}
  }

  /// ─── 1. GOOGLE PLAY NATIVE IN-APP REVIEW ───
  static Future<void> requestNativeReview({bool force = false}) async {
    if (!force) {
      if (_cachedHasRated == true || _sessionPromptShown) return;

      try {
        final prefs = await SharedPreferences.getInstance();
        _cachedHasRated = prefs.getBool(_keyHasRated) ?? false;
        if (_cachedHasRated == true) return;

        // Cooldown: at least 3 days between automatic review prompts
        final lastPrompt = prefs.getInt(_keyLastPromptTime);
        if (lastPrompt != null) {
          final diff = DateTime.now().difference(DateTime.fromMillisecondsSinceEpoch(lastPrompt));
          if (diff < const Duration(days: 3)) {
            return;
          }
        }
      } catch (_) {}
    }

    _sessionPromptShown = true;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_keyLastPromptTime, DateTime.now().millisecondsSinceEpoch);
    } catch (_) {}

    try {
      final isAvailable = await _inAppReview.isAvailable();
      if (isAvailable) {
        await _inAppReview.requestReview();
      }
    } catch (e) {
      debugPrint('Google Play native in-app review error: $e');
    }
  }

  static const String _keyDetailVisitsCount = 'review_detail_visits_count';

  /// Check and trigger Google Play Native In-App Review when entering Hadith Detail Screen.
  static Future<void> checkPromptOnHadithDetail() async {
    if (_cachedHasRated == true || _sessionPromptShown) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      _cachedHasRated = prefs.getBool(_keyHasRated) ?? false;
      if (_cachedHasRated == true) return;

      final visits = (prefs.getInt(_keyDetailVisitsCount) ?? 0) + 1;
      await prefs.setInt(_keyDetailVisitsCount, visits);

      // Only trigger on 2nd visit or beyond
      if (visits >= 2) {
        await Future.delayed(const Duration(milliseconds: 1000));
        await requestNativeReview();
      }
    } catch (_) {}
  }

  /// Track hadith reads and trigger Google Play Native In-App Review
  static Future<void> incrementHadithReadAndCheckPrompt(BuildContext context) async {
    _sessionHadithsRead++;

    if (_cachedHasRated == true || _sessionPromptShown) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      _cachedHasRated = prefs.getBool(_keyHasRated) ?? false;
      if (_cachedHasRated == true) return;

      final totalRead = (prefs.getInt(_keyHadithsReadCount) ?? 0) + 1;
      await prefs.setInt(_keyHadithsReadCount, totalRead);

      // Also trigger if reading 3+ hadiths
      if (totalRead == 3 || totalRead == 15 || _sessionHadithsRead == 5) {
        await Future.delayed(const Duration(milliseconds: 800));
        await requestNativeReview();
      }
    } catch (_) {}
  }

  /// Trigger native review when user bookmarks a hadith
  static Future<void> checkPromptOnAction(BuildContext context, {required String action}) async {
    if (_cachedHasRated == true || _sessionPromptShown) return;
    await Future.delayed(const Duration(milliseconds: 600));
    await requestNativeReview();
  }

  /// ─── 2. DIRECT GOOGLE PLAY STORE LAUNCH ───
  static Future<void> openGooglePlayStore() async {
    await markRated();

    final Uri marketUri = Uri.parse('market://details?id=$packageName');
    final Uri webUri = Uri.parse('https://play.google.com/store/apps/details?id=$packageName');

    // 1. Direct Play Store App launch (market://)
    try {
      final launched = await launchUrl(marketUri, mode: LaunchMode.externalApplication);
      if (launched) return;
    } catch (_) {}

    // 2. InAppReview plugin fallback
    try {
      await _inAppReview.openStoreListing();
      return;
    } catch (_) {}

    // 3. Web browser fallback
    try {
      await launchUrl(webUri, mode: LaunchMode.externalApplication);
    } catch (_) {}
  }

  /// Backward-compatible aliases
  static Future<void> triggerManualReview({required String appName}) async {
    await openGooglePlayStore();
  }

  static Future<void> showRatingDialog(BuildContext context, {bool isManual = false}) async {
    if (isManual) {
      await openGooglePlayStore();
    } else {
      await requestNativeReview();
    }
  }
}
