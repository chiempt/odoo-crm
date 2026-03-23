import 'package:flutter/material.dart';

enum AppFont { nunitoSans, inter, roboto }

class ThemeProvider with ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.system;
  AppFont _font = AppFont.nunitoSans;
  double _fontSizeScale = 1.0;

  ThemeMode get themeMode => _themeMode;
  AppFont get font => _font;
  double get fontSizeScale => _fontSizeScale;

  void toggleTheme() {
    _themeMode = _themeMode == ThemeMode.light
        ? ThemeMode.dark
        : ThemeMode.light;
    notifyListeners();
  }

  void setSystemTheme() {
    _themeMode = ThemeMode.system;
    notifyListeners();
  }

  void setFont(AppFont font) {
    _font = font;
    notifyListeners();
  }

  void setFontSizeScale(double scale) {
    _fontSizeScale = scale;
    notifyListeners();
  }
}
