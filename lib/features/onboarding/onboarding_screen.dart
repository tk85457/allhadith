import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _pageController = PageController();
  int _currentPage = 0;

  final _slides = const [
    _Slide(
      icon: Icons.menu_book_rounded,
      title: 'صحیح البخاری',
      subtitle: 'Sahih Al-Bukhari',
      description: 'The most authentic collection of Hadith, compiled by Imam Bukhari (rahimahullah). Over 7,500+ hadiths in Arabic, Urdu & English.',
      color: Color(0xFF1B5E20),
    ),
    _Slide(
      icon: Icons.search_rounded,
      title: 'تلاش کریں',
      subtitle: 'Powerful Search',
      description: 'Search hadiths by keyword, narrator, or topic. Find exactly what you need with filters for language & match type.',
      color: Color(0xFF00796B),
    ),
    _Slide(
      icon: Icons.bookmark_rounded,
      title: 'محفوظ کریں',
      subtitle: 'Bookmarks & Collections',
      description: 'Bookmark your favourite hadiths, create custom collections, and add personal notes. Your data stays safe.',
      color: Color(0xFF5D4037),
    ),
    _Slide(
      icon: Icons.auto_awesome,
      title: 'آج کی حدیث',
      subtitle: 'Daily Hadith & More',
      description: 'Get a new hadith every day, track your chapter progress, discover random hadiths, and share beautiful hadith cards.',
      color: Color(0xFF1565C0),
    ),
  ];

  void _onDone() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_done', true);
    if (mounted) {
      context.go('/home');
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Skip button
            Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: TextButton(
                  onPressed: _onDone,
                  child: Text(
                    'Skip',
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
                  ),
                ),
              ),
            ),
            // Page view
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: _slides.length,
                onPageChanged: (index) => setState(() => _currentPage = index),
                itemBuilder: (context, index) {
                  final slide = _slides[index];
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Center(
                      child: SingleChildScrollView(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(
                              width: 180,
                              height: 180,
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  if (index == 0)
                                    Container(
                                      width: 160,
                                      height: 160,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        border: Border.all(color: slide.color.withValues(alpha: 0.3), width: 4),
                                        boxShadow: [
                                          BoxShadow(
                                            color: slide.color.withValues(alpha: 0.2),
                                            blurRadius: 30,
                                            spreadRadius: 8,
                                          ),
                                        ],
                                      ),
                                      child: ClipOval(
                                        child: Image.asset(
                                          'assets/icon/icon_circular.png',
                                          width: 160,
                                          height: 160,
                                          cacheWidth: 320,
                                          cacheHeight: 320,
                                          fit: BoxFit.cover,
                                        ),
                                      ),
                                    )
                                  else
                                    Container(
                                      width: 160,
                                      height: 160,
                                      decoration: BoxDecoration(
                                        color: slide.color.withValues(alpha: 0.1),
                                        shape: BoxShape.circle,
                                        border: Border.all(color: slide.color.withValues(alpha: 0.3), width: 4),
                                        boxShadow: [
                                          BoxShadow(
                                            color: slide.color.withValues(alpha: 0.15),
                                            blurRadius: 30,
                                            spreadRadius: 8,
                                          ),
                                        ],
                                      ),
                                      child: Icon(slide.icon, size: 80, color: slide.color),
                                    ),
                                  // Small feature badge in bottom-right (only for first slide where it makes sense as overlay)
                                  if (index == 0)
                                    Positioned(
                                      bottom: 8,
                                      right: 8,
                                      child: Container(
                                        padding: const EdgeInsets.all(10),
                                        decoration: BoxDecoration(
                                          color: slide.color,
                                          shape: BoxShape.circle,
                                          border: Border.all(color: Colors.white, width: 3),
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.black.withValues(alpha: 0.2),
                                              blurRadius: 8,
                                              offset: const Offset(0, 3)
                                            ),
                                          ],
                                        ),
                                        child: Icon(slide.icon, size: 24, color: Colors.white),
                                      ),
                                    ).animate(delay: 600.ms).scale(duration: 400.ms, curve: Curves.easeOutBack),
                                ],
                              ),
                            ).animate(key: ValueKey('icon_$index')).scale(duration: 700.ms, curve: Curves.easeOutBack),
                            const SizedBox(height: 32),
                            Text(
                              slide.title,
                              textDirection: TextDirection.rtl,
                              style: TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                                color: slide.color,
                              ),
                            ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.3, end: 0),
                            const SizedBox(height: 8),
                            Text(
                              slide.subtitle,
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w600,
                                color: slide.color.withValues(alpha: 0.7),
                              ),
                            ).animate().fadeIn(delay: 400.ms),
                            const SizedBox(height: 20),
                            Text(
                              slide.description,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 15,
                                height: 1.6,
                                color: Colors.grey.shade600,
                              ),
                            ).animate().fadeIn(delay: 600.ms),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            // Dots & Button
            Padding(
              padding: const EdgeInsets.fromLTRB(32, 16, 32, 32),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Page dots
                  Row(
                    children: List.generate(_slides.length, (index) {
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        margin: const EdgeInsets.only(right: 8),
                        width: _currentPage == index ? 24 : 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: _currentPage == index
                              ? _slides[_currentPage].color
                              : Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      );
                    }),
                  ),
                  // Next / Get Started button
                  ElevatedButton(
                    onPressed: () {
                      if (_currentPage == _slides.length - 1) {
                        _onDone();
                      } else {
                        _pageController.nextPage(
                          duration: const Duration(milliseconds: 400),
                          curve: Curves.easeInOut,
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _slides[_currentPage].color,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                      elevation: 4,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _currentPage == _slides.length - 1 ? 'شروع کریں' : 'اگلا',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(width: 8),
                        Icon(
                          _currentPage == _slides.length - 1
                              ? Icons.check_circle
                              : Icons.arrow_forward,
                          size: 20,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Slide {
  final IconData icon;
  final String title;
  final String subtitle;
  final String description;
  final Color color;

  const _Slide({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.description,
    required this.color,
  });
}
