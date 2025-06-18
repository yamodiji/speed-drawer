import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:installed_apps/installed_apps.dart';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:fuzzy/fuzzy.dart';

import '../models/app_info.dart';
import '../utils/constants.dart';
import '../services/cache_service.dart';
import '../services/app_loading_service.dart';

class AppProvider extends ChangeNotifier {
  List<AppInfo> _allApps = [];
  List<AppInfo> _filteredApps = [];
  List<AppInfo> _favoriteApps = [];
  List<AppInfo> _mostUsedApps = [];
  List<String> _searchHistory = [];
  
  String _searchQuery = '';
  bool _isLoading = false;
  bool _isInitialLoad = true;
  bool _fuzzySearchEnabled = true;
  bool _showMostUsed = true;
  bool _autoFocus = true;
  
  int _loadingProgress = 0;
  int _totalAppsToLoad = 0;
  
  Timer? _debounceTimer;
  late Fuzzy<AppInfo> _fuzzySearcher;
  SharedPreferences? _prefs;
  
  final CacheService _cacheService = CacheService.instance;
  final AppLoadingService _loadingService = AppLoadingService.instance;

  // Getters
  List<AppInfo> get allApps => _allApps;
  List<AppInfo> get filteredApps => _filteredApps;
  List<AppInfo> get favoriteApps => _favoriteApps;
  List<AppInfo> get mostUsedApps => _mostUsedApps;
  List<String> get searchHistory => _searchHistory;
  String get searchQuery => _searchQuery;
  bool get isLoading => _isLoading;
  bool get isInitialLoad => _isInitialLoad;
  bool get fuzzySearchEnabled => _fuzzySearchEnabled;
  bool get showMostUsed => _showMostUsed;
  bool get autoFocus => _autoFocus;
  double get loadingProgress => _totalAppsToLoad > 0 ? _loadingProgress / _totalAppsToLoad : 0.0;

  AppProvider() {
    _initializeFuzzySearcher();
    _loadAppsOptimized();
  }

  void _initializeFuzzySearcher() {
    _fuzzySearcher = Fuzzy<AppInfo>(
      _allApps,
      options: FuzzyOptions(
        keys: [
          WeightedKey(
            name: 'appName',
            getter: (app) => app.appName,
            weight: 1.0,
          ),
          WeightedKey(
            name: 'packageName',
            getter: (app) => app.packageName,
            weight: 0.5,
          ),
          WeightedKey(
            name: 'systemAppName',
            getter: (app) => app.systemAppName ?? '',
            weight: 0.8,
          ),
        ],
        threshold: AppConstants.searchThreshold,
        shouldSort: true,
      ),
    );
  }

  // OPTIMIZED: New app loading with caching and batching
  Future<void> _loadAppsOptimized() async {
    _setLoading(true);
    
    try {
      // Load preferences first
      _prefs = await SharedPreferences.getInstance();
      await _loadSettings();
      
      // Use optimized loading service
      final apps = await _loadingService.loadApps(
        onBatchLoaded: _onAppBatchLoaded,
        onProgress: _onLoadingProgress,
      );
        
      if (apps.isNotEmpty) {
        _allApps = apps;
      await _loadStoredAppData();
        _sortApps();
      _initializeFuzzySearcher();
        _updateDerivedLists();
        _isInitialLoad = false;
      }
      
    } catch (e) {
      debugPrint('Error loading apps: $e');
    } finally {
      _setLoading(false);
    }
  }

  // Handle batch loading for progressive UI updates
  void _onAppBatchLoaded(List<AppInfo> batchApps) {
    if (_isInitialLoad && _allApps.isEmpty) {
      // First batch - immediately show to user
      _allApps = List.from(batchApps);
      _loadStoredAppDataSync(); // Synchronous version for immediate display
      _sortApps();
      _initializeFuzzySearcher();
      _updateDerivedLists();
      _setFilteredApps();
      notifyListeners();
    } else {
      // Subsequent batches - merge with existing
      final existingPackages = _allApps.map((app) => app.packageName).toSet();
      final newApps = batchApps.where((app) => !existingPackages.contains(app.packageName)).toList();
      
      if (newApps.isNotEmpty) {
        _allApps.addAll(newApps);
        _sortApps();
        _initializeFuzzySearcher();
        _updateDerivedLists();
        _setFilteredApps();
        notifyListeners();
      }
    }
  }

  // Handle loading progress updates
  void _onLoadingProgress(int current, int total) {
    _loadingProgress = current;
    _totalAppsToLoad = total;
    notifyListeners();
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  // OPTIMIZED: Faster synchronous data loading for immediate display
  void _loadStoredAppDataSync() {
    if (_prefs == null) return;
    
    final favoritePackages = _prefs!.getStringList(AppConstants.favoriteAppsKey) ?? [];
    final mostUsedData = _prefs!.getString(AppConstants.mostUsedAppsKey);
    
    Map<String, dynamic> usageData = {};
    if (mostUsedData != null) {
      try {
        usageData = jsonDecode(mostUsedData);
      } catch (e) {
        debugPrint('Error parsing usage data: $e');
      }
    }
    
    // Update app data in batches for better performance
    for (var app in _allApps) {
      app.isFavorite = favoritePackages.contains(app.packageName);
      
      if (usageData.containsKey(app.packageName)) {
        final data = usageData[app.packageName];
        if (data != null) {
          app.launchCount = data['launchCount'] ?? 0;
          app.lastLaunchTime = data['lastLaunchTime'] ?? 0;
        }
      }
    }
  }

  // Async version for background updates
  Future<void> _loadStoredAppData() async {
    _loadStoredAppDataSync();
  }

  // OPTIMIZED: Faster app data saving
  Future<void> _saveAppData() async {
    if (_prefs == null) return;
    
    try {
    // Save favorites
    final favoritePackages = _allApps
        .where((app) => app.isFavorite)
        .map((app) => app.packageName)
        .toList();
    
      // Save usage data for frequently used apps only
    final usageData = <String, dynamic>{};
      for (var app in _allApps.where((app) => app.launchCount > 0)) {
        usageData[app.packageName] = {
          'launchCount': app.launchCount,
          'lastLaunchTime': app.lastLaunchTime,
        };
      }
      
      // Batch save operations
      await Future.wait([
        _prefs!.setStringList(AppConstants.favoriteAppsKey, favoritePackages),
        _prefs!.setString(AppConstants.mostUsedAppsKey, jsonEncode(usageData)),
      ]);
      
      // Update cache
      await _cacheService.cacheAppList(_allApps);
      
    } catch (e) {
      debugPrint('Error saving app data: $e');
    }
  }

  Future<void> _loadSettings() async {
    if (_prefs == null) return;
    
    _fuzzySearchEnabled = _prefs!.getBool(AppConstants.fuzzySearchKey) ?? true;
    _showMostUsed = _prefs!.getBool(AppConstants.showMostUsedKey) ?? true;
    _autoFocus = _prefs!.getBool(AppConstants.autoFocusKey) ?? true;
    _searchHistory = _prefs!.getStringList(AppConstants.searchHistoryKey) ?? [];
  }

  // OPTIMIZED: Faster search with improved debouncing
  void search(String query) {
    _searchQuery = query.trim();
    
    // Immediate search for short queries or clearing
    if (_searchQuery.isEmpty || _searchQuery.length <= 2) {
      _debounceTimer?.cancel();
      _performSearch();
      return;
    }
    
    // Debounce longer searches
    _debounceTimer?.cancel();
    _debounceTimer = Timer(
      Duration(milliseconds: AppConstants.debounceDelayMs),
      () => _performSearch(),
    );
  }

  void _performSearch() {
    if (_searchQuery.isEmpty) {
      _setFilteredApps();
    } else {
      List<AppInfo> results;
      
      if (_fuzzySearchEnabled && _searchQuery.length >= AppConstants.minSearchLength) {
        // Use fuzzy search
        final fuzzyResults = _fuzzySearcher.search(_searchQuery);
        results = fuzzyResults
            .take(AppConstants.maxSearchResults)
            .map((result) => result.item)
            .toList();
      } else {
        // Use optimized contains search
        results = _allApps
            .where((app) => app.matchesQuery(_searchQuery))
            .take(AppConstants.maxSearchResults)
            .toList();
      }
      
      _filteredApps = results;
      _addToSearchHistory(_searchQuery);
    }
    
    notifyListeners();
  }

  void _setFilteredApps() {
    _filteredApps = List.from(_allApps);
  }

  void _addToSearchHistory(String query) {
    if (query.isEmpty) return;
    
    _searchHistory.remove(query);
    _searchHistory.insert(0, query);
    
    if (_searchHistory.length > AppConstants.maxSearchHistory) {
      _searchHistory = _searchHistory.take(AppConstants.maxSearchHistory).toList();
    }
    
    _prefs?.setStringList(AppConstants.searchHistoryKey, _searchHistory);
  }

  // OPTIMIZED: Faster app launching with caching
  Future<bool> launchApp(AppInfo app) async {
    try {
      final launched = await InstalledApps.startApp(app.packageName);
      if (launched == true) {
        // Update usage statistics
        app.launchCount++;
        app.lastLaunchTime = DateTime.now().millisecondsSinceEpoch;
        
        // Update cache immediately
        await _cacheService.updateCachedApp(app);
        
        // Re-sort and update lists
        _sortApps();
        _updateDerivedLists();
        
        // Save data in background
        _saveAppData();
        
        // Clear search
        clearSearch();
        
        // Provide haptic feedback
        HapticFeedback.lightImpact();
        
        notifyListeners();
        return true;
      }
    } catch (e) {
      debugPrint('Error launching app ${app.packageName}: $e');
    }
    return false;
  }

  void toggleFavorite(AppInfo app) {
    app.isFavorite = !app.isFavorite;
    _sortApps();
    _updateDerivedLists();
    _saveAppData(); // Save immediately for favorites
    notifyListeners();
  }

  // OPTIMIZED: Faster list updates
  void _updateDerivedLists() {
    _favoriteApps = _allApps.where((app) => app.isFavorite).toList();
    _mostUsedApps = _allApps
        .where((app) => app.launchCount > 0)
        .take(AppConstants.maxMostUsedApps)
        .toList();
  }

  void _sortApps() {
    _allApps.sort((a, b) {
      // Favorites first
      if (a.isFavorite && !b.isFavorite) return -1;
      if (!a.isFavorite && b.isFavorite) return 1;
      
      // Then by launch count
      final countComparison = b.launchCount.compareTo(a.launchCount);
      if (countComparison != 0) return countComparison;
      
      // Finally by name
      return a.displayName.toLowerCase().compareTo(b.displayName.toLowerCase());
    });
  }

  void clearSearch() {
    _searchQuery = '';
    _setFilteredApps();
    notifyListeners();
  }

  void clearSearchHistory() {
    _searchHistory.clear();
    _prefs?.setStringList(AppConstants.searchHistoryKey, []);
    notifyListeners();
  }

  // Settings methods
  void setFuzzySearch(bool enabled) {
    _fuzzySearchEnabled = enabled;
    _prefs?.setBool(AppConstants.fuzzySearchKey, enabled);
    if (_searchQuery.isNotEmpty) {
      _performSearch();
    }
    notifyListeners();
  }

  void setShowMostUsed(bool show) {
    _showMostUsed = show;
    _prefs?.setBool(AppConstants.showMostUsedKey, show);
    notifyListeners();
  }

  void setAutoFocus(bool autoFocus) {
    _autoFocus = autoFocus;
    _prefs?.setBool(AppConstants.autoFocusKey, autoFocus);
    notifyListeners();
  }

  // OPTIMIZED: Faster refresh
  Future<void> refreshApps() async {
    _isInitialLoad = true;
    await _loadAppsOptimized();
  }

  // OPTIMIZED: Better display logic
  List<AppInfo> getDisplayApps() {
    if (_searchQuery.isNotEmpty) {
      return _filteredApps;
    } else if (_showMostUsed && _mostUsedApps.isNotEmpty) {
      return _mostUsedApps;
    } else {
      return _favoriteApps.isNotEmpty ? _favoriteApps : _allApps.take(20).toList();
    }
  }

  // Performance monitoring
  Map<String, dynamic> getPerformanceStats() {
    return _loadingService.getPerformanceStats();
  }

  // Clear all caches (for debugging/troubleshooting)
  Future<void> clearAllCaches() async {
    await _loadingService.clearAllCaches();
    await refreshApps();
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    super.dispose();
  }
} 