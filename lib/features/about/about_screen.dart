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
                    'سب احادیث — صحاح ستہ',
                    style: GoogleFonts.amiri(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).primaryColor,
                    ),
                    textDirection: TextDirection.rtl,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'All Hadith — Kutub al-Sittah',
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

            // About Kutub al-Sittah
            _buildCard(context, isDark, 'About Kutub al-Sittah', Icons.auto_stories, [
              'Kutub al-Sittah (The Six Books) are the canonical collections of Hadith recognized across the Islamic world as the most authentic collections of prophetic traditions.',
              'Includes: Sahih al-Bukhari, Sahih Muslim, Sunan Abu Dawood, Jami` at-Tirmidhi, Sunan an-Nasa\'i, and Sunan Ibn Majah.',
              'Contains over 34,480 hadiths across 335 chapters with complete Arabic, Urdu, and English text.',
              'Preserves the Sunnah of the Prophet Muhammad ﷺ with rigorous chains of transmission.',
            ], 0),
            const SizedBox(height: 12),

            // The 6 Compilers
            _buildCard(context, isDark, 'The 6 Revered Compilers', Icons.people_outline, [
              '1. Imam Muhammad al-Bukhari (194–256 AH / 810–870 CE)',
              '2. Imam Muslim ibn al-Hajjaj (204–261 AH / 820–875 CE)',
              '3. Imam Abu Dawood al-Sijistani (202–275 AH / 817–889 CE)',
              '4. Imam Abu `Isa at-Tirmidhi (209–279 AH / 824–892 CE)',
              '5. Imam Ahmad an-Nasa\'i (214–303 AH / 829–915 CE)',
              '6. Imam Ibn Majah al-Qazwini (209–273 AH / 824–887 CE)',
            ], 1),
            const SizedBox(height: 12),

            // App Features
            _buildCard(context, isDark, 'App Features', Icons.star_outline, [
              '• All 6 canonical books in one unified application',
              '• Book-specific themes with dynamic color palettes',
              '• Realistic 3D isolated book covers',
              '• Arabic text with full Urdu & English translations',
              '• Global & book-scoped search with language filters',
              '• Bookmarks, custom collections, and personal notes',
              '• Hadith image card generator & sharing',
              '• Customizable Arabic, Urdu & English typography',
              '• Light & Dark themes with reading progress tracker',
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
