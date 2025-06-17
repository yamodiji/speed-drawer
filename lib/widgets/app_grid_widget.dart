import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/app_info.dart';
import '../providers/theme_provider.dart';
import '../providers/settings_provider.dart';
import '../widgets/app_item_widget.dart';
import '../utils/constants.dart';

class AppGridWidget extends StatefulWidget {
  final List<AppInfo> apps;
  final Function(AppInfo) onAppTap;
  final Function(AppInfo) onAppLongPress;

  const AppGridWidget({
    super.key,
    required this.apps,
    required this.onAppTap,
    required this.onAppLongPress,
  });

  @override
  State<AppGridWidget> createState() => _AppGridWidgetState();
}

class _AppGridWidgetState extends State<AppGridWidget> 
    with AutomaticKeepAliveClientMixin {
  
  @override
  bool get wantKeepAlive => true; // Keep scroll position
  
  final ScrollController _scrollController = ScrollController();
  final Map<String, Widget> _widgetCache = {}; // Cache built widgets
  
  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required for AutomaticKeepAliveClientMixin
    
    if (widget.apps.isEmpty) {
      return _buildEmptyState(context);
    }

    return Consumer2<ThemeProvider, SettingsProvider>(
      builder: (context, themeProvider, settingsProvider, child) {
        // Calculate grid dimensions based on screen size and icon size
        final screenWidth = MediaQuery.of(context).size.width;
        final iconSize = settingsProvider.iconSize;
        final itemWidth = iconSize + AppConstants.paddingMedium * 2;
        final crossAxisCount = (screenWidth / itemWidth).floor().clamp(3, 6);

        return Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppConstants.paddingSmall,
          ),
          child: CustomScrollView(
            controller: _scrollController,
            physics: const BouncingScrollPhysics(
              parent: AlwaysScrollableScrollPhysics(), // Better scrolling feel
            ),
            cacheExtent: 500, // Increased cache for smoother scrolling
            slivers: [
              // OPTIMIZED: Performance optimized grid with caching
              SliverGrid(
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: crossAxisCount,
                  childAspectRatio: 0.9,
                  crossAxisSpacing: AppConstants.paddingSmall,
                  mainAxisSpacing: AppConstants.paddingSmall,
                ),
                delegate: SliverChildBuilderDelegate(
                  (context, index) => _buildCachedAppItem(
                    context,
                    widget.apps[index],
                    settingsProvider.animationsEnabled,
                  ),
                  childCount: widget.apps.length,
                  addAutomaticKeepAlives: true, // Keep items alive when scrolling
                  addRepaintBoundaries: true, // Isolate repaints
                  addSemanticIndexes: false, // Reduce overhead for large lists
                ),
              ),
              
              // Loading indicator for progressive loading
              if (widget.apps.length > AppConstants.preloadBatchSize) 
                SliverToBoxAdapter(
                  child: _buildLoadingIndicator(context),
                ),
              
              // Bottom padding
              const SliverToBoxAdapter(
                child: SizedBox(height: AppConstants.paddingLarge),
              ),
            ],
          ),
        );
      },
    );
  }

  // OPTIMIZED: Build cached app items for better performance
  Widget _buildCachedAppItem(BuildContext context, AppInfo app, bool animationsEnabled) {
    // Create cache key based on app state
    final cacheKey = '${app.packageName}_${app.isFavorite}_${app.launchCount}_${app.isIconCached}';
    
    // Return cached widget if available and still valid
    if (_widgetCache.containsKey(cacheKey)) {
      return _widgetCache[cacheKey]!;
    }
    
    // Build new widget and cache it
    final widget = RepaintBoundary(
      child: AppItemWidget(
        app: app,
        onTap: () => this.widget.onAppTap(app),
        onLongPress: () => this.widget.onAppLongPress(app),
        animationsEnabled: animationsEnabled,
      ),
    );
    
    // Cache management - keep only recent items
    if (_widgetCache.length > 100) {
      final keys = _widgetCache.keys.toList();
      for (int i = 0; i < 20; i++) {
        _widgetCache.remove(keys[i]);
      }
    }
    
    _widgetCache[cacheKey] = widget;
    return widget;
  }

  // OPTIMIZED: Loading indicator for progressive loading
  Widget _buildLoadingIndicator(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return Container(
          padding: const EdgeInsets.all(AppConstants.paddingMedium),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: themeProvider.getTextColor(context).withOpacity(0.6),
                ),
              ),
              const SizedBox(width: AppConstants.paddingSmall),
              Text(
                'Loading more apps...',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: themeProvider.getTextColor(context).withOpacity(0.6),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.search_off,
                size: 64,
                color: themeProvider.getTextColor(context).withOpacity(0.3),
              ),
              const SizedBox(height: AppConstants.paddingMedium),
              Text(
                'No apps found',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: themeProvider.getTextColor(context).withOpacity(0.6),
                ),
              ),
              const SizedBox(height: AppConstants.paddingSmall),
              Text(
                'Try adjusting your search',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: themeProvider.getTextColor(context).withOpacity(0.4),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // Clear cache when apps list changes significantly
  void _clearWidgetCache() {
    _widgetCache.clear();
  }

  @override
  void didUpdateWidget(AppGridWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    // Clear cache if app list changed significantly
    if (oldWidget.apps.length != widget.apps.length) {
      _clearWidgetCache();
    }
  }
} 