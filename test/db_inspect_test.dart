import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  test('inspect database chapter and hadith ids', () async {
    sqfliteFfiInit();
    final dbPath = File('assets/db/all_hadith.db').absolute.path;
    final db = await databaseFactoryFfi.openDatabase(dbPath);
    
    final books = await db.rawQuery('SELECT id, name_english FROM books');
    print('BOOKS: $books');

    final chapters = await db.rawQuery('SELECT book_id, MIN(id) as min_id, MAX(id) as max_id, COUNT(*) as count FROM chapters GROUP BY book_id');
    print('CHAPTERS: $chapters');

    final hadiths = await db.rawQuery('SELECT book_id, MIN(id) as min_id, MAX(id) as max_id, MIN(chapter_id) as min_ch, MAX(chapter_id) as max_ch, COUNT(*) as count FROM hadiths GROUP BY book_id');
    print('HADITHS: $hadiths');

    final sampleHadiths = await db.rawQuery('SELECT id, book_id, chapter_id, hadith_number, is_primary FROM hadiths WHERE book_id = 2 LIMIT 5');
    print('SAMPLE BOOK 2: $sampleHadiths');

    final ch98Hadiths = await db.query(
      'hadiths',
      where: 'chapter_id = ? AND is_primary = 1',
      whereArgs: [98],
      orderBy: 'id ASC',
    );
    print('CH 98 hadiths count: ${ch98Hadiths.length}, first hadith_number: ${ch98Hadiths.first['hadith_number']}');

    // Test Urdu search
    final urduRes = await db.rawQuery("SELECT id, hadith_number, urdu_text FROM hadiths WHERE book_id = 1 AND urdu_text LIKE '%نماز%' LIMIT 3");
    print('URDU SEARCH RESULTS: ${urduRes.length}');

    // Test English search
    final engRes = await db.rawQuery("SELECT id, hadith_number, english_text FROM hadiths WHERE book_id = 1 AND english_text LIKE '%prayer%' LIMIT 3");
    print('ENGLISH SEARCH RESULTS: ${engRes.length}');

    print('--- Testing 3-language Hadith Search ---');
    // Urdu search in Book 1 vs Book 2
    final urduBukhari = await db.rawQuery("SELECT id, book_id, hadith_number, urdu_text FROM hadiths WHERE book_id = 1 AND urdu_text LIKE '%نماز%' LIMIT 3");
    print('URDU Bukhari: ${urduBukhari.length} (book_ids: ${urduBukhari.map((e) => e['book_id']).toSet()})');
    assert(urduBukhari.every((e) => e['book_id'] == 1));

    final urduMuslim = await db.rawQuery("SELECT id, book_id, hadith_number, urdu_text FROM hadiths WHERE book_id = 2 AND urdu_text LIKE '%نماز%' LIMIT 3");
    print('URDU Muslim: ${urduMuslim.length} (book_ids: ${urduMuslim.map((e) => e['book_id']).toSet()})');
    assert(urduMuslim.every((e) => e['book_id'] == 2));

    // English search in Book 1 vs Book 2
    final engBukhari = await db.rawQuery("SELECT id, book_id, hadith_number, english_text FROM hadiths WHERE book_id = 1 AND english_text LIKE '%prayer%' LIMIT 3");
    print('ENG Bukhari: ${engBukhari.length} (book_ids: ${engBukhari.map((e) => e['book_id']).toSet()})');
    assert(engBukhari.every((e) => e['book_id'] == 1));

    final engMuslim = await db.rawQuery("SELECT id, book_id, hadith_number, english_text FROM hadiths WHERE book_id = 2 AND english_text LIKE '%prayer%' LIMIT 3");
    print('ENG Muslim: ${engMuslim.length} (book_ids: ${engMuslim.map((e) => e['book_id']).toSet()})');
    assert(engMuslim.every((e) => e['book_id'] == 2));

    // Arabic search using _buildArabicSearchPattern logic
    String buildArPattern(String input) {
      final clean = input.replaceAll(RegExp(r'[\u064B-\u065F\u0670\u0640]'), '').trim();
      final buffer = StringBuffer('%');
      for (int i = 0; i < clean.length; i++) {
        final char = clean[i];
        if (char == ' ') {
          buffer.write('%');
        } else if ('أإآٱا'.contains(char)) {
          buffer.write('_%');
        } else if ('ةه'.contains(char)) {
          buffer.write('_%');
        } else if ('يى'.contains(char)) {
          buffer.write('_%');
        } else {
          buffer.write('$char%');
        }
      }
      return buffer.toString();
    }

    final arPattern = buildArPattern('الاعمال');
    final arBukhari = await db.rawQuery("SELECT id, book_id, hadith_number, arabic_text FROM hadiths WHERE book_id = 1 AND arabic_text LIKE ? LIMIT 3", [arPattern]);
    print('ARABIC Bukhari for الاعمال: ${arBukhari.length} (book_ids: ${arBukhari.map((e) => e['book_id']).toSet()})');
    assert(arBukhari.isNotEmpty);
    assert(arBukhari.every((e) => e['book_id'] == 1));

    final arMuslim = await db.rawQuery("SELECT id, book_id, hadith_number, arabic_text FROM hadiths WHERE book_id = 2 AND arabic_text LIKE ? LIMIT 3", [arPattern]);
    print('ARABIC Muslim for الاعمال: ${arMuslim.length} (book_ids: ${arMuslim.map((e) => e['book_id']).toSet()})');
    assert(arMuslim.isNotEmpty);
    assert(arMuslim.every((e) => e['book_id'] == 2));

    // Test Arabic highlighter mapping
    List<int> origIndices = [];
    StringBuffer normBuf = StringBuffer();
    final sampleArabic = 'إِنَّمَا الْأَعْمَالُ بِالنِّيَّاتِ';
    final sampleQuery = 'الاعمال';

    String normalizeChar(String c) {
      if ('أإآٱ'.contains(c)) return 'ا';
      if (c == 'ة') return 'ه';
      if (c == 'ى') return 'ي';
      return c;
    }

    for (int i = 0; i < sampleArabic.length; i++) {
      final c = sampleArabic[i];
      if (RegExp(r'[\u064B-\u065F\u0670\u0640]').hasMatch(c)) continue;
      origIndices.add(i);
      normBuf.write(normalizeChar(c));
    }
    final normText = normBuf.toString();
    final normQuery = sampleQuery.replaceAll(RegExp(r'[\u064B-\u065F\u0670\u0640]'), '').split('').map(normalizeChar).join();
    
    final matchStart = normText.indexOf(normQuery);
    print('NORM TEXT: $normText, NORM QUERY: $normQuery, MATCH START: $matchStart');
    assert(matchStart != -1);
    
    final matchEnd = matchStart + normQuery.length;
    final startOrig = origIndices[matchStart];
    var endOrig = origIndices[matchEnd - 1] + 1;
    while (endOrig < sampleArabic.length && RegExp(r'[\u064B-\u065F\u0670\u0640]').hasMatch(sampleArabic[endOrig])) {
      endOrig++;
    }
    final matchedSubstring = sampleArabic.substring(startOrig, endOrig);
    print('MATCHED SUBSTRING WITH HARAKAT: "$matchedSubstring"');
    assert(matchedSubstring == 'الْأَعْمَالُ');

    await db.close();
  });
}
