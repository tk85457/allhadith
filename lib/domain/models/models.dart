// ─── Hadith Book ───
class HadithBook {
  final int id;
  final String nameEnglish;
  final String nameUrdu;
  final String nameArabic;
  final String authorEnglish;
  final String authorUrdu;
  final int hadithCount;
  final int chapterCount;

  const HadithBook({
    required this.id,
    required this.nameEnglish,
    required this.nameUrdu,
    required this.nameArabic,
    required this.authorEnglish,
    required this.authorUrdu,
    required this.hadithCount,
    required this.chapterCount,
  });

  String get coverAsset {
    switch (id) {
      case 1:
        return 'assets/images/covers/bukhari_cover.png';
      case 2:
        return 'assets/images/covers/muslim_cover.png';
      case 3:
        return 'assets/images/covers/abudawood_cover.png';
      case 4:
        return 'assets/images/covers/tirmidhi_cover.png';
      case 5:
        return 'assets/images/covers/nasai_cover.png';
      case 6:
        return 'assets/images/covers/ibnmajah_cover.png';
      default:
        return 'assets/images/covers/bukhari_cover.png';
    }
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'name_english': nameEnglish,
    'name_urdu': nameUrdu,
    'name_arabic': nameArabic,
    'author_english': authorEnglish,
    'author_urdu': authorUrdu,
    'hadith_count': hadithCount,
    'chapter_count': chapterCount,
  };

  factory HadithBook.fromMap(Map<String, dynamic> m) => HadithBook(
    id: m['id'] as int,
    nameEnglish: m['name_english'] as String? ?? '',
    nameUrdu: m['name_urdu'] as String? ?? '',
    nameArabic: m['name_arabic'] as String? ?? '',
    authorEnglish: m['author_english'] as String? ?? '',
    authorUrdu: m['author_urdu'] as String? ?? '',
    hadithCount: m['hadith_count'] as int? ?? 0,
    chapterCount: m['chapter_count'] as int? ?? 0,
  );
}

// ─── Chapter (Book / Kitab) ───
class Chapter {
  final int id;
  final int bookId;
  final int bookNumber;
  final String titleArabic;
  final String titleUrdu;
  final String titleEnglish;
  final int hadithCount;

  const Chapter({
    required this.id,
    this.bookId = 1,
    required this.bookNumber,
    required this.titleArabic,
    required this.titleUrdu,
    required this.titleEnglish,
    required this.hadithCount,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'book_id': bookId,
    'book_number': bookNumber,
    'title_arabic': titleArabic,
    'title_urdu': titleUrdu,
    'title_english': titleEnglish,
    'hadith_count': hadithCount,
  };

  factory Chapter.fromMap(Map<String, dynamic> m) => Chapter(
    id: m['id'] as int,
    bookId: (m['book_id'] as int?) ?? 1,
    bookNumber: (m['book_number'] as int?) ?? (m['chapter_number'] as int? ?? 1),
    titleArabic: m['title_arabic'] as String? ?? '',
    titleUrdu: m['title_urdu'] as String? ?? '',
    titleEnglish: m['title_english'] as String? ?? '',
    hadithCount: (m['hadith_count'] as int?) ?? 0,
  );
}

// ─── Hadith ───
class Hadith {
  final int id;
  final int bookId;
  final int chapterId;
  final String hadithNumber;
  final String arabicText;
  final String urduText;
  final String englishText;
  final String? grade;
  final bool isPrimary;
  final int? parentId;

  const Hadith({
    required this.id,
    this.bookId = 1,
    required this.chapterId,
    required this.hadithNumber,
    required this.arabicText,
    required this.urduText,
    required this.englishText,
    this.grade,
    this.isPrimary = true,
    this.parentId,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'book_id': bookId,
    'chapter_id': chapterId,
    'hadith_number': hadithNumber,
    'arabic_text': arabicText,
    'urdu_text': urduText,
    'english_text': englishText,
    'grade': grade,
    'is_primary': isPrimary ? 1 : 0,
    'parent_id': parentId,
  };

  factory Hadith.fromMap(Map<String, dynamic> m) => Hadith(
    id: m['id'] as int,
    bookId: (m['book_id'] as int?) ?? 1,
    chapterId: (m['chapter_id'] as int?) ?? 1,
    hadithNumber: m['hadith_number'].toString(),
    arabicText: m['arabic_text'] as String? ?? '',
    urduText: m['urdu_text'] as String? ?? '',
    englishText: m['english_text'] as String? ?? '',
    grade: m['grade'] as String?,
    isPrimary: (m['is_primary'] as int? ?? 1) == 1,
    parentId: m['parent_id'] as int?,
  );
}

// ─── Bookmark ───
class Bookmark {
  final int id;
  final int bookId;
  final int hadithId;
  final DateTime createdAt;

  const Bookmark({
    required this.id,
    this.bookId = 1,
    required this.hadithId,
    required this.createdAt,
  });

  factory Bookmark.fromMap(Map<String, dynamic> m) => Bookmark(
    id: m['id'] as int,
    bookId: (m['book_id'] as int?) ?? 1,
    hadithId: m['hadith_id'] as int,
    createdAt: DateTime.parse(m['created_at'] as String),
  );
}

// ─── Collection ───
class HadithCollection {
  final int id;
  final String name;
  final DateTime createdAt;

  const HadithCollection({
    required this.id,
    required this.name,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'name': name,
    'created_at': createdAt.toIso8601String(),
  };

  factory HadithCollection.fromMap(Map<String, dynamic> m) => HadithCollection(
    id: m['id'] as int,
    name: m['name'] as String,
    createdAt: DateTime.parse(m['created_at'] as String),
  );
}

// ─── Note ───
class Note {
  final int id;
  final int bookId;
  final int hadithId;
  final String content;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Note({
    required this.id,
    this.bookId = 1,
    required this.hadithId,
    required this.content,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Note.fromMap(Map<String, dynamic> m) => Note(
    id: m['id'] as int,
    bookId: (m['book_id'] as int?) ?? 1,
    hadithId: m['hadith_id'] as int,
    content: m['content'] as String,
    createdAt: DateTime.parse(m['created_at'] as String),
    updatedAt: DateTime.parse(m['updated_at'] as String),
  );
}

// ─── Reading Progress ───
class ReadingProgress {
  final int id;
  final int bookId;
  final int chapterId;
  final int hadithIndex;
  final DateTime lastReadAt;

  const ReadingProgress({
    required this.id,
    this.bookId = 1,
    required this.chapterId,
    required this.hadithIndex,
    required this.lastReadAt,
  });

  factory ReadingProgress.fromMap(Map<String, dynamic> m) => ReadingProgress(
    id: m['id'] as int,
    bookId: (m['book_id'] as int?) ?? 1,
    chapterId: (m['chapter_id'] as int?) ?? 1,
    hadithIndex: (m['hadith_index'] as int?) ?? 0,
    lastReadAt: DateTime.parse(m['last_read_at'] as String),
  );
}
