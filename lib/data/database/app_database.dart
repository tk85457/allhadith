import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/services.dart' show rootBundle;
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

/// Production database with asset-copy-on-first-launch pattern.
/// Data tables (chapters, hadiths) come from the pre-built asset.
/// User tables (bookmarks, collections, notes, reading_progress) are created on open.
class AppDatabase {
  static final AppDatabase instance = AppDatabase._init();
  static Database? _database;
  static const String _dbName = 'all_hadith.db';
  static const int _dbVersion = 8;
  static const Set<String> _requiredTables = {'books', 'chapters', 'hadiths'};

  AppDatabase._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _openDatabase();
    return _database!;
  }

  Future<Database> _openDatabase() async {
    final dbPath = await _getDatabasePath();

    // On web, we build in-memory (asset copy not supported)
    if (kIsWeb) {
      return _openWebDatabase();
    }

    await _ensureNativeDatabaseFile(dbPath);

    return await openDatabase(
      dbPath,
      version: _dbVersion,
      onConfigure: _onConfigure,
      onOpen: _onOpen,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onConfigure(Database db) async {
    try {
      await db.execute('PRAGMA journal_mode = WAL');
      await db.execute('PRAGMA synchronous = NORMAL');
      await db.execute('PRAGMA cache_size = -2000'); // 2MB cache, ideal for low RAM phones
      await db.execute('PRAGMA temp_store = MEMORY');
      await db.execute('PRAGMA foreign_keys = ON');
    } catch (_) {}
  }

  Future<String> _getDatabasePath() async {
    if (kIsWeb) return _dbName;
    final dir = await getApplicationDocumentsDirectory();
    final dbDir = Directory(join(dir.path, 'databases'));
    if (!await dbDir.exists()) await dbDir.create(recursive: true);
    return join(dbDir.path, _dbName);
  }

  /// Copy the pre-built database from assets to the app directory.
  Future<void> _copyFromAssets(String targetPath) async {
    final data = await rootBundle.load('assets/db/$_dbName');
    final bytes = data.buffer.asUint8List(
      data.offsetInBytes,
      data.lengthInBytes,
    );
    if (bytes.isEmpty) {
      throw StateError('Bundled database asset assets/db/$_dbName is empty.');
    }
    await File(targetPath).writeAsBytes(bytes, flush: true);
  }

  Future<void> _ensureNativeDatabaseFile(String dbPath) async {
    final dbFile = File(dbPath);
    final exists = await dbFile.exists();

    // Fast path for low-end phones: If DB exists and has substantial data (>5MB),
    // skip the expensive probe connection and sqlite_master queries completely.
    if (exists) {
      final length = await dbFile.length();
      if (length > 5000000) {
        return;
      }
      debugPrintError(
        'Database file is suspiciously small ($length bytes). Resetting local copy.',
      );
      await dbFile.delete();
    }

    await _copyFromAssets(dbPath);

    final copiedHasSchema =
        await dbFile.exists() &&
        await dbFile.length() > 0 &&
        await _hasRequiredTables(dbPath);
    if (!copiedHasSchema) {
      throw StateError('Failed to initialize the bundled database at $dbPath.');
    }
  }

  Future<bool> _hasRequiredTables(String dbPath) async {
    Database? probeDb;
    try {
      probeDb = await openDatabase(
        dbPath,
        readOnly: true,
        singleInstance: false,
      );
      final rows = await probeDb.rawQuery(
        "SELECT name FROM sqlite_master WHERE type = 'table' AND name IN ('books', 'chapters', 'hadiths')",
      );
      final tableNames = rows
          .map((row) => row['name'])
          .whereType<String>()
          .toSet();
      return _requiredTables.every(tableNames.contains);
    } catch (e) {
      debugPrintError('Failed to validate database schema: $e');
      return false;
    } finally {
      await probeDb?.close();
    }
  }

  /// Web full database initialization
  Future<Database> _openWebDatabase() async {
    // We use a versioned name on web to force a clean IndexedDB copy
    const webDbName = 'all_hadith_web_v1.db';

    // Check if DB already exists in IndexedDB
    bool exists = await databaseFactory.databaseExists(webDbName);

    if (!exists) {
      debugPrintError(
        'Web database not found. Copying from assets... This may take a moment.',
      );
      try {
        final data = await rootBundle.load('assets/db/$_dbName');
        final bytes = data.buffer.asUint8List(
          data.offsetInBytes,
          data.lengthInBytes,
        );
        await databaseFactory.writeDatabaseBytes(webDbName, bytes);
        debugPrintError('Web database successfully copied from assets.');
      } catch (e) {
        debugPrintError('Failed to copy Web DB from assets: $e');
        // Fallback to empty creation
        return await openDatabase(
          webDbName,
          version: _dbVersion,
          onCreate: _createWebFallback,
          onOpen: _onOpen,
          onUpgrade: _onUpgrade,
        );
      }
    }

    return await openDatabase(
      webDbName,
      version: _dbVersion,
      onOpen: _onOpen,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _createWebFallback(Database db, int version) async {
    await _createDataTables(db);
    await _createUserTables(db);
    await _createIndexes(db);
  }

  /// Returns true if the core data table (hadiths) exists.
  Future<bool> _dataTablesExist(Database db) async {
    final result = await db.rawQuery(
      "SELECT name FROM sqlite_master WHERE type='table' AND name='hadiths'",
    );
    return result.isNotEmpty;
  }

  /// Create user-data tables (these are added on top of the pre-built asset DB)
  Future<void> _onOpen(Database db) async {
    // Fast path: Only create user tables and indexes if they do not exist yet.
    // Skips 13 redundant DDL statements on every app launch.
    final userTableCheck = await db.rawQuery(
      "SELECT name FROM sqlite_master WHERE type='table' AND name='bookmarks'",
    );
    if (userTableCheck.isEmpty) {
      final tablesExist = await _dataTablesExist(db);
      if (!tablesExist) {
        debugPrintError(
          'Data tables not found (asset copy may have failed). '
          'Creating schema from scratch.',
        );
        await _createDataTables(db);
      }
      await _createUserTables(db);
      await _createIndexes(db);
    }
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 5) {
      await _createUserTables(db);
      await _createIndexes(db);
    }
    if (oldVersion < 6) {
      // Add grouping columns for Hadith primary/secondary classification
      try {
        await db.execute(
          'ALTER TABLE hadiths ADD COLUMN is_primary INTEGER DEFAULT 1',
        );
      } catch (_) {} // Column may already exist
      try {
        await db.execute('ALTER TABLE hadiths ADD COLUMN parent_id INTEGER');
      } catch (_) {} // Column may already exist
    }
    if (oldVersion < 8) {
      // Populate Tirmidhi grades for existing databases where grade is empty
      try {
        await db.execute('''
UPDATE hadiths SET grade = 'Hasan Sahih'
WHERE book_id = 4 AND (grade IS NULL OR trim(grade) = '')
AND (arabic_text LIKE '%حَدِيثٌ حَسَنٌ صَحِيحٌ%' OR urdu_text LIKE '%حسن صحیح%' OR urdu_text LIKE '%حسن صحيح%');
        ''');
        await db.execute('''
UPDATE hadiths SET grade = 'Hasan'
WHERE book_id = 4 AND (grade IS NULL OR trim(grade) = '')
AND (arabic_text LIKE '%حَدِيثٌ حَسَنٌ%' OR urdu_text LIKE '%حدیث حسن%' OR urdu_text LIKE '%حدیث حسن غریب%' OR arabic_text LIKE '%حَدِيثٌ حَسَنٌ غَرِيبٌ%');
        ''');
        await db.execute('''
UPDATE hadiths SET grade = 'Sahih'
WHERE book_id = 4 AND (grade IS NULL OR trim(grade) = '')
AND (arabic_text LIKE '%حَدِيثٌ صَحِيحٌ%' OR urdu_text LIKE '%حدیث صحیح%' OR urdu_text LIKE '%صحیح%');
        ''');
        await db.execute('''
UPDATE hadiths SET grade = 'Daif'
WHERE book_id = 4 AND (grade IS NULL OR trim(grade) = '')
AND (arabic_text LIKE '%حَدِيثٌ غَرِيبٌ%' OR urdu_text LIKE '%حدیث غریب%' OR arabic_text LIKE '%ضَعِيفٌ%' OR urdu_text LIKE '%ضعیف%');
        ''');
      } catch (_) {}
    }
  }

  Future<void> _createDataTables(Database db) async {
    await db.execute('''
CREATE TABLE IF NOT EXISTS books (
  id INTEGER PRIMARY KEY,
  name_english TEXT NOT NULL,
  name_urdu TEXT NOT NULL,
  name_arabic TEXT NOT NULL,
  author_english TEXT NOT NULL,
  author_urdu TEXT NOT NULL,
  hadith_count INTEGER NOT NULL DEFAULT 0,
  chapter_count INTEGER NOT NULL DEFAULT 0
)''');

    await db.execute('''
CREATE TABLE IF NOT EXISTS chapters (
  id INTEGER PRIMARY KEY,
  book_id INTEGER NOT NULL DEFAULT 1,
  chapter_number INTEGER NOT NULL,
  title_arabic TEXT NOT NULL,
  title_urdu TEXT NOT NULL,
  title_english TEXT NOT NULL,
  hadith_count INTEGER NOT NULL DEFAULT 0,
  FOREIGN KEY (book_id) REFERENCES books (id)
)''');

    await db.execute('''
CREATE TABLE IF NOT EXISTS hadiths (
  id INTEGER PRIMARY KEY,
  book_id INTEGER NOT NULL DEFAULT 1,
  chapter_id INTEGER NOT NULL,
  hadith_number TEXT NOT NULL,
  arabic_text TEXT NOT NULL,
  urdu_text TEXT NOT NULL,
  english_text TEXT NOT NULL,
  grade TEXT,
  is_primary INTEGER DEFAULT 1,
  parent_id INTEGER,
  FOREIGN KEY (book_id) REFERENCES books (id),
  FOREIGN KEY (chapter_id) REFERENCES chapters (id)
)''');
  }

  Future<void> _createUserTables(Database db) async {
    await db.execute('''
CREATE TABLE IF NOT EXISTS bookmarks (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  book_id INTEGER NOT NULL DEFAULT 1,
  hadith_id INTEGER NOT NULL,
  created_at TEXT NOT NULL,
  FOREIGN KEY (hadith_id) REFERENCES hadiths (id)
)''');

    await db.execute('''
CREATE TABLE IF NOT EXISTS collections (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  name TEXT NOT NULL,
  created_at TEXT NOT NULL
)''');

    await db.execute('''
CREATE TABLE IF NOT EXISTS collection_hadith (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  collection_id INTEGER NOT NULL,
  hadith_id INTEGER NOT NULL,
  FOREIGN KEY (collection_id) REFERENCES collections (id),
  FOREIGN KEY (hadith_id) REFERENCES hadiths (id),
  UNIQUE(collection_id, hadith_id)
)''');

    await db.execute('''
CREATE TABLE IF NOT EXISTS notes (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  book_id INTEGER NOT NULL DEFAULT 1,
  hadith_id INTEGER NOT NULL,
  content TEXT NOT NULL,
  created_at TEXT NOT NULL,
  updated_at TEXT NOT NULL,
  FOREIGN KEY (hadith_id) REFERENCES hadiths (id)
)''');

    await db.execute('''
CREATE TABLE IF NOT EXISTS reading_progress (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  book_id INTEGER NOT NULL DEFAULT 1,
  chapter_id INTEGER NOT NULL,
  hadith_index INTEGER NOT NULL DEFAULT 0,
  last_read_at TEXT NOT NULL,
  FOREIGN KEY (chapter_id) REFERENCES chapters (id)
)''');
  }

  Future<void> _createIndexes(Database db) async {
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_chapters_book ON chapters(book_id)',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_hadiths_book ON hadiths(book_id)',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_hadiths_chapter ON hadiths(chapter_id)',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_hadiths_number ON hadiths(hadith_number)',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_bookmarks_hadith ON bookmarks(hadith_id)',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_notes_hadith ON notes(hadith_id)',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_progress_chapter ON reading_progress(chapter_id)',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_collection_hadith ON collection_hadith(collection_id)',
    );
  }

  /// Delete corrupted DB and re-copy from assets
  Future<void> resetDatabase() async {
    if (kIsWeb) return;
    final path = await _getDatabasePath();
    _database?.close();
    _database = null;
    final file = File(path);
    if (await file.exists()) await file.delete();
    _database = await _openDatabase();
  }

  Future<void> close() async {
    final db = await database;
    await db.close();
    _database = null;
  }
}

void debugPrintError(String msg) {
  // ignore: avoid_print
  assert(() {
    print('[AppDatabase] $msg');
    return true;
  }());
}
