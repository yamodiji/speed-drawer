import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';

import '../models/app_info.dart';
import '../utils/constants.dart';

class CacheService {
  static CacheService? _instance;
  static CacheService get instance => _instance ??= CacheService._internal();
  
  CacheService._internal();

  SharedPreferences? _prefs;
  final Map<String, Uint8List> _iconMemoryCache = {};
  final Map<String, AppInfo> _appMemoryCache = {};

  Future<void> initialize() async {
    _prefs ??= await SharedPreferences.getInstance();
    await _cleanOldCache();
  }

  // Clean old cache versions and expired data
  Future<void> _cleanOldCache() async {
    if (_prefs == null) return;

    final currentVersion = _prefs!.getInt(AppConstants.cacheVersionKey) ?? 0;
    if (currentVersion < AppConstants.cacheVersion) {
      // Clear old cache
      await _prefs!.remove(AppConstants.cachedAppsKey);
      await _prefs!.remove(AppConstants.cachedIconsKey);
      await _prefs!.setInt(AppConstants.cacheVersionKey, AppConstants.cacheVersion);
      debugPrint('Cache cleared due to version upgrade');
    }

    // Check cache age
    final lastUpdate = _prefs!.getInt(AppConstants.lastCacheUpdateKey) ?? 0;
    final now = DateTime.now().millisecondsSinceEpoch;
    if (now - lastUpdate > AppConstants.maxCacheAge) {
      await clearCache();
      debugPrint('Cache cleared due to age');
    }
  }

  // Cache app list (lightweight without icons)
  Future<void> cacheAppList(List<AppInfo> apps) async {
    if (_prefs == null) return;

    try {
      final lightApps = apps.map((app) => app.toLightJson()).toList();
      final jsonString = jsonEncode(lightApps);
      
      await _prefs!.setString(AppConstants.cachedAppsKey, jsonString);
      await _prefs!.setInt(AppConstants.lastCacheUpdateKey, DateTime.now().millisecondsSinceEpoch);
      
      // Update memory cache
      _appMemoryCache.clear();
      for (final app in apps) {
        _appMemoryCache[app.packageName] = app;
      }
      
      debugPrint('Cached ${apps.length} apps');
    } catch (e) {
      debugPrint('Error caching app list: $e');
    }
  }

  // Load cached app list
  Future<List<AppInfo>?> getCachedAppList() async {
    if (_prefs == null) return null;

    try {
      final jsonString = _prefs!.getString(AppConstants.cachedAppsKey);
      if (jsonString == null) return null;

      final List<dynamic> jsonList = jsonDecode(jsonString);
      final apps = jsonList.map((json) => AppInfo.fromJson(json)).toList();
      
      // Update memory cache
      _appMemoryCache.clear();
      for (final app in apps) {
        _appMemoryCache[app.packageName] = app;
      }
      
      debugPrint('Loaded ${apps.length} apps from cache');
      return apps;
    } catch (e) {
      debugPrint('Error loading cached app list: $e');
      return null;
    }
  }

  // Cache app icons separately (more efficient)
  Future<void> cacheAppIcon(String packageName, Uint8List iconData) async {
    if (_prefs == null) return;

    try {
      // Store in memory cache
      _iconMemoryCache[packageName] = iconData;

      // Manage persistent cache size
      final cachedIcons = _prefs!.getStringList(AppConstants.cachedIconsKey) ?? [];
      
      // Remove oldest if at max capacity
      if (cachedIcons.length >= AppConstants.iconCacheMaxSize) {
        final oldestKey = cachedIcons.first;
        cachedIcons.removeAt(0);
        await _prefs!.remove('icon_$oldestKey');
      }

      // Add new icon
      if (!cachedIcons.contains(packageName)) {
        cachedIcons.add(packageName);
        await _prefs!.setStringList(AppConstants.cachedIconsKey, cachedIcons);
      }

      // Store icon data
      final iconBase64 = base64Encode(iconData);
      await _prefs!.setString('icon_$packageName', iconBase64);
      
    } catch (e) {
      debugPrint('Error caching icon for $packageName: $e');
    }
  }

  // Get cached app icon
  Future<Uint8List?> getCachedAppIcon(String packageName) async {
    // Check memory cache first
    if (_iconMemoryCache.containsKey(packageName)) {
      return _iconMemoryCache[packageName];
    }

    if (_prefs == null) return null;

    try {
      final iconBase64 = _prefs!.getString('icon_$packageName');
      if (iconBase64 == null) return null;

      final iconData = base64Decode(iconBase64);
      
      // Store in memory cache for faster access
      _iconMemoryCache[packageName] = iconData;
      
      return iconData;
    } catch (e) {
      debugPrint('Error loading cached icon for $packageName: $e');
      return null;
    }
  }

  // Check if cache is valid
  bool isCacheValid() {
    if (_prefs == null) return false;

    final lastUpdate = _prefs!.getInt(AppConstants.lastCacheUpdateKey) ?? 0;
    final now = DateTime.now().millisecondsSinceEpoch;
    return (now - lastUpdate) < AppConstants.maxCacheAge;
  }

  // Preload frequently used icons into memory
  Future<void> preloadFrequentIcons(List<AppInfo> apps) async {
    if (_prefs == null) return;

    // Sort by usage and favorites
    final priorityApps = apps.where((app) => 
      app.isFavorite || app.launchCount > 0
    ).take(20).toList();

    for (final app in priorityApps) {
      if (!_iconMemoryCache.containsKey(app.packageName)) {
        final cachedIcon = await getCachedAppIcon(app.packageName);
        if (cachedIcon != null) {
          _iconMemoryCache[app.packageName] = cachedIcon;
        }
      }
    }

    debugPrint('Preloaded ${_iconMemoryCache.length} icons into memory');
  }

  // Get app from memory cache
  AppInfo? getCachedApp(String packageName) {
    return _appMemoryCache[packageName];
  }

  // Update app in cache
  Future<void> updateCachedApp(AppInfo app) async {
    _appMemoryCache[app.packageName] = app;
    
    // Update persistent cache
    final cachedApps = await getCachedAppList();
    if (cachedApps != null) {
      final index = cachedApps.indexWhere((a) => a.packageName == app.packageName);
      if (index >= 0) {
        cachedApps[index] = app;
        await cacheAppList(cachedApps);
      }
    }
  }

  // Clear all cache
  Future<void> clearCache() async {
    if (_prefs == null) return;

    await _prefs!.remove(AppConstants.cachedAppsKey);
    await _prefs!.remove(AppConstants.cachedIconsKey);
    await _prefs!.remove(AppConstants.lastCacheUpdateKey);
    
    // Clear cached icons
    final cachedIcons = _prefs!.getStringList(AppConstants.cachedIconsKey) ?? [];
    for (final packageName in cachedIcons) {
      await _prefs!.remove('icon_$packageName');
    }

    _iconMemoryCache.clear();
    _appMemoryCache.clear();
    
    debugPrint('All cache cleared');
  }

  // Get cache statistics
  Map<String, dynamic> getCacheStats() {
    final lastUpdate = _prefs?.getInt(AppConstants.lastCacheUpdateKey) ?? 0;
    final cacheAge = DateTime.now().millisecondsSinceEpoch - lastUpdate;
    
    return {
      'memoryApps': _appMemoryCache.length,
      'memoryIcons': _iconMemoryCache.length,
      'cacheAge': cacheAge,
      'cacheValid': isCacheValid(),
      'version': AppConstants.cacheVersion,
    };
  }

  // Clear memory cache (useful for memory management)
  void clearMemoryCache() {
    _iconMemoryCache.clear();
    _appMemoryCache.clear();
    debugPrint('Memory cache cleared');
  }
} 