import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../theme/app_theme.dart';
import '../../data/repositories/hadith_repository.dart';
import '../../domain/models/models.dart';
import '../settings/settings_provider.dart';
import '../collections/collections_screen.dart';
import '../books/book_provider.dart';
import '../common/widgets/hadith_grade_badge.dart';

class SearchScreen extends ConsumerStatefulWidget {
  final int? initialBookId;
  final String? initialQuery;

  const SearchScreen({
    super.key,
    this.initialBookId,
    this.initialQuery,
  });

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final _controller = TextEditingController();

  // Book Filter: null means all books
  int? _selectedBookId;

  // Language Filter: 'All', 'Urdu', 'English', 'Arabic'
  String _selectedLanguage = 'All';

  // FIX: This filter now actually applies the isPrimary filter
  bool _onlyPrimaryHadiths = true;
  bool _partialMatch = true;

  List<Hadith> _results = [];
  bool _isLoading = false;
  bool _hasSearched = false;
  bool _hasMore = false;
  int _currentPage = 0;
  static const int _pageSize = 30;

  bool _isLtrText() {
    if (_selectedLanguage == 'English') return true;
    if (_selectedLanguage == 'Arabic' || _selectedLanguage == 'Urdu') return false;
    final text = _controller.text.trim();
    if (text.isEmpty) return false;
    return RegExp(r'^[a-zA-Z0-9]').hasMatch(text);
  }

  String _getHintText() {
    switch (_selectedLanguage) {
      case 'Arabic':
        return 'ابحث بنص الحديث بالعربية (مثال: نية، صلاة)';
      case 'English':
        return 'Search hadith text in English (e.g. prayer)';
      case 'Urdu':
        return 'حدیث کا اردو متن تلاش کریں (مثلاً: نماز، نیت)';
      default:
        return 'Search in Urdu, English, Arabic or #...';
    }
  }

  @override
  void initState() {
    super.initState();
    if (widget.initialBookId != null) {
      _selectedBookId = widget.initialBookId == 0 ? null : widget.initialBookId;
    } else {
      _selectedBookId = ref.read(selectedBookIdProvider);
    }

    if (widget.initialQuery != null && widget.initialQuery!.trim().isNotEmpty) {
      _controller.text = widget.initialQuery!.trim();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _performSearch();
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _performSearch({bool isNewSearch = true}) async {
    final query = _controller.text.trim();
    if (query.isEmpty) return;

    if (isNewSearch) {
      setState(() {
        _isLoading = true;
        _hasSearched = true;
        _results = [];
        _currentPage = 0;
        _hasMore = false;
      });
    } else {
      setState(() {
        _isLoading = true;
      });
    }

    final repo = ref.read(hadithRepositoryProvider);
    final isNumber = int.tryParse(query) != null;

    List<Hadith> newHadiths;
    if (isNumber) {
      if (_selectedBookId != null) {
        newHadiths = await repo.searchHadithsByNumber(
          query,
          bookId: _selectedBookId,
          onlyPrimary: _onlyPrimaryHadiths,
        );
        if (newHadiths.isEmpty) {
          final single = await repo.getHadithByGlobalNumber(
            query,
            bookId: _selectedBookId,
          );
          if (single != null) newHadiths = [single];
        }
      } else {
        newHadiths = await repo.searchHadithsByNumber(
          query,
          onlyPrimary: _onlyPrimaryHadiths,
        );
      }
      if (newHadiths.isEmpty) {
        newHadiths = await repo.searchHadiths(
          query,
          language: _selectedLanguage,
          bookId: _selectedBookId,
          onlyPrimary: _onlyPrimaryHadiths,
          exactMatch: !_partialMatch,
          offset: _currentPage * _pageSize,
          limit: _pageSize,
        );
      }
    } else {
      newHadiths = await repo.searchHadiths(
        query,
        language: _selectedLanguage,
        bookId: _selectedBookId,
        onlyPrimary: _onlyPrimaryHadiths,
        exactMatch: !_partialMatch,
        offset: _currentPage * _pageSize,
        limit: _pageSize,
      );
    }

    if (mounted) {
      setState(() {
        if (isNewSearch) {
          _results = newHadiths;
        } else {
          _results.addAll(newHadiths);
        }
        _isLoading = false;
        _hasMore = newHadiths.length >= _pageSize;
      });
    }
  }

  void _loadMore() {
    _currentPage++;
    _performSearch(isNewSearch: false);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final settings = ref.watch(settingsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Search Hadith'), centerTitle: true),
      body: Column(
        children: [
          // Search Card
          Container(
            margin: const EdgeInsets.all(12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? AppTheme.cardDark : Colors.white,
              borderRadius: BorderRadius.circular(16),
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
                // Search Field
                Container(
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: isDark
                          ? Colors.grey.shade700
                          : Colors.grey.shade300,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      IconButton(
                        icon: Icon(
                          Icons.search,
                          color: _selectedBookId != null
                              ? AppTheme.getBookPrimaryColor(_selectedBookId!)
                              : Theme.of(context).primaryColor,
                        ),
                        onPressed: _performSearch,
                      ),
                      Expanded(
                        child: TextField(
                          controller: _controller,
                          textAlign: _isLtrText() ? TextAlign.left : TextAlign.right,
                          textDirection: _isLtrText() ? TextDirection.ltr : TextDirection.rtl,
                          onSubmitted: (_) => _performSearch(),
                          onChanged: (_) => setState(() {}),
                          decoration: InputDecoration(
                            hintText: _getHintText(),
                            hintStyle: TextStyle(
                              color: isDark
                                  ? Colors.grey.shade500
                                  : Colors.grey.shade400,
                              fontSize: 13,
                            ),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 12,
                            ),
                          ),
                        ),
                      ),
                      if (_controller.text.isNotEmpty)
                        IconButton(
                          icon: Icon(
                            Icons.close,
                            size: 18,
                            color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                          ),
                          onPressed: () {
                            _controller.clear();
                            setState(() {
                              _results = [];
                              _hasSearched = false;
                            });
                          },
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // Book Selection Filter (All Books + Kutub al-Sittah)
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildBookChip('All Books', null, isDark),
                      const SizedBox(width: 6),
                      _buildBookChip('Bukhari', 1, isDark),
                      const SizedBox(width: 6),
                      _buildBookChip('Muslim', 2, isDark),
                      const SizedBox(width: 6),
                      _buildBookChip('Abu Dawood', 3, isDark),
                      const SizedBox(width: 6),
                      _buildBookChip('Tirmidhi', 4, isDark),
                      const SizedBox(width: 6),
                      _buildBookChip("Nasa'i", 5, isDark),
                      const SizedBox(width: 6),
                      _buildBookChip('Ibn Majah', 6, isDark),
                    ],
                  ),
                ).animate().fadeIn(delay: 80.ms),
                const SizedBox(height: 8),

                // Language Filter — All Languages, Urdu, English, Arabic
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildLanguageChip('All Languages (تمام)', 'All', isDark),
                      const SizedBox(width: 6),
                      _buildLanguageChip('اردو (Urdu)', 'Urdu', isDark),
                      const SizedBox(width: 6),
                      _buildLanguageChip('English', 'English', isDark),
                      const SizedBox(width: 6),
                      _buildLanguageChip('العربية (Arabic)', 'Arabic', isDark),
                    ],
                  ),
                ).animate().fadeIn(delay: 100.ms),
                const SizedBox(height: 6),

                // FIX: Sahih Only filter — now applies isPrimary filter
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildFilterChip(
                        'Primary Hadiths Only',
                        _onlyPrimaryHadiths,
                        () => setState(() => _onlyPrimaryHadiths = true),
                        isDark,
                      ),
                      const SizedBox(width: 8),
                      _buildFilterChip(
                        'All Hadiths',
                        !_onlyPrimaryHadiths,
                        () => setState(() => _onlyPrimaryHadiths = false),
                        isDark,
                      ),
                    ],
                  ),
                ).animate().fadeIn(delay: 200.ms),
                const SizedBox(height: 4),

                // Match Type
                Row(
                  children: [
                    _buildFilterChip(
                      'Partial Match',
                      _partialMatch,
                      () => setState(() => _partialMatch = true),
                      isDark,
                    ),
                    const SizedBox(width: 8),
                    _buildFilterChip(
                      'Exact Match',
                      !_partialMatch,
                      () => setState(() => _partialMatch = false),
                      isDark,
                    ),
                  ],
                ).animate().fadeIn(delay: 300.ms),
                const SizedBox(height: 12),

                // Action Row
                Row(
                  children: [
                    TextButton(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              '💡 Try searching by narrator name, keyword, or topic',
                            ),
                          ),
                        );
                      },
                      child: const Text(
                        'SEARCH TIPS',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(width: 12),
                    OutlinedButton.icon(
                          onPressed: _performSearch,
                          icon: const Icon(Icons.search, size: 18),
                          label: const Text('SEARCH'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Theme.of(context).primaryColor,
                            side: BorderSide(
                              color: Theme.of(context).primaryColor,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        )
                        .animate(
                          onPlay: (controller) =>
                              controller.repeat(reverse: true),
                        )
                        .shimmer(
                          duration: 2.seconds,
                          color: Theme.of(
                            context,
                          ).primaryColor.withValues(alpha: 0.2),
                        ),
                  ],
                ).animate().fadeIn(delay: 400.ms),
              ],
            ),
          ).animate().fadeIn(duration: 400.ms).slideY(begin: -0.05, end: 0),

          // Results
          Expanded(
            child: _isLoading && _results.isEmpty
                ? Center(
                    child: CircularProgressIndicator(
                      color: Theme.of(context).primaryColor,
                    ),
                  )
                : !_hasSearched
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.search,
                          size: 64,
                          color: isDark
                              ? Colors.grey.shade700
                              : Colors.grey.shade300,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Search for hadiths above',
                          style: TextStyle(color: Colors.grey.shade500),
                        ),
                      ],
                    ),
                  )
                : _results.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.search_off,
                          size: 64,
                          color: isDark
                              ? Colors.grey.shade700
                              : Colors.grey.shade300,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'No results found',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey.shade500,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Try different keywords',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey.shade400,
                          ),
                        ),
                      ],
                    ),
                  )
                : Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 4,
                        ),
                        child: Row(
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
                                '${_results.length}${_hasMore ? '+' : ''} result${_results.length > 1 ? 's' : ''} found',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: Theme.of(context).primaryColor,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          itemCount: _results.length + (_hasMore ? 1 : 0),
                          itemBuilder: (context, index) {
                            // Load More button
                            if (index == _results.length) {
                              return Padding(
                                padding: const EdgeInsets.all(16),
                                child: _isLoading
                                    ? const Center(
                                        child: CircularProgressIndicator(),
                                      )
                                    : OutlinedButton.icon(
                                        onPressed: _loadMore,
                                        icon: const Icon(Icons.expand_more),
                                        label: const Text('Load More Results'),
                                        style: OutlinedButton.styleFrom(
                                          foregroundColor: Theme.of(
                                            context,
                                          ).primaryColor,
                                          side: BorderSide(
                                            color: Theme.of(
                                              context,
                                            ).primaryColor,
                                          ),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                          ),
                                          padding: const EdgeInsets.symmetric(
                                            vertical: 12,
                                          ),
                                        ),
                                      ),
                              );
                            }

                            final hadith = _results[index];
                            final query = _controller.text.trim();
                            final bookColor = AppTheme.getBookPrimaryColor(hadith.bookId);

                            // Detect which text to display as primary
                            final bool isArMatch = _selectedLanguage == 'Arabic' ||
                                (_selectedLanguage == 'All' && _hasArabicMatch(hadith.arabicText, query));
                            final bool isEnMatch = _selectedLanguage == 'English' ||
                                (_selectedLanguage == 'All' &&
                                    hadith.englishText.toLowerCase().contains(query.toLowerCase()));
                            final bool isUrMatch = _selectedLanguage == 'Urdu' ||
                                (_selectedLanguage == 'All' && hadith.urduText.contains(query));

                            String primaryText;
                            TextStyle primaryStyle;
                            TextDirection primaryDirection;
                            bool isPrimaryArabic = false;
                            String? matchBadgeText;

                            String? secondaryText;
                            TextStyle? secondaryStyle;
                            TextDirection secondaryDirection = TextDirection.ltr;

                            if (isArMatch && hadith.arabicText.isNotEmpty) {
                              primaryText = hadith.arabicText;
                              primaryDirection = TextDirection.rtl;
                              isPrimaryArabic = true;
                              primaryStyle = AppTheme.safeGetFont(
                                settings.arabicFontFamily,
                                color: AppTheme.getFontColor(settings.arabicFontColor, isDark) ??
                                    (isDark ? Colors.white : AppTheme.textDark),
                                fontSize: 16,
                                height: 1.8,
                              );
                              if (_selectedLanguage == 'All' && query.isNotEmpty) {
                                matchBadgeText = 'Arabic Match';
                              }
                              if (hadith.urduText.isNotEmpty) {
                                secondaryText = hadith.urduText;
                                secondaryDirection = TextDirection.rtl;
                                secondaryStyle = AppTheme.safeGetFont(
                                  settings.activeFontFamily,
                                  color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                                  fontSize: 13,
                                  height: 1.6,
                                );
                              } else if (hadith.englishText.isNotEmpty) {
                                secondaryText = hadith.englishText;
                                secondaryDirection = TextDirection.ltr;
                                secondaryStyle = AppTheme.safeGetFont(
                                  settings.englishFontFamily,
                                  color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                                  fontSize: 12,
                                  height: 1.4,
                                );
                              }
                            } else if (isEnMatch && hadith.englishText.isNotEmpty) {
                              primaryText = hadith.englishText;
                              primaryDirection = TextDirection.ltr;
                              primaryStyle = AppTheme.safeGetFont(
                                settings.englishFontFamily,
                                color: AppTheme.getFontColor(settings.englishFontColor, isDark) ??
                                    (isDark ? Colors.grey.shade300 : Colors.grey.shade800),
                                fontSize: 13,
                                height: 1.5,
                              );
                              if (_selectedLanguage == 'All' && query.isNotEmpty) {
                                matchBadgeText = 'English Match';
                              }
                              if (hadith.urduText.isNotEmpty) {
                                secondaryText = hadith.urduText;
                                secondaryDirection = TextDirection.rtl;
                                secondaryStyle = AppTheme.safeGetFont(
                                  settings.activeFontFamily,
                                  color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                                  fontSize: 13,
                                  height: 1.6,
                                );
                              }
                            } else {
                              primaryText = hadith.urduText.isNotEmpty ? hadith.urduText : hadith.englishText;
                              primaryDirection = hadith.urduText.isNotEmpty ? TextDirection.rtl : TextDirection.ltr;
                              primaryStyle = hadith.urduText.isNotEmpty
                                  ? AppTheme.safeGetFont(
                                      settings.activeFontFamily,
                                      color: AppTheme.getFontColor(settings.urduFontColor, isDark) ??
                                          (isDark ? Colors.grey.shade200 : AppTheme.textDark),
                                      fontSize: 14,
                                      height: 1.8,
                                    )
                                  : AppTheme.safeGetFont(
                                      settings.englishFontFamily,
                                      color: AppTheme.getFontColor(settings.englishFontColor, isDark) ??
                                          (isDark ? Colors.grey.shade300 : Colors.grey.shade800),
                                      fontSize: 13,
                                      height: 1.5,
                                    );
                              if (_selectedLanguage == 'All' && isUrMatch && query.isNotEmpty) {
                                matchBadgeText = 'Urdu Match';
                              }
                              if (hadith.arabicText.isNotEmpty) {
                                secondaryText = hadith.arabicText;
                                secondaryDirection = TextDirection.rtl;
                                secondaryStyle = AppTheme.safeGetFont(
                                  settings.arabicFontFamily,
                                  color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                                  fontSize: 14,
                                  height: 1.6,
                                );
                              }
                            }

                            return RepaintBoundary(
                              child: Container(
                              margin: const EdgeInsets.only(bottom: 8),
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
                                    blurRadius: 4,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(12),
                                  onTap: () async {
                                    final repo = ref.read(
                                      hadithRepositoryProvider,
                                    );
                                    // Switch selected book to match this hadith's collection
                                    await ref.read(selectedBookIdProvider.notifier).selectBook(hadith.bookId);
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
                                  onLongPress: () =>
                                      _showAddToCollectionDialog(hadith),
                                  child: Padding(
                                    padding: const EdgeInsets.all(12),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            Expanded(
                                              child: Wrap(
                                                crossAxisAlignment: WrapCrossAlignment.center,
                                                spacing: 6,
                                                runSpacing: 4,
                                                children: [
                                                  Container(
                                                    padding: const EdgeInsets.symmetric(
                                                      horizontal: 6,
                                                      vertical: 2,
                                                    ),
                                                    decoration: BoxDecoration(
                                                      color: bookColor.withValues(alpha: 0.15),
                                                      borderRadius: BorderRadius.circular(4),
                                                      border: Border.all(
                                                        color: bookColor.withValues(alpha: 0.35),
                                                        width: 0.5,
                                                      ),
                                                    ),
                                                    child: Text(
                                                      _getBookShortName(hadith.bookId),
                                                      style: TextStyle(
                                                        fontWeight: FontWeight.bold,
                                                        fontSize: 11,
                                                        color: bookColor,
                                                      ),
                                                    ),
                                                  ),
                                                  Container(
                                                    padding: const EdgeInsets.symmetric(
                                                      horizontal: 6,
                                                      vertical: 2,
                                                    ),
                                                    decoration: BoxDecoration(
                                                      color: bookColor.withValues(alpha: 0.1),
                                                      borderRadius: BorderRadius.circular(4),
                                                    ),
                                                    child: Text(
                                                      '#${hadith.hadithNumber} — Ch. ${hadith.chapterId}',
                                                      style: TextStyle(
                                                        fontWeight: FontWeight.bold,
                                                        fontSize: 11,
                                                        color: bookColor,
                                                      ),
                                                    ),
                                                  ),
                                                  HadithGradeBadge(hadith: hadith),
                                                  if (matchBadgeText != null)
                                                    Container(
                                                      padding: const EdgeInsets.symmetric(
                                                        horizontal: 6,
                                                        vertical: 2,
                                                      ),
                                                      decoration: BoxDecoration(
                                                        color: Colors.amber.withValues(alpha: isDark ? 0.25 : 0.15),
                                                        borderRadius: BorderRadius.circular(4),
                                                        border: Border.all(
                                                          color: isDark ? Colors.amber.shade700 : Colors.amber.shade600,
                                                          width: 0.5,
                                                        ),
                                                      ),
                                                      child: Text(
                                                        matchBadgeText,
                                                        style: TextStyle(
                                                          fontWeight: FontWeight.w600,
                                                          fontSize: 10,
                                                          color: isDark ? Colors.amber.shade200 : Colors.amber.shade900,
                                                        ),
                                                      ),
                                                    ),
                                                ],
                                              ),
                                            ),
                                            InkWell(
                                              onTap: () =>
                                                  _showAddToCollectionDialog(
                                                    hadith,
                                                  ),
                                              child: Padding(
                                                padding: const EdgeInsets.all(
                                                  4,
                                                ),
                                                child: Icon(
                                                  Icons.playlist_add,
                                                  size: 20,
                                                  color: Colors.grey.shade400,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 8),
                                        _buildHighlightedText(
                                          primaryText,
                                          query,
                                          primaryStyle,
                                          isDark,
                                          3,
                                          textDirection: primaryDirection,
                                          isArabic: isPrimaryArabic,
                                        ),
                                        if (secondaryText != null && secondaryText.isNotEmpty) ...[
                                          const SizedBox(height: 6),
                                          Text(
                                            secondaryText,
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                            textDirection: secondaryDirection,
                                            style: secondaryStyle,
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                        ),
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  static bool _hasArabicMatch(String arabicText, String query) {
    if (arabicText.isEmpty || query.isEmpty) return false;
    if (arabicText.contains(query)) return true;
    final cleanQuery = query.replaceAll(RegExp(r'[\u064B-\u065F\u0670\u0640]'), '').trim();
    if (cleanQuery.isEmpty) return false;

    String norm(String s) {
      return s
          .replaceAll(RegExp(r'[\u064B-\u065F\u0670\u0640]'), '')
          .replaceAll(RegExp(r'[أإآٱ]'), 'ا')
          .replaceAll('ة', 'ه')
          .replaceAll('ى', 'ي');
    }

    return norm(arabicText).contains(norm(cleanQuery));
  }

  static bool _hasArabicCharacters(String input) {
    return RegExp(r'[\u0600-\u06FF]').hasMatch(input);
  }

  Widget _buildHighlightedText(
    String text,
    String query,
    TextStyle baseStyle,
    bool isDark,
    int maxLines, {
    TextDirection textDirection = TextDirection.ltr,
    bool isArabic = false,
  }) {
    if (query.isEmpty) {
      return Text(
        text,
        maxLines: maxLines,
        overflow: TextOverflow.ellipsis,
        textDirection: textDirection,
        style: baseStyle,
      );
    }

    final highlightBg = isDark
        ? Colors.amber.shade900.withValues(alpha: 0.6)
        : Colors.yellow.shade200;
    final highlightTextCol = isDark ? Colors.white : Colors.black;

    if (isArabic || _hasArabicCharacters(text)) {
      final spans = _buildArabicHighlightedSpans(
        text,
        query,
        highlightBg,
        highlightTextCol,
      );
      if (spans != null) {
        return RichText(
          textDirection: textDirection,
          maxLines: maxLines,
          overflow: TextOverflow.ellipsis,
          text: TextSpan(style: baseStyle, children: spans),
        );
      }
    }

    final lowerText = text.toLowerCase();
    final lowerQuery = query.toLowerCase();
    final spans = <TextSpan>[];
    int start = 0;

    while (start < text.length) {
      final idx = lowerText.indexOf(lowerQuery, start);
      if (idx == -1) {
        spans.add(TextSpan(text: text.substring(start)));
        break;
      }

      if (idx > start) {
        spans.add(TextSpan(text: text.substring(start, idx)));
      }

      spans.add(
        TextSpan(
          text: text.substring(idx, idx + query.length),
          style: TextStyle(
            backgroundColor: highlightBg,
            fontWeight: FontWeight.bold,
            color: highlightTextCol,
          ),
        ),
      );

      start = idx + query.length;
    }

    return RichText(
      textDirection: textDirection,
      maxLines: maxLines,
      overflow: TextOverflow.ellipsis,
      text: TextSpan(style: baseStyle, children: spans),
    );
  }

  List<TextSpan>? _buildArabicHighlightedSpans(
    String text,
    String query,
    Color highlightColor,
    Color textColor,
  ) {
    try {
      final List<int> origIndices = [];
      final StringBuffer normBuf = StringBuffer();

      String normChar(String c) {
        if ('أإآٱ'.contains(c)) return 'ا';
        if (c == 'ة') return 'ه';
        if (c == 'ى') return 'ي';
        return c;
      }

      for (int i = 0; i < text.length; i++) {
        final c = text[i];
        if (RegExp(r'[\u064B-\u065F\u0670\u0640]').hasMatch(c)) continue;
        origIndices.add(i);
        normBuf.write(normChar(c));
      }

      final normText = normBuf.toString();
      final cleanQuery = query.replaceAll(RegExp(r'[\u064B-\u065F\u0670\u0640]'), '').trim();
      final normQuery = cleanQuery.split('').map(normChar).join();

      if (normQuery.isEmpty || !normText.contains(normQuery)) {
        return null;
      }

      final spans = <TextSpan>[];
      int startNorm = 0;
      int lastOrigIndex = 0;

      while (startNorm < normText.length) {
        final matchStart = normText.indexOf(normQuery, startNorm);
        if (matchStart == -1) {
          if (lastOrigIndex < text.length) {
            spans.add(TextSpan(text: text.substring(lastOrigIndex)));
          }
          break;
        }

        final matchEnd = matchStart + normQuery.length;
        final startOrig = origIndices[matchStart];
        var endOrig = origIndices[matchEnd - 1] + 1;
        while (endOrig < text.length &&
            RegExp(r'[\u064B-\u065F\u0670\u0640]').hasMatch(text[endOrig])) {
          endOrig++;
        }

        if (startOrig > lastOrigIndex) {
          spans.add(TextSpan(text: text.substring(lastOrigIndex, startOrig)));
        }

        spans.add(
          TextSpan(
            text: text.substring(startOrig, endOrig),
            style: TextStyle(
              backgroundColor: highlightColor,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
        );

        lastOrigIndex = endOrig;
        startNorm = matchEnd;
      }

      return spans.isNotEmpty ? spans : null;
    } catch (_) {
      return null;
    }
  }

  void _showAddToCollectionDialog(Hadith hadith) {
    showModalBottomSheet(
      context: context,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Consumer(
        builder: (context, ref, _) {
          final isDark = Theme.of(context).brightness == Brightness.dark;
          final collectionsAsync = ref.watch(collectionsProvider);

          return Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.playlist_add, color: Theme.of(ctx).primaryColor),
                    const SizedBox(width: 10),
                    Text(
                      'Add to Collection',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        color: isDark ? Colors.white : AppTheme.textDark,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                collectionsAsync.when(
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (e, _) => Text('Error: $e'),
                  data: (collections) {
                    if (collections.isEmpty) {
                      return Text(
                        'No collections yet. Create one from the Collections screen.',
                        style: TextStyle(
                          color: isDark ? Colors.white70 : Colors.black87,
                        ),
                      );
                    }
                    return Column(
                      mainAxisSize: MainAxisSize.min,
                      children: collections
                          .map(
                            (c) => ListTile(
                              leading: Icon(
                                Icons.folder,
                                color: Theme.of(context).primaryColor,
                              ),
                              title: Text(
                                c.name,
                                style: TextStyle(
                                  color: isDark
                                      ? Colors.white
                                      : AppTheme.textDark,
                                ),
                              ),
                              onTap: () async {
                                final repo = ref.read(hadithRepositoryProvider);
                                await repo.addHadithToCollection(
                                  c.id,
                                  hadith.id,
                                );
                                if (ctx.mounted) Navigator.pop(ctx);
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('Added to "${c.name}" ✓'),
                                    ),
                                  );
                                }
                              },
                            ),
                          )
                          .toList(),
                    );
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildLanguageChip(String label, String value, bool isDark) {
    final isSelected = _selectedLanguage == value;
    final primaryColor = _selectedBookId != null
        ? AppTheme.getBookPrimaryColor(_selectedBookId!)
        : Theme.of(context).primaryColor;

    return GestureDetector(
      onTap: () {
        if (_selectedLanguage != value) {
          setState(() => _selectedLanguage = value);
          if (_hasSearched && _controller.text.trim().isNotEmpty) {
            _performSearch();
          }
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: isSelected
              ? primaryColor.withValues(alpha: isDark ? 0.3 : 0.15)
              : (isDark ? Colors.grey.shade800 : Colors.grey.shade100),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? primaryColor
                : (isDark ? Colors.grey.shade700 : Colors.grey.shade300),
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isSelected) ...[
              Icon(Icons.check, size: 13, color: primaryColor),
              const SizedBox(width: 4),
            ],
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected
                    ? (isDark ? Colors.white : primaryColor)
                    : (isDark ? Colors.grey.shade300 : Colors.grey.shade800),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(
    String label,
    bool selected,
    VoidCallback onTap,
    bool isDark,
  ) {
    return GestureDetector(
      onTap: () {
        onTap();
        // FIX: Re-run search when filter changes
        if (_hasSearched && _controller.text.isNotEmpty) {
          WidgetsBinding.instance.addPostFrameCallback((_) => _performSearch());
        }
      },
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            selected
                ? Icons.radio_button_checked
                : Icons.radio_button_unchecked,
            size: 18,
            color: selected ? Theme.of(context).primaryColor : Colors.grey,
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: isDark ? Colors.grey.shade300 : AppTheme.textDark,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBookChip(String label, int? bookId, bool isDark) {
    final isSelected = _selectedBookId == bookId;
    final color = bookId != null
        ? AppTheme.getBookPrimaryColor(bookId)
        : Theme.of(context).primaryColor;
    return GestureDetector(
      onTap: () {
        setState(() => _selectedBookId = bookId);
        if (_hasSearched && _controller.text.isNotEmpty) {
          _performSearch();
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: isSelected
              ? color
              : (isDark ? Colors.grey.shade800 : Colors.grey.shade100),
          borderRadius: BorderRadius.circular(20),
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
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            color: isSelected
                ? Colors.white
                : (isDark ? Colors.grey.shade300 : Colors.grey.shade800),
          ),
        ),
      ),
    );
  }

  String _getBookShortName(int bookId) {
    switch (bookId) {
      case 1:
        return 'Bukhari';
      case 2:
        return 'Muslim';
      case 3:
        return 'Abu Dawood';
      case 4:
        return 'Tirmidhi';
      case 5:
        return "Nasa'i";
      case 6:
        return 'Ibn Majah';
      default:
        return 'Hadith';
    }
  }
}

