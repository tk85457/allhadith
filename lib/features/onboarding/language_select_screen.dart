import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../theme/app_theme.dart';
import '../settings/settings_provider.dart';

/// First-run language picker. Shown once, before the feature-intro
/// onboarding slides, right after the splash screen. The chosen language
/// is written straight into [AppSettings.titleLanguage] — the same value
/// the Settings screen's "Title Name" dropdown controls — so book and
/// chapter names immediately render in the chosen language, and the user
/// can still change it later from Settings at any time.
class LanguageSelectScreen extends ConsumerStatefulWidget {
  const LanguageSelectScreen({super.key});

  @override
  ConsumerState<LanguageSelectScreen> createState() =>
      _LanguageSelectScreenState();
}

class _LanguageSelectScreenState extends ConsumerState<LanguageSelectScreen> {
  String? _selected;
  bool _saving = false;

  static const _options = [
    _LanguageOption(
      value: 'English',
      nativeLabel: 'English',
      subLabel: 'Book & chapter names in English',
      textDirection: TextDirection.ltr,
    ),
    _LanguageOption(
      value: 'Urdu',
      nativeLabel: 'اردو',
      subLabel: 'کتاب اور باب کے نام اردو میں',
      textDirection: TextDirection.rtl,
    ),
    _LanguageOption(
      value: 'Arabic',
      nativeLabel: 'العربية',
      subLabel: 'أسماء الكتب والأبواب بالعربية',
      textDirection: TextDirection.rtl,
    ),
  ];

  Future<void> _continue() async {
    if (_selected == null || _saving) return;
    setState(() => _saving = true);
    await ref.read(settingsProvider.notifier).updateTitleLanguage(_selected!);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_done', true);
    if (!mounted) return;
    context.go('/books');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.primaryDark,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
          child: Column(
            children: [
              const SizedBox(height: 24),
              Container(
                width: 88,
                height: 88,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white.withValues(alpha: 0.6), width: 3),
                ),
                child: ClipOval(
                  child: Image.asset(
                    'assets/icon/icon_circular.png',
                    fit: BoxFit.cover,
                  ),
                ),
              ).animate().scale(duration: 500.ms, curve: Curves.easeOutBack),
              const SizedBox(height: 28),
              Text(
                'Choose your language',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ).animate().fadeIn(delay: 150.ms),
              const SizedBox(height: 8),
              Text(
                'Select the language for book & chapter names.\nYou can change this anytime in Settings.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  height: 1.5,
                  color: Colors.white.withValues(alpha: 0.8),
                ),
              ).animate().fadeIn(delay: 250.ms),
              const SizedBox(height: 36),
              Expanded(
                child: ListView.separated(
                  itemCount: _options.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 14),
                  itemBuilder: (context, index) {
                    final option = _options[index];
                    final isSelected = _selected == option.value;
                    return _LanguageCard(
                      option: option,
                      isSelected: isSelected,
                      onTap: () => setState(() => _selected = option.value),
                    ).animate().fadeIn(delay: (350 + index * 120).ms).slideY(begin: 0.15, end: 0);
                  },
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _selected == null ? null : _continue,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: AppTheme.primaryDark,
                    disabledBackgroundColor: Colors.white.withValues(alpha: 0.3),
                    disabledForegroundColor: Colors.white.withValues(alpha: 0.6),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    elevation: 3,
                  ),
                  child: _saving
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(strokeWidth: 2.4),
                        )
                      : const Text(
                          'Continue',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LanguageOption {
  final String value;
  final String nativeLabel;
  final String subLabel;
  final TextDirection textDirection;

  const _LanguageOption({
    required this.value,
    required this.nativeLabel,
    required this.subLabel,
    required this.textDirection,
  });
}

class _LanguageCard extends StatelessWidget {
  final _LanguageOption option;
  final bool isSelected;
  final VoidCallback onTap;

  const _LanguageCard({
    required this.option,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.white.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isSelected ? Colors.white : Colors.white.withValues(alpha: 0.3),
            width: 2,
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    option.nativeLabel,
                    textDirection: option.textDirection,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: isSelected ? AppTheme.primaryDark : Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    option.subLabel,
                    textDirection: option.textDirection,
                    style: TextStyle(
                      fontSize: 12.5,
                      color: isSelected
                          ? AppTheme.primaryDark.withValues(alpha: 0.7)
                          : Colors.white.withValues(alpha: 0.75),
                    ),
                  ),
                ],
              ),
            ),
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected ? AppTheme.primaryDark : Colors.transparent,
                border: Border.all(
                  color: isSelected ? AppTheme.primaryDark : Colors.white.withValues(alpha: 0.6),
                  width: 2,
                ),
              ),
              child: isSelected
                  ? const Icon(Icons.check, size: 16, color: Colors.white)
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}
