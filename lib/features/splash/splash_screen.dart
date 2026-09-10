import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../data/database/app_database.dart';
import '../../core/ads/ad_service.dart';
import '../../core/services/in_app_review_service.dart';

// Read version from pubspec.yaml at build time
const String appVersion = String.fromEnvironment('APP_VERSION', defaultValue: '1.1.3');

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

    _glowOpacity = Tween<double>(begin: 0.0, end: 0.25).animate(
      CurvedAnimation(
        parent: _iconController,
        curve: const Interval(0.6, 1.0, curve: Curves.easeInOut),
      ),
    );

    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) _iconController.forward();
    });

    // FIX: Load DB and prefs in parallel, with a minimum 2s splash wait
    _initAndNavigate();
  }

  @override
  void dispose() {
    _iconController.dispose();
    super.dispose();
  }

  Future<void> _initAndNavigate() async {
    // Start DB, prefs, and UMP consent flow in parallel — navigate once all are ready
    final results = await Future.wait([
      // Minimum splash duration (2 seconds — for animation)
      Future.delayed(const Duration(milliseconds: 2000)),
      // DB warm-up: first query will be fast afterwards
      AppDatabase.instance.database,
      // Load SharedPrefs in parallel as well
      SharedPreferences.getInstance(),
      // Google official UMP consent flow: requestConsentInfoUpdate -> loadAndShowConsentFormIfRequired -> canRequestAds
      AdService.gatherConsentAndInitialize().timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          debugPrint('AdService.gatherConsentAndInitialize timed out on splash.');
          return AdService.canRequestAds;
        },
      ),
      // Record app launch count for In-App Review (Rule: never on 1st open)
      InAppReviewService.recordAppOpen(),
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
              Color(0xFF0A7E47),
              Color(0xFF0F9D58),
              Color(0xFF14B866),
            ],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 60),

                // Animated Icon
                AnimatedBuilder(
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
                                  color: Colors.white.withValues(
                                    alpha: _glowOpacity.value,
                                  ),
                                  blurRadius: 30,
                                  spreadRadius: 10,
                                ),
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.2),
                                  blurRadius: 15,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                            ),
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                if (_circleScale.value > 0.1)
                                  Container(
                                    width: 170,
                                    height: 170,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: Colors.white.withValues(
                                          alpha: 0.2 * _circleOpacity.value,
                                        ),
                                        width: 2,
                                      ),
                                    ),
                                  )
                                      .animate(
                                        onPlay: (c) => c.repeat(),
                                      )
                                      .scale(
                                        duration: 2.seconds,
                                        begin: const Offset(1, 1),
                                        end: const Offset(1.2, 1.2),
                                      )
                                      .fadeOut(duration: 2.seconds),

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
                                            Colors.white.withValues(alpha: 0.2),
                                            Colors.transparent,
                                          ],
                                        ),
                                        border: Border.all(
                                          color: Colors.white.withValues(
                                            alpha: 0.4,
                                          ),
                                          width: 4,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                Container(
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: Colors.white,
                                      width: 2,
                                    ),
                                  ),
                                  child: ClipOval(
                                    child: Image.asset(
                                      'assets/icon/icon_circular.png',
                                      width: 150,
                                      height: 150,
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

                const SizedBox(height: 32),

                Text(
                  'بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ',
                  style: GoogleFonts.amiri(
                    fontSize: 22,
                    color: Colors.white.withValues(alpha: 0.9),
                    fontWeight: FontWeight.w400,
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
                    color: Colors.white.withValues(alpha: 0.9),
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
                    color: Colors.white.withValues(alpha: 0.7),
                    letterSpacing: 1,
                  ),
                ).animate().fade(delay: 1200.ms, duration: 500.ms),

                const SizedBox(height: 40),

                SizedBox(
                  width: 180,
                  child: LinearProgressIndicator(
                    backgroundColor: Colors.white.withValues(alpha: 0.15),
                    valueColor: AlwaysStoppedAnimation<Color>(
                      Colors.white.withValues(alpha: 0.6),
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
                    color: Colors.white.withValues(alpha: 0.5),
                  ),
                ).animate().fade(delay: 1500.ms, duration: 400.ms),

                const SizedBox(height: 20),

                Text(
                  'v$appVersion',
                  style: GoogleFonts.rubik(
                    fontSize: 11,
                    color: Colors.white.withValues(alpha: 0.35),
                  ),
                ).animate().fade(delay: 1700.ms, duration: 400.ms),

                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
