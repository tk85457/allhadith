import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../domain/models/models.dart';
import '../../data/repositories/hadith_repository.dart';

/// Notifier that manages the currently selected book ID and persists it in SharedPreferences.
class SelectedBookNotifier extends StateNotifier<int> {
  SelectedBookNotifier() : super(1) {
    _loadSelectedBook();
  }

  static const String _prefKey = 'selected_book_id';

  Future<void> _loadSelectedBook() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedId = prefs.getInt(_prefKey);
      if (savedId != null && savedId >= 1 && savedId <= 6) {
        state = savedId;
      }
    } catch (_) {}
  }

  Future<void> selectBook(int bookId) async {
    if (bookId < 1 || bookId > 6) return;
    state = bookId;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_prefKey, bookId);
    } catch (_) {}
  }
}

final selectedBookIdProvider = StateNotifierProvider<SelectedBookNotifier, int>((ref) {
  return SelectedBookNotifier();
});

/// Fetches all books from the SQLite database
final allBooksProvider = FutureProvider<List<HadithBook>>((ref) async {
  final repo = ref.watch(hadithRepositoryProvider);
  final books = await repo.getBooks();
  if (books.isNotEmpty) return books;

  // Fallback defaults if DB is still warming up
  return const [
    HadithBook(
      id: 1,
      nameEnglish: 'Sahih al-Bukhari',
      nameUrdu: 'صحیح البخاری',
      nameArabic: 'صحيح البخاري',
      authorEnglish: 'Imam Muhammad al-Bukhari',
      authorUrdu: 'امام محمد بن اسماعیل بخاری',
      hadithCount: 7589,
      chapterCount: 97,
    ),
    HadithBook(
      id: 2,
      nameEnglish: 'Sahih Muslim',
      nameUrdu: 'صحیح مسلم',
      nameArabic: 'صحيح مسلم',
      authorEnglish: 'Imam Muslim ibn al-Hajjaj',
      authorUrdu: 'امام مسلم بن الحجاج',
      hadithCount: 7563,
      chapterCount: 57,
    ),
    HadithBook(
      id: 3,
      nameEnglish: 'Sunan Abu Dawood',
      nameUrdu: 'سنن ابو داؤد',
      nameArabic: 'سنن أبي داود',
      authorEnglish: 'Imam Abu Dawood al-Sijistani',
      authorUrdu: 'امام ابو داؤد سجستانی',
      hadithCount: 5274,
      chapterCount: 43,
    ),
    HadithBook(
      id: 4,
      nameEnglish: 'Jami` at-Tirmidhi',
      nameUrdu: 'جامع ترمذی',
      nameArabic: 'جامع الترمذي',
      authorEnglish: 'Imam Abu `Isa Muhammad at-Tirmidhi',
      authorUrdu: 'امام ابو عیسیٰ محمد ترمذی',
      hadithCount: 3952,
      chapterCount: 49,
    ),
    HadithBook(
      id: 5,
      nameEnglish: "Sunan an-Nasa'i",
      nameUrdu: 'سنن نسائی',
      nameArabic: 'سنن النسائي',
      authorEnglish: 'Imam Ahmad ibn Shu`ayb an-Nasa\'i',
      authorUrdu: 'امام احمد بن شعیب نسائی',
      hadithCount: 5765,
      chapterCount: 51,
    ),
    HadithBook(
      id: 6,
      nameEnglish: 'Sunan Ibn Majah',
      nameUrdu: 'سنن ابن ماجہ',
      nameArabic: 'سنن ابن ماجه',
      authorEnglish: 'Imam Ibn Majah al-Qazwini',
      authorUrdu: 'امام ابن ماجہ قزوینی',
      hadithCount: 4343,
      chapterCount: 38,
    ),
  ];
});

/// Returns the currently active HadithBook object
final currentBookProvider = Provider<HadithBook>((ref) {
  final bookId = ref.watch(selectedBookIdProvider);
  final booksAsync = ref.watch(allBooksProvider);

  return booksAsync.when(
    data: (books) {
      return books.firstWhere(
        (b) => b.id == bookId,
        orElse: () => books.isNotEmpty
            ? books.first
            : const HadithBook(
                id: 1,
                nameEnglish: 'Sahih al-Bukhari',
                nameUrdu: 'صحیح البخاری',
                nameArabic: 'صحيح البخاري',
                authorEnglish: 'Imam Muhammad al-Bukhari',
                authorUrdu: 'امام محمد بن اسماعیل بخاری',
                hadithCount: 7589,
                chapterCount: 97,
              ),
      );
    },
    loading: () => const HadithBook(
      id: 1,
      nameEnglish: 'Sahih al-Bukhari',
      nameUrdu: 'صحیح البخاری',
      nameArabic: 'صحيح البخاري',
      authorEnglish: 'Imam Muhammad al-Bukhari',
      authorUrdu: 'امام محمد بن اسماعیل بخاری',
      hadithCount: 7589,
      chapterCount: 97,
    ),
    error: (_, _) => const HadithBook(
      id: 1,
      nameEnglish: 'Sahih al-Bukhari',
      nameUrdu: 'صحیح البخاری',
      nameArabic: 'صحيح البخاري',
      authorEnglish: 'Imam Muhammad al-Bukhari',
      authorUrdu: 'امام محمد بن اسماعیل بخاری',
      hadithCount: 7589,
      chapterCount: 97,
    ),
  );
});
