import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../theme/app_theme.dart';
import '../../data/repositories/hadith_repository.dart';
import '../../core/ads/ad_service.dart';
import '../../widgets/banner_ad_widget.dart';
import '../../domain/models/models.dart';
import '../settings/settings_provider.dart';
import '../common/widgets/shimmer_loading.dart';

final chaptersProvider = FutureProvider<List<Chapter>>((ref) async {
  final repo = ref.watch(hadithRepositoryProvider);
  return repo.getChapters();
});

final hadithOfTheDayProvider = FutureProvider<Hadith?>((ref) async {
  final repo = ref.watch(hadithRepositoryProvider);
  // FIX: Now returns a consistent hadith per day, not a different one on every restart
  return repo.getHadithOfTheDay();
});

final statsProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final repo = ref.watch(hadithRepositoryProvider);
  final bookmarks = await repo.getBookmarkCount();
  final notes = await repo.getNotesCount();
  final readChapters = await repo.getTotalReadChapters();
  final totalChapters = await repo.getTotalChapterCount();
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
  final rows = await repo.getAllChapterProgress();
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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Sahih Bukhari',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.volunteer_activism, color: Colors.amber),
            tooltip: 'Support App (Watch Ad)',
            onPressed: () {
              HapticFeedback.heavyImpact();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Loading Rewarded Ad... Thank you! 💚'),
                  duration: Duration(seconds: 2),
                ),
              );
              AdService.showRewardedAd(
                onUserEarnedReward: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('JazakAllah Khair! Thank you for supporting the app! 💚'),
                      backgroundColor: Color(0xFF0A7E47),
                    ),
                  );
                },
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              HapticFeedback.lightImpact();
              context.go('/home/settings');
            },
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (value) {
              HapticFeedback.selectionClick();
              switch (value) {
                case 'Backup':
                  _showBackupDialog(context, ref);
                  break;
                case 'Author':
                  context.go('/home/about');
                  break;
                case 'AppIntro':
                  context.go('/home/about');
                  break;
              }
            },
            itemBuilder: (context) => [
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
            // Grid Menu
            SliverToBoxAdapter(
              child: _buildGridMenu(context, ref, isDark)
                  .animate()
                  .fadeIn(duration: 600.ms)
                  .slideY(begin: -0.1, end: 0, curve: Curves.easeOutCubic),
            ),
            // Hadith of the Day (Premium Card)
            SliverToBoxAdapter(
              child: _buildHadithOfTheDay(context, ref, isDark)
                  .animate()
                  .fadeIn(delay: 150.ms, duration: 600.ms)
                  .scale(
                    begin: const Offset(0.95, 0.95),
                    end: const Offset(1, 1),
                    curve: Curves.easeOutBack,
                  ),
            ),
            // Stats Dashboard
            SliverToBoxAdapter(
              child: _buildStatsDashboard(context, ref, isDark)
                  .animate()
                  .fadeIn(delay: 300.ms, duration: 600.ms)
                  .slideX(begin: 0.1, end: 0),
            ),
            // Search Bar
            SliverToBoxAdapter(
              child: _buildSearchBar(context, isDark)
                  .animate()
                  .fadeIn(delay: 400.ms, duration: 600.ms)
                  .shimmer(color: Colors.white24),
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
                    return _ChapterCard(
                      chapter: chapter,
                      index: index,
                      isDark: isDark,
                      progress: progress,
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
      bottomNavigationBar: const BannerAdWidget(),
    );
  }

  Widget _buildHadithOfTheDay(
    BuildContext context,
    WidgetRef ref,
    bool isDark,
  ) {
    final hadithAsync = ref.watch(hadithOfTheDayProvider);
    final settings = ref.watch(settingsProvider);

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
                  ? [const Color(0xFF0F3024), const Color(0xFF0A7E47)]
                  : [const Color(0xFF0A7E47), const Color(0xFF14A361)],
            ),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF0A7E47).withValues(alpha: 0.4),
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
              const Row(
                children: [
                  Icon(Icons.insights, color: Color(0xFF0A7E47), size: 20),
                  SizedBox(width: 8),
                  Text(
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
                    const Color(0xFF0A7E47),
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
        () => context.go('/home/search'),
      ),
      _GridItem(
        Icons.bookmark_rounded,
        const Color(0xFFE65100),
        'Bookmarks',
        () => context.go('/home/bookmarks'),
      ),
      _GridItem(
        Icons.sticky_note_2_rounded,
        const Color(0xFF2E7D32),
        'Notes',
        () => context.go('/home/notes'),
      ),
      _GridItem(
        Icons.folder_rounded,
        const Color(0xFFF9A825),
        'Collections',
        () => context.go('/home/collections'),
      ),
      _GridItem(
        Icons.info_rounded,
        const Color(0xFF7B1FA2),
        'About',
        () => context.go('/home/about'),
      ),
      _GridItem(
        Icons.feedback_rounded,
        const Color(0xFF00897B),
        'Feedback',
        () => _showFeedbackDialog(context),
      ),
      _GridItem(Icons.share_rounded, const Color(0xFF0288D1), 'Share App', () {
        Share.share(
          'Download Sahih Bukhari App — The most authentic collection of Hadith with Urdu, Arabic & English translations.\nhttps://play.google.com/store/apps/details?id=com.albukhari.hadith',
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
  void _showFindHadithDialog(BuildContext context, WidgetRef ref) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) {
        bool isSearching = false;
        Future<void> doSearch(StateSetter setDialogState) async {
          final input = controller.text.trim();
          if (input.isEmpty) return;
          setDialogState(() => isSearching = true);
          final repo = ref.read(hadithRepositoryProvider);
          Hadith? result = await repo.getHadithByNumber(input);
          result ??= await repo.getHadithById(int.tryParse(input) ?? -1);
          if (!ctx.mounted) return;
          Navigator.pop(ctx);
          if (result != null && context.mounted) {
            final hIndex = await repo.getHadithIndex(
              result.chapterId,
              result.hadithNumber,
            );
            if (context.mounted) {
              context.go(
                '/home/chapter/${result.chapterId}?startIndex=$hIndex',
              );
            }
          } else if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Hadith #$input not found'),
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        }

        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: Row(
                children: [
                  Icon(
                    Icons.find_in_page_rounded,
                    color: Theme.of(ctx).primaryColor,
                  ),
                  const SizedBox(width: 8),
                  const Text('Find Hadith'),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Hadith number dalein — seedha us hadith par jaayega.',
                    style: TextStyle(color: Colors.grey, fontSize: 13),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: controller,
                    keyboardType: TextInputType.number,
                    autofocus: true,
                    enabled: !isSearching,
                    onSubmitted: (_) => doSearch(setDialogState),
                    decoration: InputDecoration(
                      hintText: 'e.g. 1, 100, 2000',
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
                          : const Icon(Icons.tag),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: isSearching ? null : () => Navigator.pop(ctx),
                  child: const Text('CANCEL'),
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
                      : const Icon(Icons.search, size: 18),
                  label: const Text('GO'),
                  onPressed: isSearching
                      ? null
                      : () => doSearch(setDialogState),
                ),
              ],
            );
          },
        );
      },
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
                  'Sahih Bukhari App Feedback',
                );
                final body = Uri.encodeComponent(
                  controller.text.trim().isNotEmpty
                      ? controller.text.trim()
                      : 'Feedback from Sahih Bukhari App user.',
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

  Widget _buildSearchBar(BuildContext context, bool isDark) {
    return GestureDetector(
      onTap: () => context.go('/home/search'),
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
    final progressAsync = ref.watch(lastProgressProvider);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 60),
      child: Material(
        color: isDark ? AppTheme.cardDark : Colors.white,
        borderRadius: BorderRadius.circular(30),
        elevation: 4,
        shadowColor: Theme.of(context).primaryColor.withValues(alpha: 0.3),
        child: InkWell(
          borderRadius: BorderRadius.circular(30),
          onTap: () {
            progressAsync.whenData((progress) {
              if (progress != null) {
                context.go(
                  '/home/chapter/${progress.chapterId}?startIndex=${progress.hadithIndex}',
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Start reading a hadith to enable resume!'),
                  ),
                );
              }
            });
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
          onTap: () => context.go('/home/chapterList/${chapter.id}'),
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
                        '${chapter.id}',
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
