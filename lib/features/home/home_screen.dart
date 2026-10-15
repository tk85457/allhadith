import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../theme/app_theme.dart';
import '../../data/repositories/hadith_repository.dart';
import '../../core/ads/ad_service.dart';
import '../../domain/models/models.dart';
import '../settings/settings_provider.dart';
import '../common/widgets/shimmer_loading.dart';
import '../books/book_provider.dart';

final chaptersProvider = FutureProvider<List<Chapter>>((ref) async {
  final repo = ref.watch(hadithRepositoryProvider);
  final bookId = ref.watch(selectedBookIdProvider);
  return repo.getChaptersByBook(bookId);
});

final hadithOfTheDayProvider = FutureProvider<Hadith?>((ref) async {
  final repo = ref.watch(hadithRepositoryProvider);
  final bookId = ref.watch(selectedBookIdProvider);
  return repo.getHadithOfTheDay(bookId: bookId);
});

final statsProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final repo = ref.watch(hadithRepositoryProvider);
  final bookId = ref.watch(selectedBookIdProvider);
  final bookmarks = await repo.getBookmarkCount(bookId: bookId);
  final notes = await repo.getNotesCount(bookId: bookId);
  final readChapters = await repo.getTotalReadChapters(bookId: bookId);
  final totalChapters = await repo.getTotalChapterCount(bookId: bookId);
  final progress = totalChapters > 0
      ? (readChapters / totalChapters * 100).round()
      : 0;
  return {
    'bookmarks': bookmarks,
    'notes': notes,
    'chapters': readChapters,
    'progress': progress,
  };
});

final chapterProgressProvider = FutureProvider<Map<int, double>>((ref) async {
  final repo = ref.watch(hadithRepositoryProvider);
  final bookId = ref.watch(selectedBookIdProvider);
  final rows = await repo.getAllChapterProgress(bookId: bookId);
  final Map<int, double> progress = {};
  for (final row in rows) {
    final id = row['id'] as int;
    final hadithCount = (row['hadith_count'] as int?) ?? 1;
    final hadithIndex = (row['hadith_index'] as int?) ?? 0;
    progress[id] = hadithCount > 0
        ? (hadithIndex / hadithCount).clamp(0.0, 1.0)
        : 0.0;
  }
  return progress;
});

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final chaptersAsync = ref.watch(chaptersProvider);
    final currentBook = ref.watch(currentBookProvider);
    final selectedBookId = ref.watch(selectedBookIdProvider);
    final settings = ref.watch(settingsProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final bookTitle = settings.titleLanguage == 'English'
        ? currentBook.nameEnglish
        : settings.titleLanguage == 'Arabic'
            ? currentBook.nameArabic
            : currentBook.nameUrdu;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        HapticFeedback.lightImpact();
        context.go('/books');
      },
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded),
            tooltip: 'All Books / کتب فہرست',
            onPressed: () {
              HapticFeedback.lightImpact();
              context.go('/books');
            },
          ),
          title: InkWell(
            onTap: () {
              HapticFeedback.lightImpact();
              context.push('/books');
            },
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Flexible(
                    child: Text(
                      bookTitle,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(Icons.arrow_drop_down, size: 22),
                ],
              ),
            ),
          ),
          centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.auto_stories),
            tooltip: 'All Books / تمام کتب',
            onPressed: () {
              HapticFeedback.lightImpact();
              context.push('/books');
            },
          ),
          ValueListenableBuilder<bool>(
            valueListenable: AdService.isAdFreeActiveNotifier,
            builder: (context, isAdFree, _) {
              return IconButton(
                icon: Icon(
                  isAdFree ? Icons.verified_rounded : Icons.workspace_premium_outlined,
                  color: isAdFree ? Colors.greenAccent : Colors.amber,
                ),
                tooltip: isAdFree
                    ? '24h Ad-Free Active (${AdService.remainingAdFreeTimeFormatted})'
                    : 'Remove Ads for 24 Hours / 24 گھنٹے اشتہارات ہٹائیں',
                onPressed: () => _showAdFreePassDialog(context, selectedBookId),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              HapticFeedback.lightImpact();
              context.push('/home/settings');
            },
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (value) {
              HapticFeedback.selectionClick();
              switch (value) {
                case 'ChangeBook':
                  context.push('/books');
                  break;
                case 'Backup':
                  _showBackupDialog(context, ref);
                  break;
                case 'Author':
                  context.push('/home/about');
                  break;
                case 'AppIntro':
                  context.push('/home/about');
                  break;
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'ChangeBook',
                child: Row(
                  children: [
                    Icon(Icons.menu_book, size: 18),
                    SizedBox(width: 8),
                    Text('Change Book (کتب احادیث)'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'Backup',
                child: Text('Backup and Restore Data'),
              ),
              const PopupMenuItem(
                value: 'Author',
                child: Text('Author Introduction'),
              ),
              const PopupMenuItem(
                value: 'AppIntro',
                child: Text('App Introduction'),
              ),
            ],
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          HapticFeedback.mediumImpact();
          ref.invalidate(chaptersProvider);
          ref.invalidate(hadithOfTheDayProvider);
          ref.invalidate(statsProvider);
          ref.invalidate(chapterProgressProvider);
        },
        child: CustomScrollView(
          slivers: [
            // Quick Horizontal Book Switcher Bar
            SliverToBoxAdapter(
              child: _buildBookSwitcher(context, ref, selectedBookId, isDark),
            ),
            // Grid Menu
            SliverToBoxAdapter(
              child: _buildGridMenu(context, ref, isDark),
            ),
            // Hadith of the Day (Premium Card)
            SliverToBoxAdapter(
              child: _buildHadithOfTheDay(context, ref, isDark),
            ),
            // Stats Dashboard
            SliverToBoxAdapter(
              child: _buildStatsDashboard(context, ref, isDark),
            ),
            // Search Bar
            SliverToBoxAdapter(
              child: _buildSearchBar(context, ref, isDark),
            ),
            chaptersAsync.when(
              loading: () => SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) =>
                      ShimmerLoading(child: ShimmerLoading.chapterCard()),
                  childCount: 6,
                ),
              ),
              error: (e, st) =>
                  SliverFillRemaining(child: Center(child: Text('Error: $e'))),
              data: (chapters) {
                final progressAsync = ref.watch(chapterProgressProvider);
                final progressMap = progressAsync.value ?? {};
                return SliverList(
                  delegate: SliverChildBuilderDelegate((context, index) {
                    final chapter = chapters[index];
                    final progress = progressMap[chapter.id];
                    return RepaintBoundary(
                      child: _ChapterCard(
                        chapter: chapter,
                        index: index,
                        isDark: isDark,
                        progress: progress,
                      ),
                    );
                  }, childCount: chapters.length),
                );
              },
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 80)),
          ],
        ),
      ),
      floatingActionButton: _buildResumeButton(context, ref, isDark),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    ),
    );
  }

  Widget _buildHadithOfTheDay(
    BuildContext context,
    WidgetRef ref,
    bool isDark,
  ) {
    final hadithAsync = ref.watch(hadithOfTheDayProvider);
    final settings = ref.watch(settingsProvider);
    final selectedBookId = ref.watch(selectedBookIdProvider);
    final bookDark = AppTheme.getBookDarkColor(selectedBookId);
    final bookPrimary = AppTheme.getBookPrimaryColor(selectedBookId);
    final bookLight = AppTheme.getBookLightColor(selectedBookId);

    return hadithAsync.when(
      loading: () => const SizedBox(
        height: 150,
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (_, _) => const SizedBox.shrink(),
      data: (hadith) {
        if (hadith == null) return const SizedBox.shrink();
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isDark
                  ? [bookDark.withValues(alpha: 0.9), bookPrimary]
                  : [bookPrimary, bookLight],
            ),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: bookPrimary.withValues(alpha: 0.4),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: Stack(
              children: [
                Positioned(
                  right: -20,
                  top: -20,
                  child: Icon(
                    Icons.format_quote,
                    size: 150,
                    color: Colors.white.withValues(alpha: 0.05),
                  ),
                ),
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(24),
                    onTap: () async {
                      HapticFeedback.heavyImpact();
                      final repo = ref.read(hadithRepositoryProvider);
                      // FIX: Renamed getHadithIndexWithinChapter to getHadithIndex
                      final idx = await repo.getHadithIndex(
                        hadith.chapterId,
                        hadith.hadithNumber,
                      );
                      if (context.mounted) {
                        context.go(
                          '/home/chapter/${hadith.chapterId}?startIndex=$idx',
                        );
                      }
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.amber.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(30),
                                  border: Border.all(
                                    color: Colors.amber.withValues(alpha: 0.5),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(
                                      Icons.auto_awesome,
                                      color: Colors.amber,
                                      size: 14,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      // FIX: case-consistent check — 'English' (capital E)
                                      settings.titleLanguage == 'English'
                                          ? 'Hadith of the Day'
                                          : settings.titleLanguage == 'Arabic'
                                          ? 'حديث اليوم'
                                          : 'آج کی حدیث',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.amber,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Text(
                                settings.titleLanguage == 'English'
                                    ? 'Hadith #${hadith.hadithNumber}'
                                    : settings.titleLanguage == 'Arabic'
                                    ? 'رقم الحديث : ${hadith.hadithNumber}'
                                    : 'حدیث نمبر : ${hadith.hadithNumber}',
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.7),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          if (hadith.urduText.isNotEmpty)
                            Text(
                              hadith.urduText.length > 250
                                  ? '${hadith.urduText.substring(0, 250)}...'
                                  : hadith.urduText,
                              textAlign: TextAlign.right,
                              textDirection: TextDirection.rtl,
                              style: AppTheme.safeGetFont(
                                settings.urduFontFamily,
                                color: Colors.white,
                                fontSize: 18,
                                height: 2.2,
                                wordSpacing: 3.0,
                              ),
                              maxLines: 5,
                              overflow: TextOverflow.ellipsis,
                            ),
                          const SizedBox(height: 20),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Text(
                                settings.titleLanguage == 'English'
                                    ? 'Read Complete'
                                    : settings.titleLanguage == 'Arabic'
                                    ? 'اقرأ كامل'
                                    : 'مکمل پڑھیں',
                                style: TextStyle(
                                  color: Colors.amber.shade200,
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Icon(
                                Icons.arrow_forward_ios,
                                color: Colors.amber.shade200,
                                size: 14,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatsDashboard(
    BuildContext context,
    WidgetRef ref,
    bool isDark,
  ) {
    final statsAsync = ref.watch(statsProvider);

    return statsAsync.when(
      loading: () => const SizedBox(
        height: 120,
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (_, _) => const SizedBox.shrink(),
      data: (stats) {
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1A1A1A) : Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.05),
                blurRadius: 15,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.insights, color: AppTheme.getBookPrimaryColor(ref.watch(selectedBookIdProvider)), size: 20),
                  const SizedBox(width: 8),
                  const Text(
                    'پڑھنے کی تفصیلات (Insights)',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  _statsItem(
                    context,
                    'Bookmarks',
                    '${stats['bookmarks']}',
                    Icons.bookmark_added,
                    const Color(0xFFE91E63),
                    isDark: isDark,
                  ),
                  _statsItem(
                    context,
                    'Notes',
                    '${stats['notes']}',
                    Icons.note_alt,
                    const Color(0xFF2196F3),
                    isDark: isDark,
                  ),
                  _statsItem(
                    context,
                    'Progress',
                    '${stats['progress']}%',
                    Icons.auto_graph,
                    AppTheme.getBookPrimaryColor(ref.watch(selectedBookIdProvider)),
                    isDark: isDark,
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _statsItem(
    BuildContext context,
    String label,
    String value,
    IconData icon,
    Color color, {
    bool isDark = false,
  }) {
    return Expanded(
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: isDark ? Colors.grey.shade400 : Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBookSwitcher(
    BuildContext context,
    WidgetRef ref,
    int selectedBookId,
    bool isDark,
  ) {
    final booksAsync = ref.watch(allBooksProvider);
    final settings = ref.watch(settingsProvider);

    return booksAsync.when(
      data: (books) {
        return Container(
          height: 46,
          margin: const EdgeInsets.fromLTRB(12, 10, 12, 2),
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: books.length + 1,
            separatorBuilder: (_, index) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              if (index == 0) {
                return ActionChip(
                  avatar: const Icon(Icons.grid_view_rounded, size: 16, color: Colors.white),
                  label: Text(
                    settings.titleLanguage == 'English' ? 'All Books' : 'تمام کتب',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  backgroundColor: AppTheme.getBookPrimaryColor(selectedBookId),
                  side: BorderSide.none,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  onPressed: () {
                    HapticFeedback.lightImpact();
                    context.push('/books');
                  },
                );
              }

              final book = books[index - 1];
              final isSelected = book.id == selectedBookId;
              final bookColor = AppTheme.getBookPrimaryColor(book.id);

              final title = settings.titleLanguage == 'English'
                  ? book.nameEnglish
                  : book.nameUrdu;

              return FilterChip(
                selected: isSelected,
                label: Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                    color: isSelected
                        ? Colors.white
                        : (isDark ? Colors.white70 : Colors.black87),
                  ),
                ),
                selectedColor: bookColor,
                backgroundColor: isDark ? AppTheme.cardDark : Colors.grey.shade100,
                checkmarkColor: Colors.white,
                side: BorderSide(
                  color: isSelected
                      ? bookColor
                      : (isDark ? Colors.white12 : Colors.grey.shade300),
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                onSelected: (_) {
                  HapticFeedback.lightImpact();
                  ref.read(selectedBookIdProvider.notifier).selectBook(book.id);
                },
              );
            },
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, _) => const SizedBox.shrink(),
    );
  }

  Widget _buildGridMenu(BuildContext context, WidgetRef ref, bool isDark) {
    final menuItems = [
      _GridItem(
        Icons.find_in_page_rounded,
        const Color(0xFF1565C0),
        'Find Hadith',
        () => _showFindHadithDialog(context, ref),
      ),
      _GridItem(
        Icons.search_rounded,
        const Color(0xFFE91E63),
        'Search',
        () {
          final currentBookId = ref.read(selectedBookIdProvider);
          context.push('/home/search?bookId=$currentBookId');
        },
      ),
      _GridItem(
        Icons.bookmark_rounded,
        const Color(0xFFE65100),
        'Bookmarks',
        () => context.push('/home/bookmarks'),
      ),
      _GridItem(
        Icons.sticky_note_2_rounded,
        const Color(0xFF2E7D32),
        'Notes',
        () => context.push('/home/notes'),
      ),
      _GridItem(
        Icons.folder_rounded,
        const Color(0xFFF9A825),
        'Collections',
        () => context.push('/home/collections'),
      ),
      _GridItem(
        Icons.info_rounded,
        const Color(0xFF7B1FA2),
        'About',
        () => context.push('/home/about'),
      ),
      _GridItem(
        Icons.feedback_rounded,
        const Color(0xFF00897B),
        'Feedback',
        () => _showFeedbackDialog(context),
      ),
      _GridItem(Icons.share_rounded, const Color(0xFF0288D1), 'Share App', () {
        Share.share(
          'Download All Hadith (سب احادیث) — The complete Kutub al-Sittah collection with Urdu, Arabic & English translations.\nhttps://play.google.com/store/apps/details?id=com.taha.allhadithshahih',
        );
      }),
    ];

    return Container(
      padding: const EdgeInsets.fromLTRB(8, 12, 8, 4),
      child: Column(
        children: [
          Row(
            children: menuItems
                .sublist(0, 4)
                .map(
                  (item) => Expanded(child: _buildGridMenuItem(item, isDark)),
                )
                .toList(),
          ),
          const SizedBox(height: 4),
          Row(
            children: menuItems
                .sublist(4, 8)
                .map(
                  (item) => Expanded(child: _buildGridMenuItem(item, isDark)),
                )
                .toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildGridMenuItem(_GridItem item, bool isDark) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          HapticFeedback.lightImpact();
          item.onTap();
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(item.icon, size: 30, color: item.color),
              const SizedBox(height: 6),
              Text(
                item.label,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: isDark ? Colors.white70 : Colors.black87,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Find Hadith by Number ───
  // ─── Find Hadith by Number ───
  void _showFindHadithDialog(BuildContext context, WidgetRef ref) {
    final controller = TextEditingController();
    int? dialogBookId = ref.read(selectedBookIdProvider);

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) {
        bool isSearching = false;

        Future<void> openDirectly(StateSetter setDialogState) async {
          final input = controller.text.trim();
          if (input.isEmpty) return;
          setDialogState(() => isSearching = true);

          final repo = ref.read(hadithRepositoryProvider);
          final isNum = int.tryParse(input) != null;

          if (!isNum) {
            // Non-numeric input -> redirect directly to full search screen
            if (!ctx.mounted) return;
            Navigator.pop(ctx);
            if (context.mounted) {
              final bParam = dialogBookId != null ? '&bookId=$dialogBookId' : '';
              context.push('/home/search?q=${Uri.encodeComponent(input)}$bParam');
            }
            return;
          }

          // First search within selected book
          Hadith? result = await repo.getHadithByNumber(input, bookId: dialogBookId);
          result ??= await repo.getHadithByGlobalNumber(input, bookId: dialogBookId);
          // Fallback to any book if not found in current book
          result ??= await repo.getHadithByNumber(input);
          result ??= await repo.getHadithById(int.tryParse(input) ?? -1);

          if (!ctx.mounted) return;
          Navigator.pop(ctx);

          if (result != null && context.mounted) {
            await ref.read(selectedBookIdProvider.notifier).selectBook(result.bookId);
            final hIndex = await repo.getHadithIndex(
              result.chapterId,
              result.hadithNumber,
            );
            if (context.mounted) {
              context.push(
                '/home/chapter/${result.chapterId}?startIndex=$hIndex',
              );
            }
          } else if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Hadith #$input not found'),
                action: SnackBarAction(
                  label: 'SEARCH',
                  onPressed: () {
                    final bParam = dialogBookId != null ? 'bookId=$dialogBookId&' : '';
                    context.push('/home/search?${bParam}q=${Uri.encodeComponent(input)}');
                  },
                ),
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        }

        void goToSearchScreen() {
          final input = controller.text.trim();
          Navigator.pop(ctx);
          if (context.mounted) {
            final bParam = dialogBookId != null ? 'bookId=$dialogBookId' : '';
            final qParam = input.isNotEmpty ? (bParam.isNotEmpty ? '&q=${Uri.encodeComponent(input)}' : 'q=${Uri.encodeComponent(input)}') : '';
            final queryStr = (bParam.isNotEmpty || qParam.isNotEmpty) ? '?$bParam$qParam' : '';
            context.push('/home/search$queryStr');
          }
        }

        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            final isDark = Theme.of(ctx).brightness == Brightness.dark;
            final activeColor = dialogBookId != null
                ? AppTheme.getBookPrimaryColor(dialogBookId!)
                : Theme.of(ctx).primaryColor;

            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: Row(
                children: [
                  Icon(
                    Icons.find_in_page_rounded,
                    color: activeColor,
                  ),
                  const SizedBox(width: 8),
                  const Text('Find Hadith'),
                ],
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Hadith number ya search keyword dalein:',
                      style: TextStyle(
                        color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Quick Book Selector Chips
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _buildDialogBookChip('All Books', null, dialogBookId, (id) {
                            setDialogState(() => dialogBookId = id);
                          }, isDark),
                          const SizedBox(width: 5),
                          _buildDialogBookChip('Bukhari', 1, dialogBookId, (id) {
                            setDialogState(() => dialogBookId = id);
                          }, isDark),
                          const SizedBox(width: 5),
                          _buildDialogBookChip('Muslim', 2, dialogBookId, (id) {
                            setDialogState(() => dialogBookId = id);
                          }, isDark),
                          const SizedBox(width: 5),
                          _buildDialogBookChip('Abu Dawood', 3, dialogBookId, (id) {
                            setDialogState(() => dialogBookId = id);
                          }, isDark),
                          const SizedBox(width: 5),
                          _buildDialogBookChip('Tirmidhi', 4, dialogBookId, (id) {
                            setDialogState(() => dialogBookId = id);
                          }, isDark),
                          const SizedBox(width: 5),
                          _buildDialogBookChip("Nasa'i", 5, dialogBookId, (id) {
                            setDialogState(() => dialogBookId = id);
                          }, isDark),
                          const SizedBox(width: 5),
                          _buildDialogBookChip('Ibn Majah', 6, dialogBookId, (id) {
                            setDialogState(() => dialogBookId = id);
                          }, isDark),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),

                    TextField(
                      controller: controller,
                      keyboardType: TextInputType.text,
                      autofocus: true,
                      enabled: !isSearching,
                      onSubmitted: (_) => openDirectly(setDialogState),
                      decoration: InputDecoration(
                        hintText: 'Hadith # (e.g. 1, 50, 1234) or keyword',
                        hintStyle: TextStyle(
                          fontSize: 13,
                          color: isDark ? Colors.grey.shade500 : Colors.grey.shade400,
                        ),
                        prefixIcon: isSearching
                            ? const Padding(
                                padding: EdgeInsets.all(12),
                                child: SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                ),
                              )
                            : Icon(Icons.tag, color: activeColor),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: activeColor, width: 1.5),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isSearching ? null : () => Navigator.pop(ctx),
                  child: const Text('CANCEL'),
                ),
                OutlinedButton.icon(
                  icon: const Icon(Icons.search, size: 16),
                  label: const Text('SEARCH'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: activeColor,
                    side: BorderSide(color: activeColor),
                  ),
                  onPressed: isSearching ? null : goToSearchScreen,
                ),
                FilledButton.icon(
                  icon: isSearching
                      ? const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.arrow_forward, size: 16),
                  label: const Text('OPEN'),
                  style: FilledButton.styleFrom(
                    backgroundColor: activeColor,
                  ),
                  onPressed: isSearching
                      ? null
                      : () => openDirectly(setDialogState),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildDialogBookChip(
    String label,
    int? bookId,
    int? selectedId,
    ValueChanged<int?> onSelect,
    bool isDark,
  ) {
    final isSelected = selectedId == bookId;
    final color = bookId != null
        ? AppTheme.getBookPrimaryColor(bookId)
        : const Color(0xFF1565C0);

    return GestureDetector(
      onTap: () => onSelect(bookId),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected
              ? color
              : (isDark ? Colors.grey.shade800 : Colors.grey.shade200),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? color
                : (isDark ? Colors.grey.shade700 : Colors.grey.shade300),
            width: 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            color: isSelected
                ? Colors.white
                : (isDark ? Colors.grey.shade300 : Colors.grey.shade800),
          ),
        ),
      ),
    );
  }

  // ─── 24-Hour Ad-Free Pass Dialog (Jami` at-Tirmidhi model) ───
  void _showAdFreePassDialog(BuildContext context, int selectedBookId) {
    HapticFeedback.lightImpact();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = AppTheme.getBookPrimaryColor(selectedBookId);

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
                      'All banner ads and transition ads are completely turned off. Enjoy peaceful, distraction-free reading and recitation!',
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

  // ─── Feedback Dialog — FIX: now redirects to email ───
  void _showFeedbackDialog(BuildContext context) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Icon(Icons.feedback_rounded, color: Theme.of(ctx).primaryColor),
              const SizedBox(width: 8),
              const Text('Feedback'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Share your feedback, suggestions, or report issues.',
                style: TextStyle(
                  color: isDark ? Colors.white70 : Colors.black54,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: controller,
                maxLines: 4,
                decoration: InputDecoration(
                  hintText: 'Write your feedback here...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('CANCEL'),
            ),
            FilledButton.icon(
              icon: const Icon(Icons.email_outlined, size: 18),
              label: const Text('SEND EMAIL'),
              onPressed: () async {
                Navigator.pop(ctx);
                final subject = Uri.encodeComponent(
                  'All Hadith App Feedback',
                );
                final body = Uri.encodeComponent(
                  controller.text.trim().isNotEmpty
                      ? controller.text.trim()
                      : 'Feedback from All Hadith App user.',
                );
                final emailUri = Uri.parse(
                  'mailto:timam3730@gmail.com?subject=$subject&body=$body',
                );
                if (await canLaunchUrl(emailUri)) {
                  await launchUrl(emailUri);
                } else if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Email app not found. Please email manually at timam3730@gmail.com.',
                      ),
                    ),
                  );
                }
              },
            ),
          ],
        );
      },
    );
  }

  // ─── Backup Dialog ───
  void _showBackupDialog(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet(
      context: context,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Icon(Icons.backup, color: Theme.of(ctx).primaryColor, size: 28),
                const SizedBox(width: 12),
                const Text(
                  'Backup & Restore',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
                ),
              ],
            ),
            const SizedBox(height: 20),
            ListTile(
              leading: Icon(Icons.cloud_upload, color: Colors.green.shade600),
              title: const Text('Export Backup'),
              subtitle: const Text('Save bookmarks, notes & collections'),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              tileColor: isDark ? Colors.grey.shade800 : Colors.grey.shade50,
              onTap: () async {
                final repo = ref.read(hadithRepositoryProvider);
                final data = await repo.exportUserData();
                if (!ctx.mounted) return;
                Navigator.pop(ctx);
                final text = jsonEncode(data);
                await Clipboard.setData(ClipboardData(text: text));
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Backup copied to clipboard! ✓'),
                    ),
                  );
                }
              },
            ),
            const SizedBox(height: 8),
            ListTile(
              leading: Icon(Icons.cloud_download, color: Colors.blue.shade600),
              title: const Text('Import Backup'),
              subtitle: const Text('Restore from backup data'),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              tileColor: isDark ? Colors.grey.shade800 : Colors.grey.shade50,
              onTap: () {
                Navigator.pop(ctx);
                _showImportDialog(context, ref);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showImportDialog(BuildContext context, WidgetRef ref) {
    final TextEditingController controller = TextEditingController();
    bool isImporting = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: const Text('Import Backup'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Paste your previously copied backup text below to restore your bookmarks, notes, and collections.',
              ),
              const SizedBox(height: 16),
              TextField(
                controller: controller,
                maxLines: 4,
                decoration: const InputDecoration(
                  hintText: 'Paste backup here...',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: isImporting ? null : () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: isImporting
                  ? null
                  : () async {
                      final text = controller.text.trim();
                      if (text.isEmpty) return;

                      setState(() => isImporting = true);
                      try {
                        final data = jsonDecode(text) as Map<String, dynamic>;
                        final repo = ref.read(hadithRepositoryProvider);
                        final importedCount = await repo.importUserData(data);

                        if (context.mounted) {
                          Navigator.pop(ctx);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'Successfully restored $importedCount records! ✓',
                              ),
                            ),
                          );
                          ref.invalidate(chaptersProvider);
                          ref.invalidate(hadithOfTheDayProvider);
                          ref.invalidate(statsProvider);
                        }
                      } catch (e) {
                        setState(() => isImporting = false);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'Invalid backup data. Import failed: $e',
                              ),
                            ),
                          );
                        }
                      }
                    },
              child: isImporting
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Restore'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar(BuildContext context, WidgetRef ref, bool isDark) {
    return GestureDetector(
      onTap: () {
        final currentBookId = ref.read(selectedBookIdProvider);
        context.push('/home/search?bookId=$currentBookId');
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isDark ? AppTheme.cardDark : Colors.white,
          borderRadius: BorderRadius.circular(30),
          border: Border.all(
            color: Theme.of(context).primaryColor.withValues(alpha: 0.3),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                'باب عنوان کے ذریعے تلاش کریں',
                textAlign: TextAlign.right,
                style: TextStyle(
                  color: isDark ? Colors.white70 : Colors.grey.shade500,
                  fontSize: 14,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              Icons.search,
              color: Theme.of(context).primaryColor.withValues(alpha: 0.7),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResumeButton(BuildContext context, WidgetRef ref, bool isDark) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 60),
      child: Material(
        color: isDark ? AppTheme.cardDark : Colors.white,
        borderRadius: BorderRadius.circular(30),
        elevation: 4,
        shadowColor: Theme.of(context).primaryColor.withValues(alpha: 0.3),
        child: InkWell(
          borderRadius: BorderRadius.circular(30),
          onTap: () async {
            HapticFeedback.lightImpact();
            final repo = ref.read(hadithRepositoryProvider);
            final bookId = ref.read(selectedBookIdProvider);

            // Fetch last reading progress for this specific selected book
            final progress = await repo.getLastReadingProgress(bookId: bookId);

            // Safe fallback to SharedPreferences for this book
            final prefs = await SharedPreferences.getInstance();
            final spChapter = prefs.getInt('last_read_chapter_id_$bookId');
            final spIndex = prefs.getInt('last_read_hadith_index_$bookId');

            int chapterId;
            int startIndex;

            if (progress != null) {
              chapterId = progress.chapterId;
              startIndex = progress.hadithIndex;
            } else if (spChapter != null) {
              chapterId = spChapter;
              startIndex = spIndex ?? 0;
            } else {
              // If user has not read this book yet, get the first chapter of THIS BOOK!
              final chapters = await repo.getChaptersByBook(bookId);
              chapterId = chapters.isNotEmpty ? chapters.first.id : 1;
              startIndex = 0;
            }

            if (context.mounted) {
              await context.push(
                '/home/chapter/$chapterId?startIndex=$startIndex',
              );
              // Invalidate progress on return to refresh dashboard/button
              ref.invalidate(lastProgressProvider);
              ref.invalidate(chapterProgressProvider);
              ref.invalidate(statsProvider);
            }
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(30),
              border: Border.all(
                color: Theme.of(context).primaryColor,
                width: 1.5,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.access_time,
                  color: Theme.of(context).primaryColor,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'Resume Hadith Reading',
                  style: TextStyle(
                    color: Theme.of(context).primaryColor,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ChapterCard extends ConsumerWidget {
  final Chapter chapter;
  final int index;
  final bool isDark;
  final double? progress;

  const _ChapterCard({
    required this.chapter,
    required this.index,
    required this.isDark,
    this.progress,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);

    return GestureDetector(
          onTap: () {
            context.push('/home/chapterList/${chapter.id}');
          },
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: isDark ? AppTheme.cardDark : Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 0,
                        vertical: 4,
                      ),
                      child: Text(
                        '${chapter.hadithCount} احادیث',
                        style: TextStyle(
                          fontSize: 14,
                          color: isDark ? Colors.grey.shade400 : Colors.black87,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        // FIX: case-consistent check — 'English' / 'Arabic' / 'Urdu'
                        settings.titleLanguage == 'English'
                            ? chapter.titleEnglish
                            : settings.titleLanguage == 'Arabic'
                            ? chapter.titleArabic
                            : chapter.titleUrdu,
                        textAlign: settings.titleLanguage == 'English'
                            ? TextAlign.left
                            : TextAlign.right,
                        textDirection: settings.titleLanguage == 'English'
                            ? TextDirection.ltr
                            : TextDirection.rtl,
                        style: AppTheme.safeGetFont(
                          settings.activeFontFamily,
                          fontSize: 18,
                          height: 2.2,
                          wordSpacing: 2.5,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    SizedBox(
                      width: 24,
                      child: Text(
                        '${chapter.bookNumber}',
                        textAlign: TextAlign.right,
                        style: TextStyle(
                          color: Theme.of(context).primaryColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                    ),
                  ],
                ),
                // Progress bar
                if (progress != null && progress! > 0) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Text(
                        '${(progress! * 100).toInt()}%',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Theme.of(context).primaryColor,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: progress!,
                            minHeight: 4,
                            backgroundColor: isDark
                                ? Colors.grey.shade800
                                : Colors.grey.shade200,
                            valueColor: AlwaysStoppedAnimation(
                              progress! >= 1.0
                                  ? Colors.green
                                  : Theme.of(context).primaryColor,
                            ),
                          ),
                        ),
                      ),
                      if (progress! >= 1.0) ...[
                        const SizedBox(width: 6),
                        const Icon(
                          Icons.check_circle,
                          color: Colors.green,
                          size: 16,
                        ),
                      ],
                    ],
                  ),
                ],
              ],
            ),
          ),
        )
        .animate()
        .fade(
          duration: 300.ms,
          delay: (index * 30).ms < 600.ms ? (index * 30).ms : 0.ms,
        )
        .slideX(begin: 0.05, end: 0, duration: 300.ms, curve: Curves.easeOut);
  }
}

class _GridItem {
  final IconData icon;
  final Color color;
  final String label;
  final VoidCallback onTap;

  const _GridItem(this.icon, this.color, this.label, this.onTap);
}
