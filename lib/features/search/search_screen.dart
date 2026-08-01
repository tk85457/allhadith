import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../theme/app_theme.dart';
import '../../data/repositories/hadith_repository.dart';
import '../../domain/models/models.dart';
import '../settings/settings_provider.dart';
import '../collections/collections_screen.dart';
import '../../widgets/banner_ad_widget.dart';

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final _controller = TextEditingController();

  // FIX: This filter now actually affects the search query
  String _selectedLanguage = 'Urdu Translation';

  // FIX: This filter now actually applies the isPrimary filter
  bool _onlyPrimaryHadiths = true;
  bool _partialMatch = true;

  List<Hadith> _results = [];
  bool _isLoading = false;
  bool _hasSearched = false;
  bool _hasMore = false;
  int _currentPage = 0;
  static const int _pageSize = 30;

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
      final single = await repo.getHadithByGlobalNumber(query);
      newHadiths = single != null ? [single] : [];
    } else {
      newHadiths = await repo.searchHadiths(
        query,
        language: _selectedLanguage,
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
      bottomNavigationBar: const BannerAdWidget(),
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
                      Expanded(
                        child: TextField(
                          controller: _controller,
                          textAlign: TextAlign.right,
                          textDirection: TextDirection.rtl,
                          onSubmitted: (_) => _performSearch(),
                          decoration: InputDecoration(
                            hintText: 'مطلوب الفاظ یہاں ٹائپ کریں',
                            hintStyle: TextStyle(
                              color: isDark
                                  ? Colors.grey.shade500
                                  : Colors.grey.shade400,
                            ),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                          ),
                        ),
                      ),
                      IconButton(
                        icon: Icon(
                          Icons.search,
                          color: Theme.of(context).primaryColor,
                        ),
                        onPressed: _performSearch,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // FIX: Language Filter — now changes the actual search language
                // Urdu = only Urdu text search, English = only English, Topic = all
                Row(
                  children: [
                    _buildRadio('Urdu Translation', isDark),
                    _buildRadio('Topic', isDark),
                    _buildRadio('English', isDark),
                  ],
                ).animate().fadeIn(delay: 100.ms),
                const SizedBox(height: 4),

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
                            final query = _controller.text;
                            return Container(
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
                                    final hIndex = await repo.getHadithIndex(
                                      hadith.chapterId,
                                      hadith.hadithNumber,
                                    );
                                    if (context.mounted) {
                                      context.go(
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
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 6,
                                                    vertical: 2,
                                                  ),
                                              decoration: BoxDecoration(
                                                color: Theme.of(context)
                                                    .primaryColor
                                                    .withValues(alpha: 0.1),
                                                borderRadius:
                                                    BorderRadius.circular(4),
                                              ),
                                              child: Text(
                                                'Hadith #${hadith.hadithNumber} — Ch. ${hadith.chapterId}',
                                                style: TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 12,
                                                  color: Theme.of(
                                                    context,
                                                  ).primaryColor,
                                                ),
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
                                        const SizedBox(height: 6),
                                        _buildHighlightedText(
                                          // FIX: Show preview based on selected language
                                          _selectedLanguage == 'English'
                                              ? hadith.englishText
                                              : _selectedLanguage ==
                                                    'Urdu Translation'
                                              ? hadith.urduText
                                              : hadith.englishText,
                                          query,
                                          AppTheme.safeGetFont(
                                            settings.englishFontFamily,
                                            color:
                                                AppTheme.getFontColor(
                                                  settings.englishFontColor,
                                                  isDark,
                                                ) ??
                                                (isDark
                                                    ? Colors.grey.shade300
                                                    : Colors.grey.shade700),
                                            fontSize: 13,
                                          ),
                                          isDark,
                                          3,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ).animate().fadeIn(delay: (50 * index).ms);
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

  Widget _buildHighlightedText(
    String text,
    String query,
    TextStyle baseStyle,
    bool isDark,
    int maxLines,
  ) {
    if (query.isEmpty) {
      return Text(
        text,
        maxLines: maxLines,
        overflow: TextOverflow.ellipsis,
        style: baseStyle,
      );
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
            backgroundColor: isDark
                ? Colors.amber.shade900.withValues(alpha: 0.6)
                : Colors.yellow.shade200,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : Colors.black,
          ),
        ),
      );

      start = idx + query.length;
    }

    return RichText(
      maxLines: maxLines,
      overflow: TextOverflow.ellipsis,
      text: TextSpan(style: baseStyle, children: spans),
    );
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

  Widget _buildRadio(String value, bool isDark) {
    final isSelected = _selectedLanguage == value;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() => _selectedLanguage = value);
          // FIX: Re-run search when language changes if a search was already performed
          if (_hasSearched && _controller.text.isNotEmpty) {
            _performSearch();
          }
        },
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isSelected
                  ? Icons.radio_button_checked
                  : Icons.radio_button_unchecked,
              size: 18,
              color: isSelected ? Theme.of(context).primaryColor : Colors.grey,
            ),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                value,
                style: TextStyle(
                  fontSize: 12,
                  color: isDark ? Colors.grey.shade300 : AppTheme.textDark,
                ),
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
}
