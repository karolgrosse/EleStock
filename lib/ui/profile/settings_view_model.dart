import 'package:flutter/material.dart';

/// Languages the app will offer. Only English is translated so far.
enum AppLanguage { english, polish }

/// App-wide settings chosen on the profile screen.
///
/// Created once in `main.dart`, above [MaterialApp], so that changing the
/// theme here recolours every screen at once. Kept in memory for now; saving
/// it on the device comes with the local database in lab 3.
class SettingsViewModel extends ChangeNotifier {
  SettingsViewModel({
    this._themeMode = ThemeMode.system,
    this._language = AppLanguage.english,
  });

  ThemeMode _themeMode;
  ThemeMode get themeMode => _themeMode;

  AppLanguage _language;
  AppLanguage get language => _language;

  void setThemeMode(ThemeMode mode) {
    if (mode == _themeMode) return;
    _themeMode = mode;
    notifyListeners();
  }

  void setLanguage(AppLanguage language) {
    if (language == _language) return;
    _language = language;
    notifyListeners();
  }
}
