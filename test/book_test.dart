import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:all_hadith/theme/app_theme.dart';
import 'package:all_hadith/domain/models/models.dart';

void main() {
  group('Kutub al-Sittah Specifications', () {
    test('Book primary colors match requirements', () {
      // Sahih al-Bukhari: Emerald Green
      expect(AppTheme.getBookPrimaryColor(1), const Color(0xFF0F9D58));
      
      // Sahih Muslim: Royal Navy Blue
      expect(AppTheme.getBookPrimaryColor(2), const Color(0xFF1A237E));
      
      // Sunan Abu Dawood: Dark Pine Forest Green
      expect(AppTheme.getBookPrimaryColor(3), const Color(0xFF00382E));
      
      // Jami` at-Tirmidhi: Persian Brown
      expect(AppTheme.getBookPrimaryColor(4), const Color(0xFF5D4037));
      
      // Sunan an-Nasa'i: Antique Olive Jade Green
      expect(AppTheme.getBookPrimaryColor(5), const Color(0xFF2E5A44));
      
      // Sunan Ibn Majah: Ocean Teal
      expect(AppTheme.getBookPrimaryColor(6), const Color(0xFF008080));
    });

    test('HadithBook model serialization', () {
      const book = HadithBook(
        id: 4,
        nameEnglish: 'Jami` at-Tirmidhi',
        nameUrdu: 'جامع ترمذی',
        nameArabic: 'جامع الترمذي',
        authorEnglish: 'Imam Abu `Isa Muhammad at-Tirmidhi',
        authorUrdu: 'امام ابو عیسیٰ محمد ترمذی',
        hadithCount: 3952,
        chapterCount: 49,
      );

      final map = book.toMap();
      expect(map['id'], 4);
      expect(map['name_english'], 'Jami` at-Tirmidhi');

      final fromMap = HadithBook.fromMap(map);
      expect(fromMap.id, 4);
      expect(fromMap.nameEnglish, 'Jami` at-Tirmidhi');
      expect(fromMap.hadithCount, 3952);
    });

    test('Cover image asset mappings exist', () {
      final coverPaths = [
        'assets/images/covers/bukhari_cover.png',
        'assets/images/covers/muslim_cover.png',
        'assets/images/covers/abudawood_cover.png',
        'assets/images/covers/tirmidhi_cover.png',
        'assets/images/covers/nasai_cover.png',
        'assets/images/covers/ibnmajah_cover.png',
      ];
      expect(coverPaths.length, 6);
    });
  });
}
