import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';

import '../../theme/app_theme.dart';
import '../../domain/models/models.dart';
import '../../widgets/banner_ad_widget.dart';
import '../settings/settings_provider.dart';
import 'book_provider.dart';

class BookSelectionScreen extends ConsumerWidget {
  const BookSelectionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final booksAsync = ref.watch(allBooksProvider);
    final selectedBookId = ref.watch(selectedBookIdProvider);
    final settings = ref.watch(settingsProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      bottomNavigationBar: const BannerAdWidget(),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // Elegant Header AppBar
          SliverAppBar(
            expandedHeight: 180,
            floating: false,
            pinned: true,
            backgroundColor: AppTheme.getBookPrimaryColor(selectedBookId),
            flexibleSpace: FlexibleSpaceBar(
              centerTitle: true,
              titlePadding: const EdgeInsets.only(bottom: 16),
              title: Text(
                settings.titleLanguage == 'English'
                    ? 'All Hadith'
                    : 'سب احادیث — کتب صحاح ستہ',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  shadows: [
                    Shadow(
                      offset: Offset(0, 1),
                      blurRadius: 3.0,
                      color: Colors.black45,
                    ),
                  ],
                ),
              ),
              background: Container(
                decoration: BoxDecoration(
                  gradient: AppTheme.getBookGradient(selectedBookId),
                ),
                child: Stack(
                  children: [
                    // Islamic geometric overlay subtle pattern
                    Positioned(
                      right: -30,
                      top: -30,
                      child: Icon(
                        Icons.auto_stories,
                        size: 200,
                        color: Colors.white.withValues(alpha: 0.08),
                      ),
                    ),
                    Positioned(
                      left: -20,
                      bottom: -20,
                      child: Icon(
                        Icons.menu_book_rounded,
                        size: 160,
                        color: Colors.white.withValues(alpha: 0.06),
                      ),
                    ),
                    SafeArea(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 16, 20, 48),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.2),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: const Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.verified_rounded,
                                        size: 14,
                                        color: Colors.white,
                                      ),
                                      SizedBox(width: 5),
                                      Text(
                                        'الصحاح الستة • 6 Authentic Books',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Row(
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.settings_outlined, color: Colors.white),
                                      tooltip: 'Settings',
                                      onPressed: () => context.push('/home/settings'),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            const Spacer(),
                            Text(
                              settings.titleLanguage == 'English'
                                  ? 'Select a Hadith Collection to Begin'
                                  : 'مطالعہ کے لیے کتاب کا انتخاب کریں',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.92),
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Subtitle / Intro Bar
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(18, 18, 18, 8),
              child: Row(
                children: [
                  Container(
                    width: 4,
                    height: 18,
                    decoration: BoxDecoration(
                      color: AppTheme.getBookPrimaryColor(selectedBookId),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    settings.titleLanguage == 'English'
                        ? 'Kutub al-Sittah (The Six Books)'
                        : 'کتب ستہ احادیث نبویہ ﷺ',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : AppTheme.textDark,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '34,486 احادیث',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // 2-Column Responsive Book Cards Grid
          booksAsync.when(
            data: (books) {
              return SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                sliver: SliverGrid(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.62,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 14,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final book = books[index];
                      final isSelected = book.id == selectedBookId;
                      final bookColor = AppTheme.getBookPrimaryColor(book.id);

                      return _BookCard(
                        book: book,
                        isSelected: isSelected,
                        bookColor: bookColor,
                        isDark: isDark,
                        settings: settings,
                        onTap: () {
                          HapticFeedback.lightImpact();
                          ref
                              .read(selectedBookIdProvider.notifier)
                              .selectBook(book.id);
                          context.go('/home');
                        },
                      ).animate().fadeIn(
                            delay: Duration(milliseconds: 60 * index),
                            duration: 350.ms,
                          ).slideY(
                            begin: 0.1,
                            end: 0,
                            curve: Curves.easeOutQuad,
                          );
                    },
                    childCount: books.length,
                  ),
                ),
              );
            },
            loading: () => const SliverToBoxAdapter(
              child: Center(
                child: Padding(
                  padding: EdgeInsets.all(40.0),
                  child: CircularProgressIndicator(),
                ),
              ),
            ),
            error: (err, _) => SliverToBoxAdapter(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(40.0),
                  child: Text('Error loading books: $err'),
                ),
              ),
            ),
          ),

          const SliverToBoxAdapter(
            child: SizedBox(height: 24),
          ),
        ],
      ),
    );
  }
}

class _BookCard extends StatelessWidget {
  final HadithBook book;
  final bool isSelected;
  final Color bookColor;
  final bool isDark;
  final AppSettings settings;
  final VoidCallback onTap;

  const _BookCard({
    required this.book,
    required this.isSelected,
    required this.bookColor,
    required this.isDark,
    required this.settings,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final title = settings.titleLanguage == 'English'
        ? book.nameEnglish
        : settings.titleLanguage == 'Arabic'
            ? book.nameArabic
            : book.nameUrdu;

    final author = settings.titleLanguage == 'English'
        ? book.authorEnglish
        : book.authorUrdu;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          decoration: BoxDecoration(
            color: isDark ? AppTheme.cardDark : AppTheme.cardWhite,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected
                  ? bookColor
                  : (isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.06)),
              width: isSelected ? 2.5 : 1.0,
            ),
            boxShadow: [
              BoxShadow(
                color: isSelected
                    ? bookColor.withValues(alpha: 0.22)
                    : (isDark
                        ? Colors.black26
                        : Colors.black.withValues(alpha: 0.05)),
                blurRadius: isSelected ? 12 : 6,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(10.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Real 3D Book Cover Image (Isolated Front-View)
                Expanded(
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Book Cover Container with authentic book drop shadow
                      Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.25),
                              blurRadius: 8,
                              offset: const Offset(2, 4),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.asset(
                            book.coverAsset,
                            fit: BoxFit.contain,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                color: bookColor.withValues(alpha: 0.15),
                                child: Center(
                                  child: Icon(
                                    Icons.auto_stories,
                                    size: 48,
                                    color: bookColor,
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ),

                      // Selected active badge overlay
                      if (isSelected)
                        Positioned(
                          top: 4,
                          right: 4,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: bookColor,
                              shape: BoxShape.circle,
                              boxShadow: const [
                                BoxShadow(
                                  color: Colors.black26,
                                  blurRadius: 4,
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.check,
                              color: Colors.white,
                              size: 14,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),

                const SizedBox(height: 8),

                // Book Title
                Text(
                  title,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: isSelected
                        ? bookColor
                        : (isDark ? Colors.white : AppTheme.textDark),
                  ),
                ),

                const SizedBox(height: 2),

                // Author Name
                Text(
                  author,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 10.5,
                    color: isDark ? Colors.grey.shade400 : AppTheme.textLight,
                  ),
                ),

                const SizedBox(height: 6),

                // Stats Badges (Hadith & Chapter counts)
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _Badge(
                      label: '${book.hadithCount} احادیث',
                      color: bookColor,
                      isDark: isDark,
                    ),
                    const SizedBox(width: 4),
                    _Badge(
                      label: '${book.chapterCount} ابواب',
                      color: Colors.grey.shade600,
                      isDark: isDark,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  final String label;
  final Color color;
  final bool isDark;

  const _Badge({
    required this.label,
    required this.color,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: isDark ? 0.2 : 0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 9.5,
          fontWeight: FontWeight.w600,
          color: isDark ? Colors.white70 : color,
        ),
      ),
    );
  }
}
