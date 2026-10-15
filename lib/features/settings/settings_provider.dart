import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppSettings {
  final bool isDarkMode;
  final bool showArabic;
  final bool showUrdu;
  final bool showEnglish;
  final double arabicFontSize;
  final double urduFontSize;
  final double englishFontSize;
  final String arabicFontFamily;
  final String urduFontFamily;
  final String englishFontFamily;
  final String arabicFontColor;
  final String urduFontColor;
  final String englishFontColor;
  final String viewType;
  final String uiColor;
  final String urduAlignment;
  final String titleLanguage;

  const AppSettings({
    this.isDarkMode = false,
    this.showArabic = true,
    this.showUrdu = true,
    this.showEnglish = true,
    this.arabicFontSize = 24.0,
    this.urduFontSize = 20.0,
    this.englishFontSize = 18.0,
    this.arabicFontFamily = 'AlQalam',
    this.urduFontFamily = 'Nastaleeq',
    this.englishFontFamily = 'Inter',
    this.arabicFontColor = 'Black',
    this.urduFontColor = 'Black',
    this.englishFontColor = 'Black',
    this.viewType = 'All Ahadith',
    this.uiColor = 'Book Theme',
    this.urduAlignment = 'Right',
    this.titleLanguage = 'Urdu',
  });

  String get activeFontFamily {
    if (titleLanguage == 'English') return englishFontFamily;
    if (titleLanguage == 'Arabic') return arabicFontFamily;
    return urduFontFamily;
  }

  double get activeFontSize {
    if (titleLanguage == 'English') return englishFontSize;
    if (titleLanguage == 'Arabic') return arabicFontSize;
    return urduFontSize;
  }

  String get activeTextDirection {
    if (titleLanguage == 'English') return 'Left';
    return 'Right';
  }

  String get activeAlignment {
    if (titleLanguage == 'English') return 'Left';
    if (titleLanguage == 'Arabic') return 'Right';
    return urduAlignment;
  }

  AppSettings copyWith({
    bool? isDarkMode,
    bool? showArabic,
    bool? showUrdu,
    bool? showEnglish,
    double? arabicFontSize,
    double? urduFontSize,
    double? englishFontSize,
    String? arabicFontFamily,
    String? urduFontFamily,
    String? englishFontFamily,
    String? arabicFontColor,
    String? urduFontColor,
    String? englishFontColor,
    String? viewType,
    String? uiColor,
    String? urduAlignment,
    String? titleLanguage,
  }) {
    return AppSettings(
      isDarkMode: isDarkMode ?? this.isDarkMode,
      showArabic: showArabic ?? this.showArabic,
      showUrdu: showUrdu ?? this.showUrdu,
      showEnglish: showEnglish ?? this.showEnglish,
      arabicFontSize: arabicFontSize ?? this.arabicFontSize,
      urduFontSize: urduFontSize ?? this.urduFontSize,
      englishFontSize: englishFontSize ?? this.englishFontSize,
      arabicFontFamily: arabicFontFamily ?? this.arabicFontFamily,
      urduFontFamily: urduFontFamily ?? this.urduFontFamily,
      englishFontFamily: englishFontFamily ?? this.englishFontFamily,
      arabicFontColor: arabicFontColor ?? this.arabicFontColor,
      urduFontColor: urduFontColor ?? this.urduFontColor,
      englishFontColor: englishFontColor ?? this.englishFontColor,
      viewType: viewType ?? this.viewType,
      uiColor: uiColor ?? this.uiColor,
      urduAlignment: urduAlignment ?? this.urduAlignment,
      titleLanguage: titleLanguage ?? this.titleLanguage,
    );
  }
}

class SettingsNotifier extends Notifier<AppSettings> {
  late final SharedPreferences _prefs;

  @override
  AppSettings build() {
    _prefs = ref.watch(sharedPreferencesProvider);
    return AppSettings(
      isDarkMode: _prefs.getBool('isDarkMode') ?? false,
      showArabic: _prefs.getBool('showArabic') ?? true,
      showUrdu: _prefs.getBool('showUrdu') ?? true,
      showEnglish: _prefs.getBool('showEnglish') ?? true,
      arabicFontSize: _prefs.getDouble('arabicFontSize') ?? 24.0,
      urduFontSize: _prefs.getDouble('urduFontSize') ?? 20.0,
      englishFontSize: _prefs.getDouble('englishFontSize') ?? 18.0,
      arabicFontFamily: _prefs.getString('arabicFontFamily') ?? 'AlQalam',
      urduFontFamily: _prefs.getString('urduFontFamily') ?? 'Nastaleeq',
      englishFontFamily: _prefs.getString('englishFontFamily') ?? 'Rubik',
      arabicFontColor: _prefs.getString('arabicFontColor') ?? 'Black',
      urduFontColor: _prefs.getString('urduFontColor') ?? 'Black',
      englishFontColor: _prefs.getString('englishFontColor') ?? 'Black',
      viewType: _prefs.getString('viewType') ?? 'All Ahadith',
      uiColor: () {
        final saved = _prefs.getString('uiColor');
        if (saved == null || saved == 'Terracotta' || saved == 'Default') {
          return 'Book Theme';
        }
        return saved;
      }(),
      urduAlignment: _prefs.getString('urduAlignment') ?? 'Right',
      titleLanguage: _prefs.getString('titleLanguage') ?? 'Urdu',
    );
  }

  Future<void> updateViewType(String type) async {
    state = state.copyWith(viewType: type);
    await _prefs.setString('viewType', type);
  }

  Future<void> updateTheme(bool isDark) async {
    state = state.copyWith(isDarkMode: isDark);
    await _prefs.setBool('isDarkMode', isDark);
  }

  Future<void> toggleTranslation(String language, bool show) async {
    switch (language) {
      case 'Arabic':
        state = state.copyWith(showArabic: show);
        await _prefs.setBool('showArabic', show);
        break;
      case 'Urdu':
        state = state.copyWith(showUrdu: show);
        await _prefs.setBool('showUrdu', show);
        break;
      case 'English':
        state = state.copyWith(showEnglish: show);
        await _prefs.setBool('showEnglish', show);
        break;
    }
  }

  Future<void> updateFontSize(String language, double size) async {
    switch (language) {
      case 'Arabic':
        state = state.copyWith(arabicFontSize: size);
        await _prefs.setDouble('arabicFontSize', size);
        break;
      case 'Urdu':
        state = state.copyWith(urduFontSize: size);
        await _prefs.setDouble('urduFontSize', size);
        break;
      case 'English':
        state = state.copyWith(englishFontSize: size);
        await _prefs.setDouble('englishFontSize', size);
        break;
    }
  }

  Future<void> updateFontFamily(String language, String fontFamily) async {
    switch (language) {
      case 'Arabic':
        state = state.copyWith(arabicFontFamily: fontFamily);
        await _prefs.setString('arabicFontFamily', fontFamily);
        break;
      case 'Urdu':
        state = state.copyWith(urduFontFamily: fontFamily);
        await _prefs.setString('urduFontFamily', fontFamily);
        break;
      case 'English':
        state = state.copyWith(englishFontFamily: fontFamily);
        await _prefs.setString('englishFontFamily', fontFamily);
        break;
    }
  }

  Future<void> updateFontColor(String language, String fontColor) async {
    switch (language) {
      case 'Arabic':
        state = state.copyWith(arabicFontColor: fontColor);
        await _prefs.setString('arabicFontColor', fontColor);
        break;
      case 'Urdu':
        state = state.copyWith(urduFontColor: fontColor);
        await _prefs.setString('urduFontColor', fontColor);
        break;
      case 'English':
        state = state.copyWith(englishFontColor: fontColor);
        await _prefs.setString('englishFontColor', fontColor);
        break;
    }
  }

  Future<void> updateUiColor(String color) async {
    state = state.copyWith(uiColor: color);
    await _prefs.setString('uiColor', color);
  }

  Future<void> updateUrduAlignment(String alignment) async {
    state = state.copyWith(urduAlignment: alignment);
    await _prefs.setString('urduAlignment', alignment);
  }

  Future<void> updateTitleLanguage(String titleLanguage) async {
    state = state.copyWith(titleLanguage: titleLanguage);
    await _prefs.setString('titleLanguage', titleLanguage);
  }
}

final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('Initialize this in main.dart');
});

final settingsProvider = NotifierProvider<SettingsNotifier, AppSettings>(SettingsNotifier.new);
