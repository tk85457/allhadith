import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../theme/app_theme.dart';
import '../../widgets/banner_ad_widget.dart';
import 'settings_provider.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  final _arabicFonts = ['Amiri', 'Lateef', 'Scheherazade New', 'Aref Ruqaa', 'Cairo', 'Tajawal', 'Changa', 'Reem Kufi', 'Lalezar', 'Markazi Text', 'AlQalam', 'Muhammadi', 'PDMS Saleem', 'NooreHuda', 'NooreHira'];
  final _urduFonts = ['Noto Nastaliq Urdu', 'Gulzar', 'Nastaleeq', 'Baloo Bhaijaan 2', 'Lateef', 'Amiri', 'Mehr', 'TypeSetting', 'PDMS Saleem'];
  final _englishFonts = ['Inter', 'Rubik', 'Roboto', 'Open Sans', 'Lato', 'Montserrat', 'Poppins', 'Oswald', 'Raleway', 'Ubuntu', 'RubikMedium', 'Google Sans Regular'];
  final _fontColors = ['Default', 'Black', 'Dark Brown', 'Dark Blue', 'Dark Green'];
  final _alignments = ['Right', 'Center', 'Left'];

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider);
    final notifier = ref.read(settingsProvider.notifier);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      bottomNavigationBar: const BannerAdWidget(),
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
              _buildDropdownRow(isDark, 'UI Color', settings.uiColor, ['Green', 'Blue', 'Purple', 'Orange', 'Dark Brown', 'Dark Blue'], (v) {
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
          ],
        ).animate().fadeIn(duration: 400.ms),
      ),
    );
  }

  Widget _buildSectionCard(bool isDark, String title, List<Widget> children) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.cardDark : Colors.white,
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
              color: isDark ? AppTheme.cardDark : Colors.white,
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: value,
                isExpanded: true,
                dropdownColor: isDark ? AppTheme.cardDark : Colors.white,
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
              color: isDark ? AppTheme.cardDark : Colors.white,
            ),
            child: Row(
              children: [
                InkWell(
                  onTap: value > min ? () => onChanged(value - 1) : null,
                  child: Padding(
                    padding: const EdgeInsets.all(4),
                    child: Icon(Icons.remove, size: 18,
                      color: value > min ? AppTheme.primaryGreen : Colors.grey),
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
                      color: value < max ? AppTheme.primaryGreen : Colors.grey),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
