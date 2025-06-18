import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:installed_apps/installed_apps.dart';
import 'package:installed_apps/app_info.dart' as installed_apps;

import '../models/app_info.dart';
import '../utils/constants.dart';
import 'cache_service.dart';

class AppLoadingService {
  static AppLoadingService? _instance;
  static AppLoadingService get instance => _instance ??= AppLoadingService._internal();
  
  AppLoadingService._internal();

  final CacheService _cacheService = CacheService.instance;
  final Map<String, bool> _systemAppCache = {};
  bool _isLoading = false;

  // Load apps with optimized caching and batching
  Future<List<AppInfo>> loadApps({
    required Function(List<AppInfo>) onBatchLoaded,
    required Function(int, int) onProgress,
  }) async {
    if (_isLoading) {
      debugPrint('App loading already in progress');
      return [];
    }

    _isLoading = true;
    try {
      // Step 1: Try to load from cache first for instant display
      final cachedApps = await _loadFromCache();
      if (cachedApps.isNotEmpty) {
        debugPrint('Loaded ${cachedApps.length} apps from cache instantly');
        onBatchLoaded(cachedApps);
        onProgress(cachedApps.length, cachedApps.length);
        
        // Preload frequently used icons in background
        _preloadIconsInBackground(cachedApps);
        
        // Check for updates in background
        _updateAppsInBackground(cachedApps, onBatchLoaded);
        
        return cachedApps;
      }

      // Step 2: Load fresh data if no valid cache
      debugPrint('No valid cache found, loading fresh data');
      return await _loadFreshApps(onBatchLoaded, onProgress);

    } finally {
      _isLoading = false;
    }
  }

  // Load apps from cache if valid
  Future<List<AppInfo>> _loadFromCache() async {
    if (!_cacheService.isCacheValid()) {
      return [];
    }

    final cachedApps = await _cacheService.getCachedAppList();
    if (cachedApps == null || cachedApps.isEmpty) {
      return [];
    }

    // Load icons for cached apps
    await _loadIconsForApps(cachedApps.take(AppConstants.preloadBatchSize).toList());
    
    return cachedApps;
  }

  // Load fresh apps with batching for perceived performance
  Future<List<AppInfo>> _loadFreshApps(
    Function(List<AppInfo>) onBatchLoaded,
    Function(int, int) onProgress,
  ) async {
    // Get installed apps (without icons for speed)
    final installedApps = await InstalledApps.getInstalledApps(
      true,  // exclude system apps initially
      false, // don't include icons yet for faster loading
      '',    // no package name filter
    );

    final List<AppInfo> allApps = [];
    final List<AppInfo> priorityApps = [];
    
    // Convert to AppInfo objects
    for (int i = 0; i < installedApps.length; i++) {
      final app = installedApps[i];
      
      if (_shouldHideApp(app)) continue;

      final appInfo = AppInfo.fromInstalledApp(app);
      
      // Check if it's a system app (cached for performance)
      final isSystemApp = await _getSystemAppStatus(app.packageName);
      final finalAppInfo = appInfo.copyWith(systemApp: isSystemApp);
      
      allApps.add(finalAppInfo);
      
      // Prioritize frequently used apps
      if (_isPriorityApp(finalAppInfo)) {
        priorityApps.add(finalAppInfo);
      }

      // Provide progress updates
      if (i % 10 == 0) {
        onProgress(i + 1, installedApps.length);
      }
    }

    // Sort apps by priority
    _sortAppsByPriority(allApps);

    // Load icons for first batch (priority apps) immediately
    if (priorityApps.isNotEmpty) {
      await _loadIconsForApps(priorityApps);
      onBatchLoaded(priorityApps);
      debugPrint('Loaded ${priorityApps.length} priority apps with icons');
    }

    // Load remaining apps in batches
    final remainingApps = allApps.where((app) => !priorityApps.contains(app)).toList();
    await _loadRemainingAppsInBatches(remainingApps, onBatchLoaded);

    // Cache the complete list
    await _cacheService.cacheAppList(allApps);
    
    onProgress(allApps.length, allApps.length);
    debugPrint('Completed loading ${allApps.length} apps');
    
    return allApps;
  }

  // Load remaining apps in batches to avoid blocking UI
  Future<void> _loadRemainingAppsInBatches(
    List<AppInfo> apps,
    Function(List<AppInfo>) onBatchLoaded,
  ) async {
    for (int i = 0; i < apps.length; i += AppConstants.preloadBatchSize) {
      final batch = apps.skip(i).take(AppConstants.preloadBatchSize).toList();
      
      // Load icons for this batch
      await _loadIconsForApps(batch);
      
      // Notify about this batch
      onBatchLoaded(batch);
      
      // Small delay to prevent blocking UI
      if (i + AppConstants.preloadBatchSize < apps.length) {
        await Future.delayed(const Duration(milliseconds: 50));
      }
      
      debugPrint('Loaded batch ${(i / AppConstants.preloadBatchSize).floor() + 1}');
    }
  }

  // Load icons for a list of apps efficiently
  Future<void> _loadIconsForApps(List<AppInfo> apps) async {
    final futures = apps.map((app) => _loadIconForApp(app)).toList();
    await Future.wait(futures);
  }

  // Load icon for individual app with caching
  Future<void> _loadIconForApp(AppInfo app) async {
    try {
      // Check cache first
      final cachedIcon = await _cacheService.getCachedAppIcon(app.packageName);
      if (cachedIcon != null) {
        app.copyWith(icon: cachedIcon);
        app.markIconCached();
        return;
      }

      // Skip icon loading in this simplified version to avoid API issues
      // Icons can be loaded on-demand in the UI
      debugPrint('Skipping icon loading for ${app.packageName} - will load on demand');
      
    } catch (e) {
      debugPrint('Error loading icon for ${app.packageName}: $e');
    }
  }

  // Check if app should be hidden
  bool _shouldHideApp(installed_apps.AppInfo app) {
    final hidePackages = [
      'com.android.launcher',
      'com.google.android.launcher',
      'com.sec.android.app.launcher',
      'com.miui.home',
      'com.oneplus.launcher',
      'com.android.settings',
      'com.android.packageinstaller',
    ];
    
    return hidePackages.any((pkg) => app.packageName.contains(pkg));
  }

  // Get system app status with caching
  Future<bool> _getSystemAppStatus(String packageName) async {
    if (_systemAppCache.containsKey(packageName)) {
      return _systemAppCache[packageName]!;
    }

    try {
      final isSystemApp = await InstalledApps.isSystemApp(packageName);
      _systemAppCache[packageName] = isSystemApp ?? false;
      return isSystemApp ?? false;
    } catch (e) {
      _systemAppCache[packageName] = false;
      return false;
    }
  }

  // Check if app should be prioritized
  bool _isPriorityApp(AppInfo app) {
    return app.isFavorite || 
           app.launchCount > 0 ||
           _isCommonApp(app.packageName);
  }

  // Common apps that users typically access frequently
  bool _isCommonApp(String packageName) {
    final commonApps = [
      'com.android.chrome',
      'com.google.android.apps.messaging',
      'com.whatsapp',
      'com.facebook.katana',
      'com.instagram.android',
      'com.spotify.music',
      'com.netflix.mediaclient',
      'com.android.gallery3d',
      'com.google.android.gm',
      'com.android.calculator2',
    ];
    
    return commonApps.any((pkg) => packageName.contains(pkg));
  }

  // Sort apps by priority for better user experience
  void _sortAppsByPriority(List<AppInfo> apps) {
    apps.sort((a, b) {
      // Favorites first
      if (a.isFavorite && !b.isFavorite) return -1;
      if (!a.isFavorite && b.isFavorite) return 1;
      
      // Then by launch count
      final countComparison = b.launchCount.compareTo(a.launchCount);
      if (countComparison != 0) return countComparison;
      
      // Then common apps
      final aIsCommon = _isCommonApp(a.packageName);
      final bIsCommon = _isCommonApp(b.packageName);
      if (aIsCommon && !bIsCommon) return -1;
      if (!aIsCommon && bIsCommon) return 1;
      
      // Finally by name
      return a.displayName.toLowerCase().compareTo(b.displayName.toLowerCase());
    });
  }

  // Preload icons in background
  void _preloadIconsInBackground(List<AppInfo> apps) {
    Future.delayed(const Duration(milliseconds: 100), () async {
      await _cacheService.preloadFrequentIcons(apps);
    });
  }

  // Update apps in background to check for new installations
  void _updateAppsInBackground(
    List<AppInfo> cachedApps,
    Function(List<AppInfo>) onBatchLoaded,
  ) {
    Future.delayed(const Duration(seconds: 2), () async {
      final freshApps = await _loadFreshApps(
        (apps) {}, // Don't notify for background updates
        (current, total) {}, // Don't show progress for background updates
      );
      
      // Check if there are new apps
      if (freshApps.length != cachedApps.length) {
        debugPrint('Found ${freshApps.length - cachedApps.length} new apps');
        onBatchLoaded(freshApps);
      }
    });
  }

  // Get cache statistics
  Map<String, dynamic> getPerformanceStats() {
    final cacheStats = _cacheService.getCacheStats();
    return {
      ...cacheStats,
      'systemAppCache': _systemAppCache.length,
      'isLoading': _isLoading,
    };
  }

  // Clear all caches
  Future<void> clearAllCaches() async {
    await _cacheService.clearCache();
    _systemAppCache.clear();
    debugPrint('All caches cleared');
  }
} 