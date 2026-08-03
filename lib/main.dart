import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'theme/app_theme.dart';
import 'core/router.dart';
import 'core/ads/ad_service.dart';
import 'features/settings/settings_provider.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      systemNavigationBarColor: Colors.transparent,
    ),
  );

  // Initialize AdMob Mobile Ads SDK asynchronously without blocking first frame
  AdService.initialize();

  // Cheap, synchronous factory wiring for web/desktop — no I/O, safe to run
  // before the first frame.
  if (kIsWeb) {
    databaseFactory = databaseFactoryFfiWeb;
  } else if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }

  // COLD START FIX: previously main() awaited SharedPreferences.getInstance()
  // AND a full Isar DB warm-up (which, on first launch, copies the bundled
  // SQLite asset to disk and migrates every hadith into Isar) before ever
  // calling runApp(). That blocked the very first frame from being drawn,
  // which is exactly what Android/Play Console measure as "cold start" /
  // "time to initial display". Now we call runApp() immediately; the tiny
  // bit of real async work left (SharedPreferences) happens behind a
  // near-instant loading frame, and the heavy Isar/SQLite warm-up already
  // lives in SplashScreen (features/splash/splash_screen.dart), which runs
  // *after* the first frame is on screen.
  runApp(const _Bootstrap());
}

/// Loads [SharedPreferences] before mounting the real app. This is fast
/// (no large I/O), so this shows for at most a frame or two — but doing it
/// here (instead of blocking main()) lets Flutter draw its first frame
/// immediately, which is what fixes slow/cold app starts.
class _Bootstrap extends StatelessWidget {
  const _Bootstrap();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<SharedPreferences>(
      future: SharedPreferences.getInstance(),
      builder: (context, snapshot) {
        final prefs = snapshot.data;
        if (prefs == null) {
          return const _BootLoading();
        }
        return ProviderScope(
          overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
          child: const SahihBukhariApp(),
        );
      },
    );
  }
}

/// Matches the native launch theme's background so there is no visible
/// flash/jump between the native splash and the first Flutter frame.
class _BootLoading extends StatelessWidget {
  const _BootLoading();

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: AppTheme.primaryDark,
        body: SizedBox.shrink(),
      ),
    );
  }
}

class SahihBukhariApp extends ConsumerWidget {
  const SahihBukhariApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);

    final primaryColor = AppTheme.getPrimaryColor(settings.uiColor);

    return MaterialApp.router(
      title: 'Al-Bukhari',
      debugShowCheckedModeBanner: false,
      theme: settings.isDarkMode
          ? AppTheme.darkTheme(primaryColor)
          : AppTheme.lightTheme(primaryColor),
      routerConfig: goRouter,
      builder: (context, child) {
        if (child == null) {
          return const SizedBox.shrink();
        }

        return SafeArea(top: false, left: false, right: false, child: child);
      },
    );
  }
}
