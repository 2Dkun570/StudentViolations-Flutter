import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeModeProvider extends ChangeNotifier {
  static const _preferenceKey = 'is_dark_mode';
  ThemeMode _themeMode = ThemeMode.light;

  ThemeMode get themeMode => _themeMode;

  Future<void> load() async {
    final preferences = await SharedPreferences.getInstance();
    _themeMode = preferences.getBool(_preferenceKey) == true
        ? ThemeMode.dark
        : ThemeMode.light;
    notifyListeners();
  }

  Future<void> setDarkMode(bool enabled) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setBool(_preferenceKey, enabled);
    _themeMode = enabled ? ThemeMode.dark : ThemeMode.light;
    notifyListeners();
  }
}
