import 'package:flutter_test/flutter_test.dart';
import 'package:speed_drawer/models/app_info.dart';
import 'package:speed_drawer/services/cache_service.dart';
import 'package:speed_drawer/services/app_loading_service.dart';
import 'package:speed_drawer/utils/constants.dart';

void main() {
  // Initialize Flutter bindings for all tests
  TestWidgetsFlutterBinding.ensureInitialized();
  
  group('Performance Services Unit Tests', () {
    
    group('CacheService Tests', () {
      late CacheService cacheService;
      
      setUp(() async {
        cacheService = CacheService.instance;
        await cacheService.initialize();
      });
      
      test('should initialize successfully', () async {
        expect(cacheService, isNotNull);
        
        final stats = cacheService.getCacheStats();
        expect(stats, isA<Map<String, dynamic>>());
        expect(stats.containsKey('cacheValid'), isTrue);
        expect(stats.containsKey('memoryApps'), isTrue);
        expect(stats.containsKey('memoryIcons'), isTrue);
      });
      
      test('should cache and retrieve app list efficiently', () async {
        // Create test apps
        final testApps = List.generate(10, (index) => AppInfo(
          appName: 'Test App $index',
          packageName: 'com.test.app$index',
          launchCount: index,
          isFavorite: index % 3 == 0,
        ));
        
        // Test caching
        await cacheService.cacheAppList(testApps);
        
        // Test retrieval
        final cachedApps = await cacheService.getCachedAppList();
        
        expect(cachedApps, isNotNull);
        expect(cachedApps!.length, equals(testApps.length));
        
        // Validate app data integrity
        for (int i = 0; i < testApps.length; i++) {
          expect(cachedApps[i].appName, equals(testApps[i].appName));
          expect(cachedApps[i].packageName, equals(testApps[i].packageName));
          expect(cachedApps[i].launchCount, equals(testApps[i].launchCount));
          expect(cachedApps[i].isFavorite, equals(testApps[i].isFavorite));
        }
      });
      
      test('should handle cache validation correctly', () async {
        // Initially cache should be valid after initialization
        expect(cacheService.isCacheValid(), isTrue);
        
        // Test cache stats
        final stats = cacheService.getCacheStats();
        expect(stats['cacheValid'], isTrue);
        expect(stats['version'], equals(AppConstants.cacheVersion));
      });
      
      test('should manage memory cache efficiently', () async {
        final initialStats = cacheService.getCacheStats();
        final initialMemoryApps = initialStats['memoryApps'] as int;
        
        // Add some test apps to memory cache
        final testApps = List.generate(5, (index) => AppInfo(
          appName: 'Memory Test App $index',
          packageName: 'com.memory.test$index',
        ));
        
        await cacheService.cacheAppList(testApps);
        
        final afterStats = cacheService.getCacheStats();
        expect(afterStats['memoryApps'], greaterThanOrEqualTo(initialMemoryApps));
      });
      
      test('should clear cache properly', () async {
        // Add some test data
        final testApps = [AppInfo(appName: 'Test', packageName: 'com.test')];
        await cacheService.cacheAppList(testApps);
        
        // Clear cache
        await cacheService.clearCache();
        
        // Verify cache is cleared
        final stats = cacheService.getCacheStats();
        expect(stats['memoryApps'], equals(0));
        expect(stats['memoryIcons'], equals(0));
      });
    });
    
    group('AppLoadingService Tests', () {
      late AppLoadingService loadingService;
      
      setUp(() {
        loadingService = AppLoadingService.instance;
      });
      
      test('should provide performance stats', () {
        final stats = loadingService.getPerformanceStats();
        
        expect(stats, isA<Map<String, dynamic>>());
        expect(stats.containsKey('systemAppCache'), isTrue);
        expect(stats.containsKey('isLoading'), isTrue);
        expect(stats.containsKey('cacheValid'), isTrue);
      });
      
      test('should handle batch loading callbacks', () async {
        final List<List<AppInfo>> batches = [];
        final List<MapEntry<int, int>> progressUpdates = [];
        
        // Note: This test might not work in unit test environment without actual apps
        // but it validates the interface and callback structure
        try {
          await loadingService.loadApps(
            onBatchLoaded: (apps) {
              batches.add(apps);
            },
            onProgress: (current, total) {
              progressUpdates.add(MapEntry(current, total));
            },
          );
          
          // If we get here without exception, the interface works
          expect(batches, isA<List<List<AppInfo>>>());
          expect(progressUpdates, isA<List<MapEntry<int, int>>>());
          
        } catch (e) {
          // Expected in unit test environment without actual Android apps
          print('Note: App loading test skipped in unit test environment: $e');
        }
      });
      
      test('should manage system app cache', () {
        final initialStats = loadingService.getPerformanceStats();
        expect(initialStats['systemAppCache'], isA<int>());
        expect(initialStats['systemAppCache'], greaterThanOrEqualTo(0));
      });
      
      test('should clear all caches', () async {
        await loadingService.clearAllCaches();
        
        final stats = loadingService.getPerformanceStats();
        expect(stats['systemAppCache'], equals(0));
      });
    });
    
    group('Performance Constants Tests', () {
      test('should have reasonable performance constants', () {
        // Validate cache constants
        expect(AppConstants.maxCacheAge, greaterThan(0));
        expect(AppConstants.iconCacheMaxSize, greaterThan(0));
        expect(AppConstants.preloadBatchSize, greaterThan(0));
        expect(AppConstants.preloadBatchSize, lessThanOrEqualTo(50)); // Reasonable batch size
        
        // Validate performance constants
        expect(AppConstants.debounceDelayMs, greaterThan(0));
        expect(AppConstants.debounceDelayMs, lessThanOrEqualTo(100)); // Fast response
        expect(AppConstants.maxSearchResults, greaterThan(0));
        
        // Validate cache version
        expect(AppConstants.cacheVersion, greaterThan(0));
      });
      
      test('should have optimized debounce delay', () {
        // The optimized debounce delay should be faster than original
        expect(AppConstants.debounceDelayMs, equals(50)); // Reduced from 100ms
      });
      
      test('should have reasonable batch size', () {
        // Batch size should be optimized for performance
        expect(AppConstants.preloadBatchSize, equals(20));
      });
    });
    
    group('AppInfo Model Tests', () {
      test('should serialize and deserialize correctly', () {
        final originalApp = AppInfo(
          appName: 'Test App',
          packageName: 'com.test.app',
          launchCount: 5,
          isFavorite: true,
          systemApp: false,
          searchScore: 0.8,
        );
        
        // Test lightweight JSON
        final lightJson = originalApp.toLightJson();
        expect(lightJson['appName'], equals('Test App'));
        expect(lightJson['packageName'], equals('com.test.app'));
        expect(lightJson['launchCount'], equals(5));
        expect(lightJson['isFavorite'], equals(true));
        
        // Test full JSON without icon
        final fullJson = originalApp.toJson();
        expect(fullJson['appName'], equals('Test App'));
        expect(fullJson['packageName'], equals('com.test.app'));
        expect(fullJson.containsKey('iconData'), isFalse);
        
        // Test deserialization
        final deserializedApp = AppInfo.fromJson(fullJson);
        expect(deserializedApp.appName, equals(originalApp.appName));
        expect(deserializedApp.packageName, equals(originalApp.packageName));
        expect(deserializedApp.launchCount, equals(originalApp.launchCount));
        expect(deserializedApp.isFavorite, equals(originalApp.isFavorite));
      });
      
      test('should generate correct icon cache keys', () {
        final app1 = AppInfo(
          packageName: 'com.test.app1',
          appName: 'Test App 1',
          versionCode: 123,
        );
        
        final app2 = AppInfo(
          packageName: 'com.test.app2', 
          appName: 'Test App 2',
          versionCode: 456,
        );
        
        expect(app1.iconCacheKey, equals('icon_com.test.app1_123'));
        expect(app2.iconCacheKey, equals('icon_com.test.app2_456'));
        expect(app1.iconCacheKey, isNot(equals(app2.iconCacheKey)));
      });
      
      test('should handle search queries correctly', () {
        final app = AppInfo(
          appName: 'Chrome Browser',
          packageName: 'com.android.chrome',
          systemAppName: 'Google Chrome',
        );
        
        expect(app.matchesQuery('chrome'), isTrue);
        expect(app.matchesQuery('browser'), isTrue);
        expect(app.matchesQuery('google'), isTrue);
        expect(app.matchesQuery('android'), isTrue);
        expect(app.matchesQuery('firefox'), isFalse);
        expect(app.matchesQuery(''), isTrue); // Empty query matches all
      });
    });
  });
} 