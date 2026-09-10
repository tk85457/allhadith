<div align="center">

# 📖 All Hadith — Kutub al-Sittah (سب احادیث — صحاح ستہ)
### Complete 6 Authentic Canonical Hadith Books in Urdu, Arabic & English — 100% Offline

[![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B?style=for-the-badge&logo=flutter&logoColor=white)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.x-0175C2?style=for-the-badge&logo=dart&logoColor=white)](https://dart.dev)
[![Platform](https://img.shields.io/badge/Platform-Android%20%7C%20iOS-3DDC84?style=for-the-badge&logo=android&logoColor=white)](https://play.google.com/store/apps/details?id=com.allhadith.app)
[![Offline](https://img.shields.io/badge/Offline-100%25%20No%20Internet-0A7E47?style=for-the-badge)](https://play.google.com/store/apps/details?id=com.allhadith.app)
[![License](https://img.shields.io/badge/License-MIT-green.svg?style=for-the-badge)](LICENSE)

[**📱 Get it on Google Play**](https://play.google.com/store/apps/details?id=com.allhadith.app)

</div>

---

## 🌟 About All Hadith (Kutub al-Sittah)

**Kutub al-Sittah (الكتب الستة)** are the six canonical Hadith collections in Sunni Islam:
1. **Sahih Bukhari** (صحيح البخاري) — Imam Al-Bukhari
2. **Sahih Muslim** (صحيح مسلم) — Imam Muslim
3. **Jami' at-Tirmidhi** (جامع الترمذي) — Imam At-Tirmidhi
4. **Sunan Abu Dawood** (سنن أبي داود) — Imam Abu Dawood
5. **Sunan an-Nasa'i** (سنن النسائي) — Imam An-Nasa'i
6. **Sunan Ibn Majah** (سنن ابن ماجه) — Imam Ibn Majah

This modern Flutter application delivers all **97 Books and 7,563 authentic Hadiths** with high-speed instant search, side-by-side Urdu & English translations, Arabic text, and dark mode support.

---

## ✨ Features

- 📜 **Complete Collection**: All 97 Books & 7,563 Authentic Hadiths of Sahih Al-Bukhari.
- 🌐 **Dual Translations**: Clear side-by-side **Urdu** (صحيح البخاري اردو) and **English** translations.
- ⚡ **Instant Smart Search**: Search Hadiths by number, Arabic roots, English keywords, or Urdu words in under 50ms.
- 📡 **100% Offline**: Zero internet required. Database is fully embedded for fast local access.
- 📌 **Bookmarks & Notes**: Organize favorite Hadiths and save personal research notes.
- 🎨 **Islamic Theme**: Customizable typography (Arabic Naskh, Uthmani, Urdu Nastaliq) with Emerald Green & Gold aesthetics.
- 🔔 **Daily Hadith Reminders**: Handpicked daily Hadith notification reminders.

---

## 🏗️ Architecture & Tech Stack

```
lib/
├── core/            # Theme, Constants, Localizations & Database Providers
├── data/            # Local SQLite & Isar Database Engine
├── domain/          # Hadith & Chapter Data Models
├── presentation/    # Riverpod State Management & UI Screens
└── widgets/         # Reusable Custom Components & Kutub Al-Sittah Promo Engine
```

* **Framework**: [Flutter 3.x](https://flutter.dev) (Dart 3)
* **State Management**: [Flutter Riverpod](https://pub.dev/packages/flutter_riverpod)
* **Database**: High-performance local SQLite (`sqflite`) & `isar_community`
* **Navigation**: [GoRouter](https://pub.dev/packages/go_router)
* **Typography**: [Google Fonts](https://pub.dev/packages/google_fonts) (Amiri, Lateef, Noto Nastaliq Urdu)

---

## 📚 Kutub Al-Sittah Hadith Ecosystem

This application is part of the **Kutub Al-Sittah (الكتب الستة)** Hadith suite developed by **Taha imam**:

| Hadith Collection | Status | GitHub Repository |
| :--- | :--- | :--- |
| 📖 **Sahih Al-Bukhari** | 🟢 Published | [shahihbukhari](https://github.com/tk85457/shahihbukhari) |
| 📖 **Sahih Muslim** | 🟢 Published | [shahihmuslim](https://github.com/tk85457/shahihmuslim) |
| 📖 **Jami at-Tirmidhi** | 🟢 Published | [JamiatTirmidhi](https://github.com/tk85457/JamiatTirmidhi) |
| 📖 **Sunan Abu Dawood** | 🟢 Published | [sunanabudawood](https://github.com/tk85457/sunanabudawood) |
| 📖 **Sunan An-Nasai** | 🟢 Published | [sunanannasai](https://github.com/tk85457/sunanannasai) |
| 📖 **Sunan Ibn Majah** | 🟢 Published | [sunanibnmajah](https://github.com/tk85457/sunanibnmajah) |

---

## 🚀 Getting Started

### Prerequisites
- [Flutter SDK](https://docs.flutter.dev/get-started/install) (`>= 3.10.0`)
- Android Studio / VS Code with Flutter extension
- Java JDK 17

### Installation

```bash
# 1. Clone the repository
git clone https://github.com/tk85457/shahihbukhari.git

# 2. Navigate to project directory
cd shahihbukhari

# 3. Install dependencies
flutter pub get

# 4. Run application
flutter run
```

### Build Production Release (AAB Bundle)

```bash
flutter build appbundle --release
```

---

## 👤 Author & License

* **Developer**: **Taha imam**
* **App Package**: `com.albukhari.hadith`
* **License**: MIT License - see [LICENSE](LICENSE) for details.
