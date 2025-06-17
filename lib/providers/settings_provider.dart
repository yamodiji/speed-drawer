import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/constants.dart';

class SettingsProvider extends ChangeNotifier {
  final SharedPreferences _prefs;
  
  bool _vibrationEnabled = true;
  bool _animationsEnabled = true;
  bool _autoFocus = true;
  bool _fuzzySearch = true;
  bool _showMostUsed = true;
  bool _showKeyboard = true;
  bool _showSearchHistory = true;
  bool _clearSearchOnClose = false;
  double _iconSize = AppConstants.mediumIconSize;
  double _backgroundOpacity = 0.9;

  SettingsProvider(this._prefs) {
    _loadSettings();
  }

  // Getters
  bool get vibrationEnabled => _vibrationEnabled;
  bool get animationsEnabled => _animationsEnabled;
  bool get autoFocus => _autoFocus;
  bool get fuzzySearch => _fuzzySearch;
  bool get showMostUsed => _showMostUsed;
  bool get showKeyboard => _showKeyboard;
  bool get showSearchHistory => _showSearchHistory;
  bool get clearSearchOnClose => _clearSearchOnClose;
  double get iconSize => _iconSize;
  double get backgroundOpacity => _backgroundOpacity;

  // Load all settings from SharedPreferences
  void _loadSettings() {
    _vibrationEnabled = _prefs.getBool(AppConstants.vibrationKey) ?? true;
    _animationsEnabled = _prefs.getBool(AppConstants.animationsKey) ?? true;
    _autoFocus = _prefs.getBool(AppConstants.autoFocusKey) ?? true;
    _fuzzySearch = _prefs.getBool(AppConstants.fuzzySearchKey) ?? true;
    _showMostUsed = _prefs.getBool(AppConstants.showMostUsedKey) ?? true;
    _showKeyboard = _prefs.getBool(AppConstants.showKeyboardKey) ?? true;
    _showSearchHistory = _prefs.getBool(AppConstants.showSearchHistoryKey) ?? true;
    _clearSearchOnClose = _prefs.getBool(AppConstants.clearSearchOnCloseKey) ?? false;
    _iconSize = _prefs.getDouble(AppConstants.iconSizeKey) ?? AppConstants.mediumIconSize;
    _backgroundOpacity = _prefs.getDouble(AppConstants.backgroundOpacityKey) ?? 0.9;
  }

  // Vibration settings
  void setVibrationEnabled(bool enabled) {
    _vibrationEnabled = enabled;
    _prefs.setBool(AppConstants.vibrationKey, enabled);
    notifyListeners();
  }

  // Animation settings
  void setAnimationsEnabled(bool enabled) {
    _animationsEnabled = enabled;
    _prefs.setBool(AppConstants.animationsKey, enabled);
    notifyListeners();
  }

  // Auto focus settings
  void setAutoFocus(bool enabled) {
    _autoFocus = enabled;
    _prefs.setBool(AppConstants.autoFocusKey, enabled);
    notifyListeners();
  }

  // Fuzzy search settings
  void setFuzzySearch(bool enabled) {
    _fuzzySearch = enabled;
    _prefs.setBool(AppConstants.fuzzySearchKey, enabled);
    notifyListeners();
  }

  // Show most used apps settings
  void setShowMostUsed(bool enabled) {
    _showMostUsed = enabled;
    _prefs.setBool(AppConstants.showMostUsedKey, enabled);
    notifyListeners();
  }

  // Show keyboard settings
  void setShowKeyboard(bool enabled) {
    _showKeyboard = enabled;
    _prefs.setBool(AppConstants.showKeyboardKey, enabled);
    notifyListeners();
  }

  // Show search history settings
  void setShowSearchHistory(bool enabled) {
    _showSearchHistory = enabled;
    _prefs.setBool(AppConstants.showSearchHistoryKey, enabled);
    notifyListeners();
  }

  // Clear search on close settings
  void setClearSearchOnClose(bool enabled) {
    _clearSearchOnClose = enabled;
    _prefs.setBool(AppConstants.clearSearchOnCloseKey, enabled);
    notifyListeners();
  }

  // Icon size settings
  void setIconSize(double size) {
    _iconSize = size;
    _prefs.setDouble(AppConstants.iconSizeKey, size);
    notifyListeners();
  }

  // Background opacity settings
  void setBackgroundOpacity(double opacity) {
    _backgroundOpacity = opacity;
    _prefs.setDouble(AppConstants.backgroundOpacityKey, opacity);
    notifyListeners();
  }

  // Get icon size label for UI
  String getIconSizeLabel() {
    if (_iconSize <= AppConstants.smallIconSize) {
      return 'Small';
    } else if (_iconSize <= AppConstants.mediumIconSize) {
      return 'Medium';
    } else if (_iconSize <= AppConstants.largeIconSize) {
      return 'Large';
    } else {
      return 'Extra Large';
    }
  }

  // Get background opacity percentage for UI
  String getBackgroundOpacityLabel() {
    return '${(_backgroundOpacity * 100).round()}%';
  }

  // Reset all settings to defaults
  void resetToDefaults() {
    _vibrationEnabled = true;
    _animationsEnabled = true;
    _autoFocus = true;
    _fuzzySearch = true;
    _showMostUsed = true;
    _showKeyboard = true;
    _showSearchHistory = true;
    _clearSearchOnClose = false;
    _iconSize = AppConstants.mediumIconSize;
    _backgroundOpacity = 0.9;

    // Save to preferences
    _prefs.setBool(AppConstants.vibrationKey, _vibrationEnabled);
    _prefs.setBool(AppConstants.animationsKey, _animationsEnabled);
    _prefs.setBool(AppConstants.autoFocusKey, _autoFocus);
    _prefs.setBool(AppConstants.fuzzySearchKey, _fuzzySearch);
    _prefs.setBool(AppConstants.showMostUsedKey, _showMostUsed);
    _prefs.setBool(AppConstants.showKeyboardKey, _showKeyboard);
    _prefs.setBool(AppConstants.showSearchHistoryKey, _showSearchHistory);
    _prefs.setBool(AppConstants.clearSearchOnCloseKey, _clearSearchOnClose);
    _prefs.setDouble(AppConstants.iconSizeKey, _iconSize);
    _prefs.setDouble(AppConstants.backgroundOpacityKey, _backgroundOpacity);

    notifyListeners();
  }

  // Export settings as JSON
  Map<String, dynamic> exportSettings() {
    return {
      'vibrationEnabled': _vibrationEnabled,
      'animationsEnabled': _animationsEnabled,
      'autoFocus': _autoFocus,
      'fuzzySearch': _fuzzySearch,
      'showMostUsed': _showMostUsed,
      'showKeyboard': _showKeyboard,
      'showSearchHistory': _showSearchHistory,
      'clearSearchOnClose': _clearSearchOnClose,
      'iconSize': _iconSize,
      'backgroundOpacity': _backgroundOpacity,
    };
  }

  // Import settings from JSON
  void importSettings(Map<String, dynamic> settings) {
    _vibrationEnabled = settings['vibrationEnabled'] ?? true;
    _animationsEnabled = settings['animationsEnabled'] ?? true;
    _autoFocus = settings['autoFocus'] ?? true;
    _fuzzySearch = settings['fuzzySearch'] ?? true;
    _showMostUsed = settings['showMostUsed'] ?? true;
    _showKeyboard = settings['showKeyboard'] ?? true;
    _showSearchHistory = settings['showSearchHistory'] ?? true;
    _clearSearchOnClose = settings['clearSearchOnClose'] ?? false;
    _iconSize = settings['iconSize']?.toDouble() ?? AppConstants.mediumIconSize;
    _backgroundOpacity = settings['backgroundOpacity']?.toDouble() ?? 0.9;

    // Save to preferences
    _prefs.setBool(AppConstants.vibrationKey, _vibrationEnabled);
    _prefs.setBool(AppConstants.animationsKey, _animationsEnabled);
    _prefs.setBool(AppConstants.autoFocusKey, _autoFocus);
    _prefs.setBool(AppConstants.fuzzySearchKey, _fuzzySearch);
    _prefs.setBool(AppConstants.showMostUsedKey, _showMostUsed);
    _prefs.setBool(AppConstants.showKeyboardKey, _showKeyboard);
    _prefs.setBool(AppConstants.showSearchHistoryKey, _showSearchHistory);
    _prefs.setBool(AppConstants.clearSearchOnCloseKey, _clearSearchOnClose);
    _prefs.setDouble(AppConstants.iconSizeKey, _iconSize);
    _prefs.setDouble(AppConstants.backgroundOpacityKey, _backgroundOpacity);

    notifyListeners();
  }

  // Get animation duration based on settings
  Duration getAnimationDuration() {
    return _animationsEnabled 
        ? Duration(milliseconds: AppConstants.animationDurationMs)
        : Duration.zero;
  }

  // Check if performance mode should be enabled (disable animations for better performance)
  bool get isPerformanceMode => !_animationsEnabled;
} 