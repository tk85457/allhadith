import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../theme/app_theme.dart';
import '../../data/database/app_database.dart';
import '../../core/ads/ad_service.dart';
import '../../core/services/in_app_review_service.dart';
import '../../core/services/notification_service.dart';

// Read version from pubspec.yaml at build time
const String appVersion = String.fromEnvironment('APP_VERSION', defaultValue: '1.0.3');

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _iconController;
  late Animation<double> _iconScale;
  late Animation<double> _iconOpacity;
  late Animation<double> _circleScale;
  late Animation<double> _circleOpacity;
  late Animation<double> _glowOpacity;

  @override
  void initState() {
    super.initState();

    _iconController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _iconScale = Tween<double>(begin: 0.15, end: 1.0).animate(
      CurvedAnimation(
        parent: _iconController,
        curve: const Interval(0.0, 0.7, curve: Curves.easeOutBack),
      ),
    );

    _iconOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _iconController,
        curve: const Interval(0.0, 0.3, curve: Curves.easeIn),
      ),
    );

    _circleScale = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(
        parent: _iconController,
        curve: const Interval(0.4, 0.8, curve: Curves.elasticOut),
      ),
    );

    _circleOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _iconController,
        curve: const Interval(0.35, 0.6, curve: Curves.easeIn),
      ),
    );

    _glowOpacity = Tween<double>(begin: 0.0, end: 0.35).animate(
      CurvedAnimation(
        parent: _iconController,
        curve: const Interval(0.6, 1.0, curve: Curves.easeInOut),
      ),
    );

    Future.delayed(const Duration(milliseconds: 50), () {
      if (mounted) _iconController.forward();
    });

    _initAndNavigate();
  }

  @override
  void dispose() {
    _iconController.dispose();
    super.dispose();
  }

  Future<void> _initAndNavigate() async {
    // 1. Fire non-critical background services without blocking splash
    unawaited(AdService.gatherConsentAndInitialize().catchError((e) {
      debugPrint('AdService init handled: $e');
      return AdService.canRequestAds;
    }));
    NotificationService.initialize();
    InAppReviewService.recordAppOpen();

    // 2. Load essential local DB and preferences in parallel
    final results = await Future.wait([
      // Snappy minimum splash duration (600ms) for clean branding transition
      Future.delayed(const Duration(milliseconds: 600)),
      AppDatabase.instance.database,
      SharedPreferences.getInstance(),
    ]);

    if (!mounted) return;

    final prefs = results[2] as SharedPreferences;
    final onboardingDone = prefs.getBool('onboarding_done') ?? false;
    context.go(onboardingDone ? '/books' : '/language-select');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppTheme.terracottaDark,
              AppTheme.terracottaPrimary,
              AppTheme.terracottaLight,
            ],
            stops: [0.0, 0.55, 1.0],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 60),

                // Animated Icon with isolated RepaintBoundary
                RepaintBoundary(
                  child: AnimatedBuilder(
                    animation: _iconController,
                    builder: (context, child) {
                      final yOffset = (1.0 - _iconScale.value) * -100;
                      return Opacity(
                        opacity: _iconOpacity.value,
                        child: Transform.translate(
                          offset: Offset(0, yOffset),
                          child: Transform.scale(
                            scale: _iconScale.value,
                            child: Container(
                              width: 170,
                              height: 170,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: AppTheme.desertDuneGold.withValues(
                                      alpha: _glowOpacity.value,
                                    ),
                                    blurRadius: 16,
                                    spreadRadius: 2,
                                  ),
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.25),
                                    blurRadius: 10,
                                    offset: const Offset(0, 6),
                                  ),
                                ],
                              ),
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  if (_circleScale.value > 0.1)
                                    Opacity(
                                      opacity: (_circleOpacity.value * 0.4).clamp(0.0, 1.0),
                                      child: Container(
                                        width: 170,
                                        height: 170,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                            color: AppTheme.desertDuneGold,
                                            width: 1.5,
                                          ),
                                        ),
                                      ),
                                    ),

                                  Opacity(
                                    opacity: _circleOpacity.value,
                                    child: Transform.scale(
                                      scale: _circleScale.value,
                                      child: Container(
                                        width: 165,
                                        height: 165,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          gradient: RadialGradient(
                                            colors: [
                                              AppTheme.desertDuneGold.withValues(alpha: 0.2),
                                              Colors.transparent,
                                            ],
                                          ),
                                          border: Border.all(
                                            color: AppTheme.desertDuneGold.withValues(
                                              alpha: 0.4,
                                            ),
                                            width: 2.5,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  Container(
                                    width: 155,
                                    height: 155,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      boxShadow: [
                                        BoxShadow(
                                          color: AppTheme.desertDuneGold.withValues(alpha: 0.25),
                                          blurRadius: 12,
                                          spreadRadius: 1,
                                        ),
                                      ],
                                    ),
                                    child: ClipOval(
                                      child: Image.asset(
                                        'assets/icon/icon_circular.png',
                                        width: 155,
                                        height: 155,
                                        cacheWidth: 310,
                                        cacheHeight: 310,
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),

                const SizedBox(height: 32),

                Text(
                  'بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ',
                  style: GoogleFonts.amiri(
                    fontSize: 24,
                    color: AppTheme.desertDuneGold,
                    fontWeight: FontWeight.bold,
                  ),
                  textDirection: TextDirection.rtl,
                )
                    .animate()
                    .fade(delay: 600.ms, duration: 600.ms)
                    .slideY(begin: 0.3, end: 0, curve: Curves.easeOut),

                const SizedBox(height: 20),

                Text(
                  'سب احادیث — صحاح ستہ',
                  style: GoogleFonts.amiri(
                    fontSize: 34,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    shadows: const [
                      Shadow(
                        color: Colors.black45,
                        offset: Offset(0, 2),
                        blurRadius: 6,
                      ),
                    ],
                  ),
                  textDirection: TextDirection.rtl,
                )
                    .animate()
                    .fade(delay: 800.ms, duration: 600.ms)
                    .slideY(begin: 0.5, end: 0, curve: Curves.easeOut),

                const SizedBox(height: 8),

                Text(
                  'All Hadith — Kutub al-Sittah',
                  style: GoogleFonts.rubik(
                    fontSize: 18,
                    color: AppTheme.desertDuneGold,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1.5,
                  ),
                )
                    .animate()
                    .fade(delay: 1000.ms, duration: 600.ms)
                    .slideY(begin: 0.5, end: 0, curve: Curves.easeOut),

                const SizedBox(height: 6),

                Text(
                  'The 6 Canonical Collections of Hadith',
                  style: GoogleFonts.rubik(
                    fontSize: 12,
                    color: Colors.white.withValues(alpha: 0.8),
                    letterSpacing: 1,
                  ),
                ).animate().fade(delay: 1200.ms, duration: 500.ms),

                const SizedBox(height: 40),

                SizedBox(
                  width: 180,
                  child: LinearProgressIndicator(
                    backgroundColor: Colors.white.withValues(alpha: 0.15),
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      AppTheme.desertDuneGold,
                    ),
                    minHeight: 2.5,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ).animate().fade(delay: 1400.ms, duration: 400.ms),

                const SizedBox(height: 12),

                Text(
                  'Loading...',
                  style: GoogleFonts.rubik(
                    fontSize: 12,
                    color: AppTheme.desertDuneGold.withValues(alpha: 0.8),
                  ),
                ).animate().fade(delay: 1500.ms, duration: 400.ms),

                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
