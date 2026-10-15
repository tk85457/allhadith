import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../theme/app_theme.dart';
import '../../data/repositories/hadith_repository.dart';
import '../settings/settings_provider.dart';
import '../../domain/models/models.dart';
import '../books/book_provider.dart';
import '../common/widgets/hadith_grade_badge.dart';

final collectionDetailsProvider = FutureProvider.family<HadithCollection?, int>(
  (ref, id) async {
    return ref.watch(hadithRepositoryProvider).getCollectionById(id);
  },
);

final collectionHadithsProvider = FutureProvider.family<List<Hadith>, int>((
  ref,
  id,
) async {
  return ref.watch(hadithRepositoryProvider).getCollectionHadiths(id);
});

class CollectionDetailScreen extends ConsumerWidget {
  final int collectionId;

  const CollectionDetailScreen({super.key, required this.collectionId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final settings = ref.watch(settingsProvider);
    final collectionAsync = ref.watch(collectionDetailsProvider(collectionId));
    final hadithsAsync = ref.watch(collectionHadithsProvider(collectionId));

    return Scaffold(
      appBar: AppBar(
        title: collectionAsync.when(
          data: (c) => Text(c?.name ?? 'Collection'),
          loading: () => const Text('Loading...'),
          error: (_, _) => const Text('Error'),
        ),
      ),
      body: hadithsAsync.when(
        loading: () => Center(
          child: CircularProgressIndicator(
            color: Theme.of(context).primaryColor,
          ),
        ),
        error: (e, st) => Center(child: Text('Error: $e')),
        data: (hadiths) {
          if (hadiths.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.playlist_add_check,
                    size: 64,
                    color: Theme.of(
                      context,
                    ).primaryColor.withValues(alpha: 0.5),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No hadiths in this collection yet.',
                    style: TextStyle(
                      fontSize: 16,
                      color: isDark
                          ? Colors.grey.shade400
                          : Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: hadiths.length,
            itemBuilder: (context, index) {
              final hadith = hadiths[index];
              return InkWell(
                onTap: () async {
                  final repo = ref.read(hadithRepositoryProvider);
                  // Switch active book to match this collection item
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
                          Wrap(
                            spacing: 6,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: AppTheme.getBookPrimaryColor(hadith.bookId).withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(4),
                                  border: Border.all(
                                    color: AppTheme.getBookPrimaryColor(hadith.bookId).withValues(alpha: 0.35),
                                    width: 0.5,
                                  ),
                                ),
                                child: Text(
                                  _getBookName(hadith.bookId),
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 11,
                                    color: AppTheme.getBookPrimaryColor(hadith.bookId),
                                  ),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: Theme.of(
                                    context,
                                  ).primaryColor.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  'Hadith #${hadith.hadithNumber}',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 11,
                                    color: Theme.of(context).primaryColor,
                                  ),
                                ),
                              ),
                              HadithGradeBadge(hadith: hadith),
                            ],
                          ),
                          Icon(
                            Icons.bookmark,
                            color: Theme.of(context).primaryColor,
                            size: 20,
                          ),
                        ],
                      ),
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
                        _getBookName(hadith.bookId),
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey.shade500,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ),
                ),
              ).animate().fadeIn(delay: (60 * index).ms).slideX(begin: 0.05, end: 0);
            },
          );
        },
      ),
    );
  }

  String _getBookName(int bookId) {
    switch (bookId) {
      case 1:
        return 'Sahih al-Bukhari';
      case 2:
        return 'Sahih Muslim';
      case 3:
        return 'Sunan Abu Dawood';
      case 4:
        return 'Jami` at-Tirmidhi';
      case 5:
        return "Sunan an-Nasa'i";
      case 6:
        return 'Sunan Ibn Majah';
      default:
        return 'Hadith';
    }
  }
}

