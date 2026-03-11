import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class ThemeProvider with ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.light;
  AppThemePreset _preset = AppThemePreset.classicLight;

  ThemeMode get themeMode => _themeMode;
  AppThemePreset get preset => _preset;

  Color get seedColor {
    final current = AppThemeCatalog.options.firstWhere((o) => o.preset == _preset);
    return current.preview;
  }

  ThemeData get lightTheme => AppThemeCatalog.buildTheme(_preset, Brightness.light);
  ThemeData get darkTheme => AppThemeCatalog.buildTheme(_preset, Brightness.dark);

  void setThemeMode(ThemeMode mode) {
    _themeMode = mode;
    notifyListeners();
  }

  void setThemePreset(AppThemePreset preset) {
    _preset = preset;
    final selected = AppThemeCatalog.options.firstWhere((o) => o.preset == preset);
    _themeMode = selected.forceDark ? ThemeMode.dark : ThemeMode.light;
    notifyListeners();
  }

  void setSeedColor(Color color) {
    final preset = AppThemeCatalog.options.firstWhere(
      (option) => option.preview.toARGB32() == color.toARGB32(),
      orElse: () => AppThemeCatalog.options.first,
    );
    setThemePreset(preset.preset);
  }
}