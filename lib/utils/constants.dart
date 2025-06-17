import 'package:flutter/material.dart';

class AppConstants {
  // Theme constants
  static const String themeKey = 'theme_mode';
  static const String iconSizeKey = 'icon_size';
  static const String backgroundOpacityKey = 'background_opacity';
  static const String fuzzySearchKey = 'fuzzy_search';
  static const String favoriteAppsKey = 'favorite_apps';
  static const String mostUsedAppsKey = 'most_used_apps';
  static const String showMostUsedKey = 'show_most_used';
  static const String searchHistoryKey = 'search_history';
  static const String autoFocusKey = 'auto_focus';
  static const String vibrationKey = 'vibration';
  static const String animationsKey = 'animations';
  static const String showKeyboardKey = 'show_keyboard';
  static const String showSearchHistoryKey = 'show_search_history';
  static const String clearSearchOnCloseKey = 'clear_search_on_close';

  // Cache constants - NEW
  static const String cachedAppsKey = 'cached_apps_v2';
  static const String cacheVersionKey = 'cache_version';
  static const String lastCacheUpdateKey = 'last_cache_update';
  static const String cachedIconsKey = 'cached_icons_v2';
  static const int cacheVersion = 2;
  static const int maxCacheAge = 24 * 60 * 60 * 1000; // 24 hours in milliseconds
  static const int iconCacheMaxSize = 100; // Max number of icons to cache
  static const int preloadBatchSize = 20; // Load apps in batches for faster initial display

  // Performance constants
  static const int maxSearchResults = 50;
  static const int maxSearchHistory = 20;
  static const int maxMostUsedApps = 10;
  static const int debounceDelayMs = 50; // Reduced from 100ms for faster response
  static const int animationDurationMs = 150;

  // Icon sizes
  static const double smallIconSize = 32.0;
  static const double mediumIconSize = 48.0;
  static const double largeIconSize = 64.0;
  static const double extraLargeIconSize = 80.0;

  // Spacing
  static const double paddingSmall = 8.0;
  static const double paddingMedium = 16.0;
  static const double paddingLarge = 24.0;
  static const double borderRadius = 12.0;

  // Colors
  static const Color primaryColor = Color(0xFF2196F3);
  static const Color primaryDarkColor = Color(0xFF1976D2);
  static const Color accentColor = Color(0xFF03DAC6);
  static const Color errorColor = Color(0xFFB00020);

  // Search configuration
  static const double searchThreshold = 0.6;
  static const int minSearchLength = 1;

  // Widget configuration
  static const String widgetTitle = 'Speed Drawer';
  static const String widgetDescription = 'Quick app search';

  // Quick actions
  static const String quickActionSearch = 'search';
  static const String quickActionFavorites = 'favorites';
  static const String quickActionSettings = 'settings';
} 