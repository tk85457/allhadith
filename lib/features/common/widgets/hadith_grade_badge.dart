import "package:flutter/material.dart";
import "../../../domain/models/models.dart";

/// Represents parsed hadith grade information translated into 3 languages:
/// Arabic, Urdu, and English, with accompanying UI color theme and icon.
class HadithGradeInfo {
  final String arabic;
  final String urdu;
  final String english;
  final Color primaryColor;
  final Color lightBgColor;
  final Color darkBgColor;
  final Color darkTextColor;
  final IconData icon;

  const HadithGradeInfo({
    required this.arabic,
    required this.urdu,
    required this.english,
    required this.primaryColor,
    required this.lightBgColor,
    required this.darkBgColor,
    required this.darkTextColor,
    required this.icon,
  });

  /// Resolves the grade for a hadith.
  /// NOTE: Bukhari (bookId 1) and Muslim (bookId 2) are intentionally omitted (returns null),
  /// because all hadiths in Bukhari and Muslim are unanimously authentic (Sahih).
  static HadithGradeInfo? fromHadith(Hadith hadith) {
    if (hadith.bookId == 1 || hadith.bookId == 2) {
      return null;
    }

    String raw = hadith.grade?.trim() ?? "";

    // Fallback: If grade column is empty in Sunan books (e.g. Tirmidhi),
    // detect Imam Tirmidhi hukam from text.
    if (raw.isEmpty || raw == "-") {
      if (hadith.bookId == 4) {
        final ur = hadith.urduText;
        final ar = hadith.arabicText;
        if (ar.contains("حَدِيثٌ حَسَنٌ صَحِيحٌ") ||
            ur.contains("حسن صحیح") ||
            ur.contains("حسن صحيح")) {
          raw = "Hasan Sahih";
        } else if (ar.contains("حَدِيثٌ حَسَنٌ غَرِيبٌ") ||
            ur.contains("حسن غریب") ||
            ur.contains("حسن غريب") ||
            ar.contains("حَدِيثٌ حَسَنٌ") ||
            ur.contains("حدیث حسن")) {
          raw = "Hasan";
        } else if (ar.contains("حَدِيثٌ صَحِيحٌ") ||
            ur.contains("حدیث صحیح") ||
            ur.contains("صحیح")) {
          raw = "Sahih";
        } else if (ar.contains("حَدِيثٌ غَرِيبٌ") ||
            ur.contains("حدیث غریب") ||
            ar.contains("ضَعِيفٌ") ||
            ur.contains("ضعیف") ||
            ur.contains("ضعيف")) {
          raw = "Daif";
        }
      }
    }

    if (raw.isEmpty || raw == "-") {
      return null;
    }

    return fromRaw(raw);
  }

  /// Parses raw grade string into 3 languages (Arabic, Urdu, English).
  static HadithGradeInfo fromRaw(String raw) {
    final clean = raw.trim();
    final lower = clean.toLowerCase();

    // 1. Sahih Agreed Upon (Muttafaq Alayh)
    if (lower.contains("agreed upon") || lower.contains("muttafaq")) {
      return const HadithGradeInfo(
        arabic: "صحيح (متفق عليه)",
        urdu: "صحیح (متفق علیہ)",
        english: "Sahih (Agreed Upon)",
        primaryColor: Color(0xFF1B5E20),
        lightBgColor: Color(0xFFE8F5E9),
        darkBgColor: Color(0xFF1B3820),
        darkTextColor: Color(0xFF81C784),
        icon: Icons.verified_rounded,
      );
    }

    // 2. Hasan Sahih
    if (lower.contains("hasan sahih")) {
      return const HadithGradeInfo(
        arabic: "حسن صحيح",
        urdu: "حسن صحیح",
        english: "Hasan Sahih",
        primaryColor: Color(0xFF00796B),
        lightBgColor: Color(0xFFE0F2F1),
        darkBgColor: Color(0xFF00363A),
        darkTextColor: Color(0xFF4DB6AC),
        icon: Icons.verified_rounded,
      );
    }

    // 3. Sahih variants (Sahih Isnaad, Sahih Maqtu, Sahih Mauquf, Sahih Lighairihi, etc.)
    if (lower.startsWith("sahih") || lower == "sahih hadith") {
      if (lower.contains("isnaad") || lower.contains("sanad")) {
        return const HadithGradeInfo(
          arabic: "صحيح الإسناد",
          urdu: "صحیح الاسناد",
          english: "Sahih Isnaad",
          primaryColor: Color(0xFF2E7D32),
          lightBgColor: Color(0xFFE8F5E9),
          darkBgColor: Color(0xFF1B3820),
          darkTextColor: Color(0xFF81C784),
          icon: Icons.verified_rounded,
        );
      }
      if (lower.contains("lighairihi")) {
        return const HadithGradeInfo(
          arabic: "صحيح لغيره",
          urdu: "صحیح لغیرہ",
          english: "Sahih Li-ghairihi",
          primaryColor: Color(0xFF2E7D32),
          lightBgColor: Color(0xFFE8F5E9),
          darkBgColor: Color(0xFF1B3820),
          darkTextColor: Color(0xFF81C784),
          icon: Icons.verified_rounded,
        );
      }
      if (lower.contains("maqtu")) {
        return const HadithGradeInfo(
          arabic: "صحيح مقطوع",
          urdu: "صحیح مقطوع",
          english: "Sahih Maqtu'",
          primaryColor: Color(0xFF2E7D32),
          lightBgColor: Color(0xFFE8F5E9),
          darkBgColor: Color(0xFF1B3820),
          darkTextColor: Color(0xFF81C784),
          icon: Icons.verified_rounded,
        );
      }
      if (lower.contains("muquf") || lower.contains("mauquf")) {
        return const HadithGradeInfo(
          arabic: "صحيح موقوف",
          urdu: "صحیح موقوف",
          english: "Sahih Mauquf",
          primaryColor: Color(0xFF2E7D32),
          lightBgColor: Color(0xFFE8F5E9),
          darkBgColor: Color(0xFF1B3820),
          darkTextColor: Color(0xFF81C784),
          icon: Icons.verified_rounded,
        );
      }
      if (lower.contains("mutawatir")) {
        return const HadithGradeInfo(
          arabic: "صحيح متواتر",
          urdu: "صحیح متواتر",
          english: "Sahih Mutawatir",
          primaryColor: Color(0xFF1B5E20),
          lightBgColor: Color(0xFFE8F5E9),
          darkBgColor: Color(0xFF1B3820),
          darkTextColor: Color(0xFF81C784),
          icon: Icons.verified_rounded,
        );
      }
      return const HadithGradeInfo(
        arabic: "صحيح",
        urdu: "صحیح",
        english: "Sahih",
        primaryColor: Color(0xFF2E7D32),
        lightBgColor: Color(0xFFE8F5E9),
        darkBgColor: Color(0xFF1B3820),
        darkTextColor: Color(0xFF81C784),
        icon: Icons.verified_rounded,
      );
    }

    // 4. Hasan variants
    if (lower.startsWith("hasan")) {
      if (lower.contains("isnaad")) {
        return const HadithGradeInfo(
          arabic: "حسن الإسناد",
          urdu: "حسن الاسناد",
          english: "Hasan Isnaad",
          primaryColor: Color(0xFF0277BD),
          lightBgColor: Color(0xFFE1F5FE),
          darkBgColor: Color(0xFF013654),
          darkTextColor: Color(0xFF4FC3F7),
          icon: Icons.thumb_up_rounded,
        );
      }
      if (lower.contains("lighairihi")) {
        return const HadithGradeInfo(
          arabic: "حسن لغيره",
          urdu: "حسن لغیرہ",
          english: "Hasan Li-ghairihi",
          primaryColor: Color(0xFF0277BD),
          lightBgColor: Color(0xFFE1F5FE),
          darkBgColor: Color(0xFF013654),
          darkTextColor: Color(0xFF4FC3F7),
          icon: Icons.thumb_up_rounded,
        );
      }
      return const HadithGradeInfo(
        arabic: "حسن",
        urdu: "حسن",
        english: "Hasan",
        primaryColor: Color(0xFF0277BD),
        lightBgColor: Color(0xFFE1F5FE),
        darkBgColor: Color(0xFF013654),
        darkTextColor: Color(0xFF4FC3F7),
        icon: Icons.thumb_up_rounded,
      );
    }

    // 5. Very Daif
    if (lower.contains("very daif") || lower.contains("very da'if")) {
      return const HadithGradeInfo(
        arabic: "ضعيف جداً",
        urdu: "سخت ضعیف",
        english: "Very Da'if",
        primaryColor: Color(0xFFD32F2F),
        lightBgColor: Color(0xFFFFEBEE),
        darkBgColor: Color(0xFF3E1717),
        darkTextColor: Color(0xFFEF9A9A),
        icon: Icons.error_outline_rounded,
      );
    }

    // 6. Mawdu / Batil (Fabricated / Invalid)
    if (lower.contains("mawdu") || lower.contains("fabricated")) {
      return const HadithGradeInfo(
        arabic: "موضوع",
        urdu: "موضوع (من گھڑت)",
        english: "Mawdu' (Fabricated)",
        primaryColor: Color(0xFFC62828),
        lightBgColor: Color(0xFFFFEBEE),
        darkBgColor: Color(0xFF3E1717),
        darkTextColor: Color(0xFFEF9A9A),
        icon: Icons.cancel_outlined,
      );
    }
    if (lower.contains("batil")) {
      return const HadithGradeInfo(
        arabic: "باطل",
        urdu: "باطل",
        english: "Batil",
        primaryColor: Color(0xFFC62828),
        lightBgColor: Color(0xFFFFEBEE),
        darkBgColor: Color(0xFF3E1717),
        darkTextColor: Color(0xFFEF9A9A),
        icon: Icons.cancel_outlined,
      );
    }

    // 7. Munkar / Shadh
    if (lower.contains("munkar")) {
      return const HadithGradeInfo(
        arabic: "منكر",
        urdu: "منکر",
        english: "Munkar",
        primaryColor: Color(0xFFE65100),
        lightBgColor: Color(0xFFFFF3E0),
        darkBgColor: Color(0xFF3E2714),
        darkTextColor: Color(0xFFFFB74D),
        icon: Icons.warning_amber_rounded,
      );
    }
    if (lower.contains("shadh")) {
      return const HadithGradeInfo(
        arabic: "شاذ",
        urdu: "شاذ",
        english: "Shadh",
        primaryColor: Color(0xFFE65100),
        lightBgColor: Color(0xFFFFF3E0),
        darkBgColor: Color(0xFF3E2714),
        darkTextColor: Color(0xFFFFB74D),
        icon: Icons.warning_amber_rounded,
      );
    }

    // 8. Daif variants (Daif Isnaad, Daif Maqtu, Sanad Daif, Daif)
    if (lower.contains("daif") || lower.contains("da'if") || lower.contains("sanad daif")) {
      if (lower.contains("isnaad") || lower.contains("sanad")) {
        return const HadithGradeInfo(
          arabic: "ضعيف الإسناد",
          urdu: "ضعیف الاسناد",
          english: "Da'if Isnaad",
          primaryColor: Color(0xFFEF6C00),
          lightBgColor: Color(0xFFFFF3E0),
          darkBgColor: Color(0xFF3E2714),
          darkTextColor: Color(0xFFFFB74D),
          icon: Icons.warning_amber_rounded,
        );
      }
      return const HadithGradeInfo(
        arabic: "ضعيف",
        urdu: "ضعیف",
        english: "Da'if",
        primaryColor: Color(0xFFEF6C00),
        lightBgColor: Color(0xFFFFF3E0),
        darkBgColor: Color(0xFF3E2714),
        darkTextColor: Color(0xFFFFB74D),
        icon: Icons.warning_amber_rounded,
      );
    }

    // Default fallback: display cleaned raw string across languages
    return HadithGradeInfo(
      arabic: clean,
      urdu: clean,
      english: clean,
      primaryColor: const Color(0xFF6A1B9A),
      lightBgColor: const Color(0xFFF3E5F5),
      darkBgColor: const Color(0xFF2A1538),
      darkTextColor: const Color(0xFFCE93D8),
      icon: Icons.info_outline_rounded,
    );
  }
}

/// A prominent badge displaying the hadith grade across Arabic, Urdu, and English.
/// Hides itself automatically for Sahih Bukhari and Sahih Muslim.
class HadithGradeBadge extends StatelessWidget {
  final Hadith hadith;
  final bool isProminent;

  const HadithGradeBadge({
    super.key,
    required this.hadith,
    this.isProminent = false,
  });

  @override
  Widget build(BuildContext context) {
    // Hide for Sahih Bukhari (1) and Sahih Muslim (2)
    if (hadith.bookId == 1 || hadith.bookId == 2) {
      return const SizedBox.shrink();
    }

    final info = HadithGradeInfo.fromHadith(hadith);
    if (info == null) {
      return const SizedBox.shrink();
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isProminent ? 10 : 7,
        vertical: isProminent ? 4 : 2.5,
      ),
      decoration: BoxDecoration(
        color: isDark ? info.darkBgColor : info.lightBgColor,
        borderRadius: BorderRadius.circular(isProminent ? 8 : 6),
        border: Border.all(
          color: info.primaryColor.withValues(alpha: isDark ? 0.6 : 0.4),
          width: 0.9,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(
            info.icon,
            size: isProminent ? 13 : 11,
            color: isDark ? info.darkTextColor : info.primaryColor,
          ),
          const SizedBox(width: 4),
          Text(
            "${info.arabic} • ${info.urdu} • ${info.english}",
            textDirection: TextDirection.rtl,
            style: TextStyle(
              fontSize: isProminent ? 12 : 10.5,
              fontWeight: FontWeight.bold,
              color: isDark ? info.darkTextColor : info.primaryColor,
              letterSpacing: 0.1,
            ),
          ),
        ],
      ),
    );
  }
}
