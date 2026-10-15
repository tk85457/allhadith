import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../theme/app_theme.dart';
import '../../core/ads/ad_service.dart';
import '../../core/services/in_app_review_service.dart';
import 'settings_provider.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  final bool fromBooks;

  const SettingsScreen({super.key, this.fromBooks = false});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  final _arabicFonts = ['Amiri', 'Lateef', 'Scheherazade New', 'Aref Ruqaa', 'Cairo', 'Tajawal', 'Changa', 'Reem Kufi', 'Lalezar', 'Markazi Text', 'AlQalam', 'Muhammadi', 'PDMS Saleem', 'NooreHuda', 'NooreHira'];
  final _urduFonts = ['Noto Nastaliq Urdu', 'Gulzar', 'Nastaleeq', 'Baloo Bhaijaan 2', 'Lateef', 'Amiri', 'Mehr', 'TypeSetting', 'PDMS Saleem'];
  final _englishFonts = ['Inter', 'Rubik', 'Roboto', 'Open Sans', 'Lato', 'Montserrat', 'Poppins', 'Oswald', 'Raleway', 'Ubuntu', 'RubikMedium', 'Google Sans Regular'];
  final _fontColors = ['Default', 'Black', 'Dark Brown', 'Dark Blue', 'Dark Green'];
  final _alignments = ['Right', 'Center', 'Left'];

  bool _privacyOptionsRequired = false;

  @override
  void initState() {
    super.initState();
    _checkPrivacyOptions();
  }

  Future<void> _checkPrivacyOptions() async {
    final required = await AdService.isPrivacyOptionsRequired();
    if (mounted && required != _privacyOptionsRequired) {
      setState(() {
        _privacyOptionsRequired = required;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider);
    final notifier = ref.read(settingsProvider.notifier);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final content = Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // ─── Title Name Section (First / Prominent) ───
            _buildSectionCard(isDark, 'Title Name', [
              _buildDropdownRow(isDark, 'Language', settings.titleLanguage, ['Urdu', 'English', 'Arabic'], (v) {
                notifier.updateTitleLanguage(v!);
              }),
            ]),

            // ─── General Section ───
            _buildSectionCard(isDark, 'General', [
              _buildDropdownRow(isDark, 'Theme', settings.isDarkMode ? 'Dark' : 'Green', ['Green', 'Dark'], (v) {
                notifier.updateTheme(v == 'Dark');
              }),
              const SizedBox(height: 12),
              _buildDropdownRow(isDark, 'Arabic', settings.showArabic ? 'Show' : 'Hide', ['Show', 'Hide'], (v) {
                notifier.toggleTranslation('Arabic', v == 'Show');
              }),
              const SizedBox(height: 12),
              _buildDropdownRow(isDark, 'Urdu', settings.showUrdu ? 'Show' : 'Hide', ['Show', 'Hide'], (v) {
                notifier.toggleTranslation('Urdu', v == 'Show');
              }),
              const SizedBox(height: 12),
              _buildDropdownRow(isDark, 'English', settings.showEnglish ? 'Show' : 'Hide', ['Show', 'Hide'], (v) {
                notifier.toggleTranslation('English', v == 'Show');
              }),
              const SizedBox(height: 12),
              _buildDropdownRow(isDark, 'View', settings.viewType, ['All Ahadith', 'Translations Only'], (v) {
                notifier.updateViewType(v!);
              }),
              const SizedBox(height: 12),
              _buildDropdownRow(isDark, 'UI Color', settings.uiColor, ['Book Theme', 'Green', 'Blue', 'Purple', 'Orange', 'Dark Brown', 'Dark Blue', 'Terracotta'], (v) {
                notifier.updateUiColor(v!);
              }),
            ]),

            // ─── Arabic Font Section ───
            _buildSectionCard(isDark, 'Arabic Font', [
              _buildDropdownRow(isDark, 'Arabic Font', settings.arabicFontFamily, _arabicFonts, (v) {
                notifier.updateFontFamily('Arabic', v!);
              }),
              const SizedBox(height: 12),
              _buildFontSizeRow(isDark, 'Font Size', settings.arabicFontSize, 16, 40, (v) {
                notifier.updateFontSize('Arabic', v);
              }),
              const SizedBox(height: 12),
              _buildDropdownRow(isDark, 'Font Color', settings.arabicFontColor, _fontColors, (v) {
                notifier.updateFontColor('Arabic', v!);
              }),
              const SizedBox(height: 24),
              // Arabic Preview
              Text(
                'اَلْحَمْدُ لِلّٰهِ رَبِّ الْعٰلَمِيْنَ',
                textAlign: TextAlign.center,
                textDirection: TextDirection.rtl,
                style: AppTheme.safeGetFont(
                  settings.arabicFontFamily,
                  fontSize: settings.arabicFontSize,
                  height: 1.8,
                  color: AppTheme.getFontColor(settings.arabicFontColor, isDark),
                ),
              ),
            ]),

            // ─── Urdu Font Section ───
            _buildSectionCard(isDark, 'Urdu Font', [
              _buildDropdownRow(isDark, 'Urdu Font', settings.urduFontFamily, _urduFonts, (v) {
                notifier.updateFontFamily('Urdu', v!);
              }),
              const SizedBox(height: 12),
              _buildFontSizeRow(isDark, 'Font Size', settings.urduFontSize, 14, 36, (v) {
                notifier.updateFontSize('Urdu', v);
              }),
              const SizedBox(height: 12),
              _buildDropdownRow(isDark, 'Font Color', settings.urduFontColor, _fontColors, (v) {
                notifier.updateFontColor('Urdu', v!);
              }),
              const SizedBox(height: 12),
              _buildDropdownRow(isDark, 'Alignment', settings.urduAlignment, _alignments, (v) {
                notifier.updateUrduAlignment(v!);
              }),
              const SizedBox(height: 24),
              // Urdu Preview
              Text(
                'تمام تعریفیں اللہ کی ہیں جو تمام جہانوں کا پروردگار ہے',
                textAlign: _getAlignment(settings.urduAlignment),
                textDirection: TextDirection.rtl,
                style: AppTheme.safeGetFont(
                  settings.urduFontFamily,
                  fontSize: settings.urduFontSize,
                  height: 2.0,
                  color: AppTheme.getFontColor(settings.urduFontColor, isDark),
                ),
              ),
            ]),

            // ─── English Font Section ───
            _buildSectionCard(isDark, 'English Font', [
              _buildDropdownRow(isDark, 'English Font', settings.englishFontFamily, _englishFonts, (v) {
                notifier.updateFontFamily('English', v!);
              }),
              const SizedBox(height: 12),
              _buildFontSizeRow(isDark, 'Font Size', settings.englishFontSize, 12, 32, (v) {
                notifier.updateFontSize('English', v);
              }),
              const SizedBox(height: 12),
              _buildDropdownRow(isDark, 'Font Color', settings.englishFontColor, _fontColors, (v) {
                notifier.updateFontColor('English', v!);
              }),
              const SizedBox(height: 24),
              // English Preview
              Text(
                '[All] praise is [due] to Allah, Lord of the worlds',
                textAlign: TextAlign.center,
                style: AppTheme.safeGetFont(
                  settings.englishFontFamily,
                  fontSize: settings.englishFontSize,
                  color: AppTheme.getFontColor(settings.englishFontColor, isDark),
                ),
              ),
            ]),

            // ─── Support & Feedback Section ───
            _buildSectionCard(isDark, 'Support & Feedback', [
              ValueListenableBuilder<bool>(
                valueListenable: AdService.isAdFreeActiveNotifier,
                builder: (context, isAdFree, _) {
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(
                      isAdFree ? Icons.verified_rounded : Icons.workspace_premium_rounded,
                      color: isAdFree ? Colors.green : Colors.amber,
                      size: 28,
                    ),
                    title: Text(
                      '24-Hour Ad-Free Reading Pass',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.grey.shade300 : AppTheme.textDark,
                      ),
                    ),
                    subtitle: Text(
                      isAdFree
                          ? 'Active (${AdService.remainingAdFreeTimeFormatted} remaining)'
                          : 'Watch 1 video to remove all ads for 24 hours',
                      style: TextStyle(
                        fontSize: 12,
                        color: isAdFree
                            ? Colors.green
                            : (isDark ? Colors.grey.shade400 : Colors.grey.shade600),
                      ),
                    ),
                    trailing: isAdFree
                        ? Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.green.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Text(
                              'ACTIVE',
                              style: TextStyle(
                                color: Colors.green,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          )
                        : const Icon(Icons.chevron_right, size: 20),
                    onTap: () {
                      _showAdFreePassDialog(context, isDark);
                    },
                  );
                },
              ),
              Divider(
                height: 1,
                color: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(
                  Icons.star_rounded,
                  color: Colors.amber,
                  size: 28,
                ),
                title: Text(
                  'Rate this App',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.grey.shade300 : AppTheme.textDark,
                  ),
                ),
                subtitle: Text(
                  'Rate us on Google Play to support the project',
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                  ),
                ),
                trailing: const Icon(Icons.chevron_right, size: 20),
                onTap: () async {
                  await InAppReviewService.triggerManualReview(appName: 'All Hadith');
                },
              ),
            ]),

            // ─── Privacy & Consent Section (Google UMP Requirement) ───
            if (_privacyOptionsRequired)
              _buildSectionCard(isDark, 'Privacy & Consent', [
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(
                    Icons.privacy_tip_outlined,
                    color: Theme.of(context).primaryColor,
                  ),
                  title: Text(
                    'Ad Privacy Settings',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.grey.shade300 : AppTheme.textDark,
                    ),
                  ),
                  subtitle: Text(
                    'Review or change your advertising consent choices',
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                    ),
                  ),
                  trailing: const Icon(Icons.chevron_right, size: 20),
                  onTap: () async {
                    await AdService.showPrivacyOptionsForm();
                    _checkPrivacyOptions();
                  },
                ),
              ]),
          ],
        ).animate().fadeIn(duration: 400.ms),
      ),
    );

    if (widget.fromBooks) {
      final terracottaTheme = isDark
          ? AppTheme.darkTheme(AppTheme.terracottaPrimary)
          : AppTheme.lightTheme(AppTheme.terracottaPrimary);
      return Theme(
        data: terracottaTheme,
        child: content,
      );
    }

    return content;
  }

  Widget _buildSectionCard(bool isDark, String title, List<Widget> children) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? (Theme.of(context).cardTheme.color ?? AppTheme.cardDark) : Colors.white,
        border: Border.all(color: isDark ? Colors.grey.shade800 : Colors.grey.shade200),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).primaryColor,
            ),
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  TextAlign _getAlignment(String alignment) {
    switch (alignment) {
      case 'Right': return TextAlign.right;
      case 'Center': return TextAlign.center;
      case 'Left': return TextAlign.left;
      default: return TextAlign.right;
    }
  }

  Widget _buildDropdownRow(bool isDark, String label, String value, List<String> options, ValueChanged<String?> onChanged) {
    return Row(
      children: [
        SizedBox(
          width: 110,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.grey.shade300 : AppTheme.textDark,
            ),
          ),
        ),
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              border: Border.all(color: isDark ? Colors.grey.shade700 : Colors.grey.shade300),
              borderRadius: BorderRadius.circular(8),
              color: isDark ? (Theme.of(context).cardTheme.color ?? AppTheme.cardDark) : Colors.white,
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: value,
                isExpanded: true,
                dropdownColor: isDark ? (Theme.of(context).cardTheme.color ?? AppTheme.cardDark) : Colors.white,
                style: TextStyle(
                  fontSize: 14,
                  color: isDark ? Colors.grey.shade300 : Colors.grey.shade700,
                ),
                items: options.map((opt) => DropdownMenuItem(
                  value: opt,
                  child: Text(opt, textAlign: TextAlign.center),
                )).toList(),
                onChanged: onChanged,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFontSizeRow(bool isDark, String label, double value, double min, double max, ValueChanged<double> onChanged) {
    return Row(
      children: [
        SizedBox(
          width: 110,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.grey.shade300 : AppTheme.textDark,
            ),
          ),
        ),
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              border: Border.all(color: isDark ? Colors.grey.shade700 : Colors.grey.shade300),
              borderRadius: BorderRadius.circular(8),
              color: isDark ? (Theme.of(context).cardTheme.color ?? AppTheme.cardDark) : Colors.white,
            ),
            child: Row(
              children: [
                InkWell(
                  onTap: value > min ? () => onChanged(value - 1) : null,
                  child: Padding(
                    padding: const EdgeInsets.all(4),
                    child: Icon(Icons.remove, size: 18,
                      color: value > min ? Theme.of(context).primaryColor : Colors.grey),
                  ),
                ),
                Expanded(
                  child: Text(
                    '${value.toInt()}',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: isDark ? Colors.grey.shade300 : Colors.grey.shade700,
                    ),
                  ),
                ),
                InkWell(
                  onTap: value < max ? () => onChanged(value + 1) : null,
                  child: Padding(
                    padding: const EdgeInsets.all(4),
                    child: Icon(Icons.add, size: 18,
                      color: value < max ? Theme.of(context).primaryColor : Colors.grey),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ─── 24-Hour Ad-Free Pass Dialog ───
  void _showAdFreePassDialog(BuildContext context, bool isDark) {
    HapticFeedback.lightImpact();
    final primaryColor = Theme.of(context).primaryColor;

    showDialog(
      context: context,
      builder: (dialogCtx) {
        return ValueListenableBuilder<bool>(
          valueListenable: AdService.isAdFreeActiveNotifier,
          builder: (context, isAdFree, _) {
            final remainingText = AdService.remainingAdFreeTimeFormatted;

            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
              titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
              contentPadding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
              actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              title: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: (isAdFree ? Colors.green : Colors.amber).withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      isAdFree ? Icons.verified_rounded : Icons.workspace_premium_rounded,
                      color: isAdFree ? Colors.green : Colors.amber.shade700,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      isAdFree ? '24h Ad-Free Active' : 'Remove Ads for 24h',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : AppTheme.textDark,
                      ),
                    ),
                  ),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (isAdFree) ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.green.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.timer_outlined, color: Colors.green, size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Pass Active: $remainingText remaining',
                              style: const TextStyle(
                                color: Colors.green,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'All banner ads and transition ads are completely turned off. Enjoy peaceful, distraction-free study and recitation!',
                      style: TextStyle(
                        fontSize: 13,
                        color: isDark ? Colors.grey.shade300 : Colors.grey.shade700,
                        height: 1.4,
                      ),
                    ),
                  ] else ...[
                    Text(
                      'Watch 1 sponsor video to completely remove all ads for 24 hours:',
                      style: TextStyle(
                        fontSize: 13,
                        color: isDark ? Colors.grey.shade300 : Colors.grey.shade700,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: (isDark ? Colors.grey.shade900 : Colors.grey.shade100),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildAdBenefitRow(Icons.check_circle_rounded, 'No Banner Ads on any screen'),
                          const SizedBox(height: 6),
                          _buildAdBenefitRow(Icons.check_circle_rounded, 'No Transition Ads between chapters'),
                          const SizedBox(height: 6),
                          _buildAdBenefitRow(Icons.check_circle_rounded, '100% Free & peaceful reading'),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogCtx).pop(),
                  child: Text(
                    'Close',
                    style: TextStyle(color: isDark ? Colors.grey.shade400 : Colors.grey.shade600),
                  ),
                ),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isAdFree ? Colors.green.shade700 : primaryColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  ),
                  icon: const Icon(Icons.play_circle_fill_rounded, size: 20),
                  label: Text(isAdFree ? 'Extend +24h' : 'Watch & Unlock 24h'),
                  onPressed: () async {
                    Navigator.of(dialogCtx).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Loading Rewarded Ad... Please wait 💚'),
                        duration: Duration(seconds: 2),
                      ),
                    );
                    await AdService.showVoluntaryRewardedAd(
                      onUserEarnedReward: () {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: const Text('JazakAllah Khair! 24-Hour Ad-Free Reading unlocked! 💚'),
                              backgroundColor: Colors.green.shade700,
                              duration: const Duration(seconds: 4),
                            ),
                          );
                        }
                      },
                      onAdFailed: () {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Ad could not load right now. Please try again shortly.'),
                              duration: Duration(seconds: 2),
                            ),
                          );
                        }
                      },
                    );
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildAdBenefitRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, color: Colors.green, size: 16),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
          ),
        ),
      ],
    );
  }
}

