import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/constants.dart';

class ThemeProvider extends ChangeNotifier {
  final SharedPreferences _prefs;
  
  ThemeMode _themeMode = ThemeMode.system;
  double _iconSize = AppConstants.mediumIconSize;
  double _backgroundOpacity = 0.9;

  ThemeProvider(this._prefs) {
    _loadThemePreferences();
  }

  // Getters
  ThemeMode get themeMode => _themeMode;
  double get iconSize => _iconSize;
  double get backgroundOpacity => _backgroundOpacity;

  bool get isDarkMode => _themeMode == ThemeMode.dark ||
      (_themeMode == ThemeMode.system && 
       WidgetsBinding.instance.platformDispatcher.platformBrightness == Brightness.dark);

  // Theme definitions
  ThemeData get lightTheme => ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppConstants.primaryColor,
      brightness: Brightness.light,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      iconTheme: IconThemeData(color: Colors.black87),
    ),
    scaffoldBackgroundColor: Colors.white.withOpacity(_backgroundOpacity),
    cardTheme: CardTheme(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppConstants.borderRadius),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.grey[100],
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppConstants.borderRadius),
        borderSide: BorderSide.none,
      ),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppConstants.paddingMedium,
        vertical: AppConstants.paddingSmall,
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppConstants.borderRadius),
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: AppConstants.paddingLarge,
          vertical: AppConstants.paddingMedium,
        ),
      ),
    ),
  );

  ThemeData get darkTheme => ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppConstants.primaryColor,
      brightness: Brightness.dark,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      iconTheme: IconThemeData(color: Colors.white70),
    ),
    scaffoldBackgroundColor: Colors.black.withOpacity(_backgroundOpacity),
    cardTheme: CardTheme(
      elevation: 4,
      color: Colors.grey[900],
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppConstants.borderRadius),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.grey[800],
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppConstants.borderRadius),
        borderSide: BorderSide.none,
      ),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppConstants.paddingMedium,
        vertical: AppConstants.paddingSmall,
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppConstants.borderRadius),
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: AppConstants.paddingLarge,
          vertical: AppConstants.paddingMedium,
        ),
      ),
    ),
  );

  // Methods to update theme settings
  void setThemeMode(ThemeMode mode) {
    _themeMode = mode;
    _prefs.setString(AppConstants.themeKey, mode.toString());
    notifyListeners();
  }

  void setIconSize(double size) {
    _iconSize = size;
    _prefs.setDouble(AppConstants.iconSizeKey, size);
    notifyListeners();
  }

  void setBackgroundOpacity(double opacity) {
    _backgroundOpacity = opacity;
    _prefs.setDouble(AppConstants.backgroundOpacityKey, opacity);
    notifyListeners();
  }

  void toggleTheme() {
    if (_themeMode == ThemeMode.light) {
      setThemeMode(ThemeMode.dark);
    } else {
      setThemeMode(ThemeMode.light);
    }
  }

  // Load preferences from storage
  void _loadThemePreferences() {
    final themeString = _prefs.getString(AppConstants.themeKey);
    if (themeString != null) {
      _themeMode = ThemeMode.values.firstWhere(
        (mode) => mode.toString() == themeString,
        orElse: () => ThemeMode.system,
      );
    }

    _iconSize = _prefs.getDouble(AppConstants.iconSizeKey) ?? AppConstants.mediumIconSize;
    _backgroundOpacity = _prefs.getDouble(AppConstants.backgroundOpacityKey) ?? 0.9;
  }

  // Get appropriate text color based on current theme
  Color getTextColor(BuildContext context) {
    return isDarkMode ? Colors.white : Colors.black87;
  }

  // Get appropriate accent color
  Color getAccentColor(BuildContext context) {
    return isDarkMode ? AppConstants.accentColor : AppConstants.primaryColor;
  }

  // Get appropriate background color with opacity
  Color getBackgroundColor(BuildContext context) {
    final baseColor = isDarkMode ? Colors.black : Colors.white;
    return baseColor.withOpacity(_backgroundOpacity);
  }

  // Get appropriate card color
  Color getCardColor(BuildContext context) {
    return isDarkMode ? Colors.grey[900]! : Colors.white;
  }

  // Get appropriate surface color
  Color getSurfaceColor(BuildContext context) {
    return isDarkMode ? Colors.grey[800]! : Colors.grey[100]!;
  }
} 