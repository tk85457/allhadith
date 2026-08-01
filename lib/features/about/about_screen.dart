import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/app_theme.dart';
import '../../widgets/banner_ad_widget.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      bottomNavigationBar: const BannerAdWidget(),
      appBar: AppBar(
        title: const Text('About'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // App Info Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: isDark ? AppTheme.cardDark : Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.06),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Theme.of(context).primaryColor.withValues(alpha: 0.3), width: 3),
                      boxShadow: [
                        BoxShadow(
                          color: Theme.of(context).primaryColor.withValues(alpha: 0.15),
                          blurRadius: 16,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: ClipOval(
                      child: Image.asset(
                        'assets/icon/icon_circular.png',
                        width: 100,
                        height: 100,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'صحیح البخاری',
                    style: GoogleFonts.amiri(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).primaryColor,
                    ),
                    textDirection: TextDirection.rtl,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Sahih Al-Bukhari',
                    style: GoogleFonts.rubik(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Version 1.0.0',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                  ),
                ],
              ),
            ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.05, end: 0),
            const SizedBox(height: 16),

            // About Sahih Bukhari
            _buildCard(context, isDark, 'About Sahih Bukhari', Icons.info_outline, [
              'Sahih al-Bukhari is a collection of hadith compiled by Imam Muhammad al-Bukhari (rahimahullah) around 846 CE / 232 AH.',
              'It is considered by Muslims to be the most authentic collection of hadith after the Holy Quran.',
              'Imam Bukhari collected over 600,000 hadiths and selected approximately 7,563 hadiths (with repetitions) for this collection.',
              'The collection was completed over 16 years with extreme care and precision.',
            ], 0),
            const SizedBox(height: 12),

            // About Author
            _buildCard(context, isDark, 'About Imam Bukhari', Icons.person_outline, [
              'Full Name: Abu Abdullah Muhammad ibn Ismail al-Bukhari',
              'Born: 21 July 810 CE (13 Shawwal 194 AH) in Bukhara, present-day Uzbekistan',
              'Died: 1 September 870 CE (1 Shawwal 256 AH)',
              'He memorized the entire Quran by age 9 and began studying hadith at age 11.',
              'He traveled extensively across the Islamic world to collect and verify hadiths.',
            ], 1),
            const SizedBox(height: 12),

            // App Features
            _buildCard(context, isDark, 'App Features', Icons.star_outline, [
              '• Complete Sahih Bukhari collection',
              '• Arabic, Urdu & English translations',
              '• Bookmark your favourite hadiths',
              '• Create custom collections',
              '• Powerful search functionality',
              '• Adjustable font sizes',
              '• Dark & Light mode',
              '• Notes on hadiths',
              '• Resume reading from where you left',
            ], 2),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildCard(BuildContext context, bool isDark, String title, IconData icon, List<String> items, int delay) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.cardDark : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: Theme.of(context).primaryColor, size: 22),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  fontSize: 17,
                  color: Theme.of(context).primaryColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...items.map((item) => Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Text(
              item,
              style: TextStyle(
                fontSize: 13.5,
                height: 1.5,
                color: isDark ? Colors.grey.shade300 : Colors.grey.shade700,
              ),
            ),
          )),
        ],
      ),
    ).animate().fadeIn(delay: (150 * delay).ms, duration: 400.ms).slideY(begin: 0.05, end: 0);
  }
}
