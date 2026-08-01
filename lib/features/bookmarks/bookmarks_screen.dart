import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../theme/app_theme.dart';
import '../../data/repositories/hadith_repository.dart';
import '../../domain/models/models.dart';
import '../settings/settings_provider.dart';
import '../../widgets/banner_ad_widget.dart';

final bookmarkedHadithsProvider = FutureProvider<List<Map<String, dynamic>>>((
  ref,
) async {
  final repo = ref.watch(hadithRepositoryProvider);
  return repo.getBookmarkedHadithsWithChapter();
});

class BookmarksScreen extends ConsumerWidget {
  const BookmarksScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bookmarksAsync = ref.watch(bookmarkedHadithsProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final settings = ref.watch(settingsProvider);

    return Scaffold(
      bottomNavigationBar: const BannerAdWidget(),
      appBar: AppBar(title: const Text('Bookmarks'), centerTitle: true),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(bookmarkedHadithsProvider);
        },
        child: bookmarksAsync.when(
          loading: () => Center(
            child: CircularProgressIndicator(
              color: Theme.of(context).primaryColor,
            ),
          ),
          error: (e, _) => Center(child: Text('Error: $e')),
          data: (rows) {
            if (rows.isEmpty) {
              return ListView(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child:
                        Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 40,
                              ),
                              decoration: BoxDecoration(
                                color: isDark
                                    ? AppTheme.cardDark
                                    : Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(
                                      alpha: isDark ? 0.2 : 0.04,
                                    ),
                                    blurRadius: 6,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Column(
                                children: [
                                  Container(
                                        padding: const EdgeInsets.all(24),
                                        decoration: BoxDecoration(
                                          color: Theme.of(
                                            context,
                                          ).primaryColor.withValues(alpha: 0.1),
                                          shape: BoxShape.circle,
                                        ),
                                        child: Icon(
                                          Icons.bookmark_outline,
                                          size: 64,
                                          color: Theme.of(context).primaryColor,
                                        ),
                                      )
                                      .animate(
                                        onPlay: (controller) =>
                                            controller.repeat(reverse: true),
                                      )
                                      .scale(
                                        begin: const Offset(1, 1),
                                        end: const Offset(1.05, 1.05),
                                        duration: 1500.ms,
                                        curve: Curves.easeInOut,
                                      ),
                                  const SizedBox(height: 24),
                                  Text(
                                    'No Bookmarks Yet',
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: isDark
                                          ? Colors.grey.shade300
                                          : Colors.grey.shade800,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Tap the bookmark icon on any hadith\nto save it here for quick access.',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 15,
                                      height: 1.4,
                                      color: isDark
                                          ? Colors.grey.shade400
                                          : Colors.grey.shade600,
                                    ),
                                  ),
                                ],
                              ),
                            )
                            .animate()
                            .fadeIn(duration: 500.ms)
                            .slideY(
                              begin: 0.1,
                              end: 0,
                              duration: 500.ms,
                              curve: Curves.easeOut,
                            ),
                  ),
                ],
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: rows.length,
              itemBuilder: (context, index) {
                final row = rows[index];
                final hadith = Hadith.fromMap(row);
                final chapterTitleUrdu =
                    row['chapter_title_urdu'] as String? ?? '';
                final chapterTitleArabic =
                    row['chapter_title_arabic'] as String? ?? '';
                final chapterTitleEnglish =
                    row['chapter_title_english'] as String? ?? '';
                final chapterTitle = settings.titleLanguage == 'English'
                    ? chapterTitleEnglish
                    : settings.titleLanguage == 'Arabic'
                    ? chapterTitleArabic
                    : chapterTitleUrdu;

                final bookNumber = row['book_number'] as int? ?? 0;

                return Dismissible(
                  key: Key('bookmark_${hadith.id}'),
                  direction: DismissDirection.endToStart,
                  background: Container(
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 20),
                    margin: const EdgeInsets.only(bottom: 8),
                    decoration: BoxDecoration(
                      color: Colors.red.shade400,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.delete, color: Colors.white),
                  ),
                  onDismissed: (_) async {
                    final repo = ref.read(hadithRepositoryProvider);
                    await repo.toggleBookmark(hadith.id);
                    ref.invalidate(bookmarkedHadithsProvider);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Bookmark removed')),
                      );
                    }
                  },
                  child: InkWell(
                    onTap: () async {
                      final repo = ref.read(hadithRepositoryProvider);
                      final hIndex = await repo.getHadithIndex(
                        hadith.chapterId,
                        hadith.hadithNumber,
                      );
                      if (context.mounted) {
                        context.push(
                          '/home/chapter/${hadith.chapterId}?startIndex=$hIndex',
                        );
                      }
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: isDark ? AppTheme.cardDark : Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(
                              alpha: isDark ? 0.2 : 0.04,
                            ),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: Theme.of(
                                    context,
                                  ).primaryColor.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  'Hadith #${hadith.hadithNumber} — Book $bookNumber',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                    color: Theme.of(context).primaryColor,
                                  ),
                                ),
                              ),
                              Icon(
                                Icons.bookmark,
                                color: Theme.of(context).primaryColor,
                                size: 20,
                              ),
                            ],
                          ),
                          if (chapterTitle.isNotEmpty) ...[
                            const SizedBox(height: 6),
                            Text(
                              chapterTitle,
                              textAlign: settings.titleLanguage == 'English'
                                  ? TextAlign.left
                                  : TextAlign.right,
                              textDirection: settings.titleLanguage == 'English'
                                  ? TextDirection.ltr
                                  : TextDirection.rtl,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTheme.safeGetFont(
                                settings.activeFontFamily,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                height: 2.0,
                                wordSpacing: 2.0,
                                color: Theme.of(
                                  context,
                                ).primaryColor.withValues(alpha: 0.8),
                              ),
                            ),
                          ],
                          const SizedBox(height: 8),
                          Text(
                            hadith.englishText,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: AppTheme.safeGetFont(
                              settings.englishFontFamily,
                              fontSize: 13,
                              color:
                                  AppTheme.getFontColor(
                                    settings.englishFontColor,
                                    isDark,
                                  ) ??
                                  (isDark
                                      ? Colors.grey.shade300
                                      : Colors.grey.shade700),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Sahih Bukhari',
                            style: TextStyle(
                              fontSize: 11,
                              color: isDark
                                  ? Colors.white60
                                  : Colors.grey.shade500,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ).animate().fadeIn(delay: (80 * index).ms).slideX(begin: 0.05, end: 0),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
