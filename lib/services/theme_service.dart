import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeService with ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.system;
  SharedPreferences? _prefs;

  ThemeMode get themeMode => _themeMode;

  ThemeService() {
    _loadThemePreference();
  }

  // Tema tercihini Shared Preferences'tan yükler
  Future<void> _loadThemePreference() async {
    _prefs = await SharedPreferences.getInstance();
    final themeString = _prefs?.getString('theme_preference') ?? 'system';
    _themeMode = _getThemeModeFromString(themeString);
    notifyListeners(); // Tema yüklendikten sonra dinleyicileri bilgilendir
  }

  // Tema tercihini Shared Preferences'a kaydeder
  Future<void> setThemeMode(ThemeMode mode) async {
    if (_prefs == null) {
      _prefs = await SharedPreferences.getInstance();
    }
    _themeMode = mode;
    await _prefs?.setString('theme_preference', _getStringFromThemeMode(mode));
    notifyListeners(); // Tema değişimini dinleyicilere bildir
  }

  // String değeri ThemeMode enum'ına çevirir
  ThemeMode _getThemeModeFromString(String themeString) {
    switch (themeString) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      case 'system':
        return ThemeMode.system;
      default:
        return ThemeMode.system;
    }
  }

  // ThemeMode enum değerini String'e çevirir
  String _getStringFromThemeMode(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return 'light';
      case ThemeMode.dark:
        return 'dark';
      case ThemeMode.system:
        return 'system';
    }
  }
} 