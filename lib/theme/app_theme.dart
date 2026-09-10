import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Colors
  static const Color primaryGreen = Color(0xFF0F9D58);
  static const Color primaryDark = Color(0xFF0A7E47);
  static const Color primaryLight = Color(0xFF14B866);
  static const Color accentGold = Color(0xFFD4A843);
  static const Color backgroundLight = Color(0xFFF4F6F8);
  static const Color backgroundDark = Color(0xFF121212);
  static const Color surfaceDark = Color(0xFF1E1E1E);
  static const Color cardWhite = Colors.white;
  static const Color cardDark = Color(0xFF252525);
  static const Color textDark = Color(0xFF1E1E1E);
  static const Color textLight = Color(0xFF616161);
  static const Color textOnDark = Color(0xFFE0E0E0);

  // Border Radius
  static const double borderRadius = 16.0;

  // Book-specific color themes
  static Color getBookPrimaryColor(int bookId) {
    switch (bookId) {
      case 1: // Sahih al-Bukhari - Emerald Green
        return const Color(0xFF0F9D58);
      case 2: // Sahih Muslim - Royal Navy Blue
        return const Color(0xFF1A237E);
      case 3: // Sunan Abu Dawood - Deep Dark Pine Forest Green
        return const Color(0xFF00382E);
      case 4: // Jami` at-Tirmidhi - Warm Persian Brown / Wine
        return const Color(0xFF5D4037);
      case 5: // Sunan an-Nasa'i - Antique Olive Jade Green
        return const Color(0xFF2E5A44);
      case 6: // Sunan Ibn Majah - Ocean Teal / Turquoise
        return const Color(0xFF008080);
      default:
        return primaryGreen;
    }
  }

  static Color getBookDarkColor(int bookId) {
    switch (bookId) {
      case 1:
        return const Color(0xFF0A7E47);
      case 2:
        return const Color(0xFF0D1642);
      case 3:
        return const Color(0xFF00251E);
      case 4:
        return const Color(0xFF3E2723);
      case 5:
        return const Color(0xFF1B3B2B);
      case 6:
        return const Color(0xFF004D40);
      default:
        return primaryDark;
    }
  }

  static Color getBookLightColor(int bookId) {
    switch (bookId) {
      case 1:
        return const Color(0xFF14B866);
      case 2:
        return const Color(0xFF283593);
      case 3:
        return const Color(0xFF005647);
      case 4:
        return const Color(0xFF795548);
      case 5:
        return const Color(0xFF3F775B);
      case 6:
        return const Color(0xFF00A896);
      default:
        return primaryLight;
    }
  }

  static LinearGradient getBookGradient(int bookId) {
    return LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        getBookDarkColor(bookId),
        getBookPrimaryColor(bookId),
        getBookLightColor(bookId),
      ],
    );
  }

  static Color getPrimaryColor(String colorName) {
    switch (colorName) {
      case 'Blue':
        return Colors.blue;
      case 'Purple':
        return Colors.deepPurple;
      case 'Orange':
        return Colors.deepOrange;
      case 'Dark Brown':
        return const Color(0xFF5D4037);
      case 'Dark Blue':
        return const Color(0xFF1A237E);
      case 'Green':
      default:
        return primaryGreen;
    }
  }

  static ThemeData lightTheme(Color primaryColor) {
    final baseTextTheme = GoogleFonts.rubikTextTheme();

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryColor,
        primary: primaryColor,
        surface: cardWhite,
      ),
      scaffoldBackgroundColor: backgroundLight,
      appBarTheme: AppBarTheme(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        centerTitle: true,
        elevation: 0,
        scrolledUnderElevation: 2,
        systemOverlayStyle: const SystemUiOverlayStyle(
          statusBarIconBrightness: Brightness.light,
          statusBarBrightness: Brightness.dark,
          systemNavigationBarIconBrightness: Brightness.dark,
        ),
      ),
      cardTheme: CardThemeData(
        color: cardWhite,
        elevation: 2,
        shadowColor: Colors.black.withValues(alpha: 0.08),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(borderRadius),
        ),
      ),
      textTheme: baseTextTheme.copyWith(
        titleLarge: baseTextTheme.titleLarge?.copyWith(
          color: textDark,
          fontWeight: FontWeight.bold,
        ),
        bodyLarge: baseTextTheme.bodyLarge?.copyWith(color: textDark),
        bodyMedium: baseTextTheme.bodyMedium?.copyWith(color: textLight),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(borderRadius),
          ),
          elevation: 2,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: cardWhite,
        foregroundColor: primaryColor,
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(30),
          side: BorderSide(color: primaryColor, width: 2),
        ),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return primaryColor;
          return Colors.grey;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return primaryColor.withValues(alpha: 0.4);
          }
          return Colors.grey.withValues(alpha: 0.3);
        }),
      ),
      sliderTheme: SliderThemeData(
        activeTrackColor: primaryColor,
        thumbColor: primaryColor,
        inactiveTrackColor: const Color(0xFFE0E0E0),
      ),
      dialogTheme: DialogThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: const Color(0xFF323232),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
      ),
    );
  }

  static ThemeData darkTheme(Color primaryColor) {
    final baseTextTheme = GoogleFonts.rubikTextTheme(
      ThemeData.dark().textTheme,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryColor,
        brightness: Brightness.dark,
        primary: primaryColor,
        surface: surfaceDark,
      ),
      scaffoldBackgroundColor: backgroundDark,
      appBarTheme: const AppBarTheme(
        backgroundColor: surfaceDark,
        foregroundColor: Colors.white,
        centerTitle: true,
        elevation: 0,
        scrolledUnderElevation: 2,
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarIconBrightness: Brightness.light,
          statusBarBrightness: Brightness.dark,
          systemNavigationBarIconBrightness: Brightness.light,
        ),
      ),
      cardTheme: CardThemeData(
        color: cardDark,
        elevation: 1,
        shadowColor: Colors.black.withValues(alpha: 0.3),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(borderRadius),
        ),
      ),
      textTheme: baseTextTheme.copyWith(
        titleLarge: baseTextTheme.titleLarge?.copyWith(
          color: textOnDark,
          fontWeight: FontWeight.bold,
        ),
        bodyLarge: baseTextTheme.bodyLarge?.copyWith(color: textOnDark),
        bodyMedium: baseTextTheme.bodyMedium?.copyWith(
          color: Colors.grey.shade400,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryGreen,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(borderRadius),
          ),
          elevation: 2,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: cardDark,
        foregroundColor: primaryLight,
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(30),
          side: const BorderSide(color: primaryLight, width: 2),
        ),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return primaryLight;
          return Colors.grey;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return primaryLight.withValues(alpha: 0.4);
          }
          return Colors.grey.withValues(alpha: 0.3);
        }),
      ),
      sliderTheme: const SliderThemeData(
        activeTrackColor: primaryLight,
        thumbColor: primaryLight,
        inactiveTrackColor: Color(0xFF424242),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: cardDark,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: const Color(0xFF424242),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: cardDark,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
      ),
    );
  }

  static TextStyle get arabicText {
    return GoogleFonts.amiri(
      fontSize: 24,
      height: 1.8,
      fontWeight: FontWeight.w400,
    );
  }

  static TextStyle get urduText {
    return GoogleFonts.notoNastaliqUrdu(
      fontSize: 20,
      height: 2.0,
      fontWeight: FontWeight.w400,
    );
  }

  static Color? getFontColor(String colorName, bool isDark) {
    switch (colorName) {
      case 'Black':
        return isDark ? Colors.white : Colors.black;
      case 'Dark Brown':
        return isDark ? const Color(0xFFFFCCBC) : const Color(0xFF5D4037);
      case 'Dark Blue':
        return isDark ? const Color(0xFFBBDEFB) : const Color(0xFF1A237E);
      case 'Dark Green':
        return isDark ? const Color(0xFFC8E6C9) : const Color(0xFF1B5E20);
      default:
        return isDark ? Colors.white : null;
    }
  }

  static TextStyle safeGetFont(
    String fontFamily, {
    double? fontSize,
    double? height,
    Color? color,
    FontWeight? fontWeight,
    double? wordSpacing,
    double? letterSpacing,
  }) {
    String lookupName = fontFamily;
    if (fontFamily == 'AlQalam' || fontFamily == 'PDMS Saleem') {
      lookupName = 'Amiri';
    } else if (fontFamily == 'Muhammadi' || fontFamily == 'NooreHira') {
      lookupName = 'Lateef';
    } else if (fontFamily == 'NooreHuda') {
      lookupName = 'Scheherazade New';
    } else if (fontFamily == 'Nastaleeq') {
      lookupName = 'Noto Nastaliq Urdu';
    } else if (fontFamily == 'Mehr') {
      lookupName = 'Gulzar';
    } else if (fontFamily == 'TypeSetting') {
      lookupName = 'Aref Ruqaa';
    } else if (fontFamily == 'RubikMedium') {
      lookupName = 'Rubik';
      fontWeight = FontWeight.w500;
    } else if (fontFamily == 'OpenSans') {
      lookupName = 'Open Sans';
    } else if (fontFamily == 'Google Sans Regular') {
      lookupName = 'Roboto';
    }

    try {
      return GoogleFonts.getFont(
        lookupName,
        fontSize: fontSize,
        height: height,
        color: color,
        fontWeight: fontWeight,
        wordSpacing: wordSpacing,
        letterSpacing: letterSpacing,
      );
    } catch (e) {
      return TextStyle(
        fontFamily: fontFamily,
        fontSize: fontSize,
        height: height,
        color: color,
        fontWeight: fontWeight,
        wordSpacing: wordSpacing,
        letterSpacing: letterSpacing,
      );
    }
  }
}
