import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../theme/app_theme.dart';
import '../../data/repositories/hadith_repository.dart';
import '../../domain/models/models.dart';
import '../settings/settings_provider.dart';
import '../../widgets/banner_ad_widget.dart';
import '../../widgets/native_ad_widget.dart';

final chapterHadithsListProvider = FutureProvider.family<List<Hadith>, int>((ref, chapterId) async {
  final repo = ref.watch(hadithRepositoryProvider);
  return repo.getHadithsByChapter(chapterId, limit: 10000);
});

final singleChapterProvider = FutureProvider.family<Chapter?, int>((ref, chapterId) async {
  final repo = ref.watch(hadithRepositoryProvider);
  return repo.getChapterById(chapterId);
});

class HadithListScreen extends ConsumerWidget {
  final int chapterId;

  const HadithListScreen({super.key, required this.chapterId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hadithsAsync = ref.watch(chapterHadithsListProvider(chapterId));
    final chapterAsync = ref.watch(singleChapterProvider(chapterId));
    final settings = ref.watch(settingsProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: chapterAsync.when(
          data: (chapter) => Text(
            settings.titleLanguage == 'English'
                ? (chapter?.titleEnglish ?? 'Chapter')
                : settings.titleLanguage == 'Arabic'
                    ? (chapter?.titleArabic ?? 'باب')
                    : (chapter?.titleUrdu ?? 'باب'),
            style: AppTheme.safeGetFont(
              settings.activeFontFamily,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          loading: () => const Text('Loading...'),
          error: (_, _) => const Text('Error'),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => context.push('/home/settings'),
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Field
          Container(
            margin: const EdgeInsets.all(12),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            decoration: BoxDecoration(
              color: isDark ? AppTheme.cardDark : Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    textAlign: TextAlign.right,
                    textDirection: TextDirection.rtl,
                    onSubmitted: (query) {
                        context.push('/home/search');
                    },
                    decoration: InputDecoration(
                      hintText: 'حدیث نمبر یا عنوان کے ذریعے تلاش کریں',
                      hintStyle: TextStyle(color: isDark ? Colors.grey.shade500 : Colors.grey.shade400, fontSize: 13),
                      border: InputBorder.none,
                    ),
                  ),
                ),
                const Icon(Icons.search, color: Colors.blue),
              ],
            ),
          ),
          Expanded(
            child: hadithsAsync.when(
              loading: () => Center(child: CircularProgressIndicator(color: Theme.of(context).primaryColor)),
              error: (e, st) => Center(child: Text('Error: $e')),
              data: (hadiths) {
                if (hadiths.isEmpty) {
                  return Center(child: Text('عذر خواہ ہیں، کوئی حدیث نہیں ملی', style: TextStyle(color: isDark ? Colors.white70 : Colors.black87)));
                }

                final totalItems = hadiths.length + (hadiths.length ~/ 5);

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  itemCount: totalItems,
                  itemBuilder: (context, index) {
                    // Insert a Native Ad every 5 Hadiths (index 5, 11, 17...)
                    if ((index + 1) % 6 == 0) {
                      return const NativeAdCardWidget();
                    }

                    final realIndex = index - (index ~/ 6);
                    if (realIndex >= hadiths.length) return const SizedBox.shrink();
                    final hadith = hadiths[realIndex];

                    return GestureDetector(
                      onTap: () {
                        context.push('/home/chapter/$chapterId?startIndex=$realIndex');
                      },
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
                        decoration: BoxDecoration(
                          color: isDark ? AppTheme.cardDark : Colors.white,
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: isDark ? Colors.grey.shade800 : Colors.grey.shade300),
                        ),
                        child: Row(
                          textDirection: TextDirection.rtl,
                          children: [
                            Icon(Icons.circle, size: 14, color: Theme.of(context).primaryColor),
                            const SizedBox(width: 16),
                            Text(
                              hadith.hadithNumber,
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).primaryColor,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Text(
                                    settings.titleLanguage == 'English'
                                        ? (chapterAsync.value?.titleEnglish ?? 'Chapter')
                                        : settings.titleLanguage == 'Arabic'
                                            ? (chapterAsync.value?.titleArabic ?? 'باب')
                                            : (chapterAsync.value?.titleUrdu ?? 'باب'),
                                    textAlign: settings.titleLanguage == 'English' ? TextAlign.left : TextAlign.right,
                                    textDirection: settings.titleLanguage == 'English' ? TextDirection.ltr : TextDirection.rtl,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: AppTheme.safeGetFont(
                                      settings.activeFontFamily,
                                      color: Theme.of(context).primaryColor,
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      height: 2.0,
                                      wordSpacing: 2.0,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    hadith.urduText.replaceAll('\n', ' '),
                                    textAlign: TextAlign.right,
                                    textDirection: TextDirection.rtl,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: AppTheme.safeGetFont(
                                      settings.urduFontFamily,
                                      color: isDark ? Colors.white70 : Colors.black87,
                                      fontSize: 15,
                                      height: 2.0,
                                      wordSpacing: 2.0,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                          ),
                        ),
                      ).animate()
                       .fade(duration: 400.ms)
                       .slideY(begin: 0.1, end: 0, curve: Curves.easeOut, delay: (realIndex % 10 * 50).ms);
                  },
                );
              },
            ),
          ),
        ],
      ),
      bottomNavigationBar: const BannerAdWidget(),
    );
  }
}
