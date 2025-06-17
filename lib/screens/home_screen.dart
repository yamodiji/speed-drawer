import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../providers/app_provider.dart';
import '../providers/theme_provider.dart';
import '../providers/settings_provider.dart';
import '../widgets/search_bar_widget.dart';
import '../widgets/app_grid_widget.dart';
import '../widgets/quick_actions_widget.dart';
import '../widgets/settings_drawer.dart';
import '../utils/constants.dart';
import '../models/app_info.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  bool _hasTriedKeyboardAfterLoad = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    
    // Auto-focus search bar when app opens with multiple attempts
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _requestKeyboardFocus();
    });

    // Listen to search controller changes
    _searchController.addListener(() {
      context.read<AppProvider>().search(_searchController.text);
    });
  }

  void _requestKeyboardFocus() {
    final settingsProvider = context.read<SettingsProvider>();
    if (settingsProvider.showKeyboard) {
      _searchFocusNode.requestFocus();
      
      // Force keyboard to show with a slight delay
      Future.delayed(const Duration(milliseconds: 100), () {
        if (mounted && settingsProvider.showKeyboard) {
          _searchFocusNode.requestFocus();
          SystemChannels.textInput.invokeMethod('TextInput.show');
        }
      });
      
      // Additional attempt with longer delay
      Future.delayed(const Duration(milliseconds: 300), () {
        if (mounted && settingsProvider.showKeyboard && !_searchFocusNode.hasFocus) {
          _searchFocusNode.requestFocus();
          SystemChannels.textInput.invokeMethod('TextInput.show');
        }
      });
    }
  }

  void _retryKeyboardAfterAppLoad() {
    final settingsProvider = context.read<SettingsProvider>();
    if (settingsProvider.showKeyboard && !_hasTriedKeyboardAfterLoad) {
      _hasTriedKeyboardAfterLoad = true;
      
      // Wait a bit after app loading completes, then try to show keyboard
      Future.delayed(const Duration(milliseconds: 200), () {
        if (mounted && settingsProvider.showKeyboard) {
          _searchFocusNode.requestFocus();
          SystemChannels.textInput.invokeMethod('TextInput.show');
          
          // Final backup attempt
          Future.delayed(const Duration(milliseconds: 500), () {
            if (mounted && settingsProvider.showKeyboard && !_searchFocusNode.hasFocus) {
              _searchFocusNode.requestFocus();
              SystemChannels.textInput.invokeMethod('TextInput.show');
            }
          });
        }
      });
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    
    if (state == AppLifecycleState.resumed) {
      // Reset keyboard retry flag when app resumes
      _hasTriedKeyboardAfterLoad = false;
      
      // Auto-focus when app comes back to foreground
      final settingsProvider = context.read<SettingsProvider>();
      if (settingsProvider.showKeyboard && !_searchFocusNode.hasFocus) {
        _requestKeyboardFocus();
      }
    } else if (state == AppLifecycleState.paused) {
      // Clear search when app is minimized/closed if setting is enabled
      final settingsProvider = context.read<SettingsProvider>();
      if (settingsProvider.clearSearchOnClose) {
        _searchController.clear();
        context.read<AppProvider>().clearSearch();
      }
    }
  }

  void _clearSearch() {
    _searchController.clear();
    context.read<AppProvider>().clearSearch();
    final settingsProvider = context.read<SettingsProvider>();
    if (settingsProvider.showKeyboard) {
      _searchFocusNode.requestFocus();
    }
  }

  void _openSettings() {
    _scaffoldKey.currentState?.openEndDrawer();
  }

  void _onRefreshApps() async {
    // Reset keyboard retry flag when manually refreshing
    _hasTriedKeyboardAfterLoad = false;
    // Call the actual refresh method
    await context.read<AppProvider>().refreshApps();
    // The keyboard retry will happen automatically when loading completes via the build method
  }

  @override
  Widget build(BuildContext context) {
    return Consumer3<AppProvider, ThemeProvider, SettingsProvider>(
      builder: (context, appProvider, themeProvider, settingsProvider, child) {
        // Check if apps just finished loading and retry keyboard if needed
        if (!appProvider.isLoading && !_hasTriedKeyboardAfterLoad) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _retryKeyboardAfterAppLoad();
          });
        }
        
        return Scaffold(
          key: _scaffoldKey,
          backgroundColor: themeProvider.getBackgroundColor(context),
          endDrawer: SettingsDrawer(
            onRefreshApps: _onRefreshApps,
          ),
          body: SafeArea(
            child: Column(
              children: [
                // Top padding
                const SizedBox(height: AppConstants.paddingMedium),
                
                // Search bar and quick actions
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppConstants.paddingMedium,
                  ),
                  child: Column(
                    children: [
                      // Search bar
                      SearchBarWidget(
                        controller: _searchController,
                        focusNode: _searchFocusNode,
                        onClear: _clearSearch,
                        onSettingsPressed: _openSettings,
                      ),
                      
                      // Quick actions (favorites, recent searches)
                      if (appProvider.searchQuery.isEmpty) ...[
                        const SizedBox(height: AppConstants.paddingMedium),
                        QuickActionsWidget(
                          onSearchHistoryTap: (query) {
                            _searchController.text = query;
                            appProvider.search(query);
                          },
                        ),
                      ],
                    ],
                  ),
                ),
                
                const SizedBox(height: AppConstants.paddingMedium),
                
                // App grid with optimized loading
                Expanded(
                  child: appProvider.isLoading && appProvider.isInitialLoad
                      ? _buildLoadingScreen(context, appProvider)
                      : AppGridWidget(
                          apps: appProvider.getDisplayApps(),
                          onAppTap: (app) async {
                            // Provide haptic feedback if enabled
                            if (settingsProvider.vibrationEnabled) {
                              HapticFeedback.lightImpact();
                            }
                            
                            // Launch app
                            final success = await appProvider.launchApp(app);
                            if (!success) {
                              // Show error if app failed to launch
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Failed to launch ${app.displayName}'),
                                    duration: const Duration(seconds: 2),
                                    backgroundColor: AppConstants.errorColor,
                                  ),
                                );
                              }
                            }
                          },
                          onAppLongPress: (app) {
                            // Provide haptic feedback if enabled
                            if (settingsProvider.vibrationEnabled) {
                              HapticFeedback.mediumImpact();
                            }
                            
                            // Show app options
                            _showAppOptions(context, app);
                          },
                        ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // OPTIMIZED: Enhanced loading screen with progress
  Widget _buildLoadingScreen(BuildContext context, AppProvider appProvider) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // App icon or logo
              Icon(
                Icons.apps,
                size: 64,
                color: themeProvider.getTextColor(context).withOpacity(0.6),
              ),
              const SizedBox(height: AppConstants.paddingLarge),
              
              // Loading progress
              SizedBox(
                width: 200,
                child: LinearProgressIndicator(
                  value: appProvider.loadingProgress,
                  backgroundColor: themeProvider.getTextColor(context).withOpacity(0.1),
                  valueColor: AlwaysStoppedAnimation<Color>(
                    themeProvider.getTextColor(context).withOpacity(0.6),
                  ),
                ),
              ),
              const SizedBox(height: AppConstants.paddingMedium),
              
              // Loading text
              Text(
                appProvider.loadingProgress > 0 
                  ? 'Loading apps... ${(appProvider.loadingProgress * 100).toInt()}%'
                  : 'Discovering apps...',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: themeProvider.getTextColor(context).withOpacity(0.6),
                ),
              ),
              
              // Performance tip
              const SizedBox(height: AppConstants.paddingLarge),
              Text(
                'Apps will appear as they load',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: themeProvider.getTextColor(context).withOpacity(0.4),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showAppOptions(BuildContext context, AppInfo app) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Consumer2<AppProvider, ThemeProvider>(
        builder: (context, appProvider, themeProvider, child) {
          return Container(
            decoration: BoxDecoration(
              color: themeProvider.getCardColor(context),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(AppConstants.borderRadius),
              ),
            ),
            padding: const EdgeInsets.all(AppConstants.paddingLarge),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // App info header
                Row(
                  children: [
                    // App icon
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        color: themeProvider.getSurfaceColor(context),
                      ),
                      child: app.icon != null
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.memory(
                                app.icon!,
                                fit: BoxFit.cover,
                              ),
                            )
                          : const Icon(Icons.android),
                    ),
                    
                    const SizedBox(width: AppConstants.paddingMedium),
                    
                    // App details
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            app.displayName,
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              color: themeProvider.getTextColor(context),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (app.launchCount > 0)
                            Text(
                              'Launched ${app.launchCount} times',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: themeProvider.getTextColor(context).withOpacity(0.7),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: AppConstants.paddingLarge),
                
                // Action buttons
                Row(
                  children: [
                    // Favorite button
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          appProvider.toggleFavorite(app);
                          Navigator.pop(context);
                        },
                        icon: Icon(
                          app.isFavorite ? Icons.favorite : Icons.favorite_border,
                          color: app.isFavorite ? Colors.red : null,
                        ),
                        label: Text(app.isFavorite ? 'Unfavorite' : 'Favorite'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: themeProvider.getSurfaceColor(context),
                          foregroundColor: themeProvider.getTextColor(context),
                        ),
                      ),
                    ),
                    
                    const SizedBox(width: AppConstants.paddingMedium),
                    
                    // Launch button
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () async {
                          Navigator.pop(context);
                          await appProvider.launchApp(app);
                        },
                        icon: const Icon(Icons.launch),
                        label: const Text('Launch'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: themeProvider.getAccentColor(context),
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
                
                // Bottom padding for safe area
                SizedBox(height: MediaQuery.of(context).padding.bottom),
              ],
            ),
          );
        },
      ),
    );
  }
} 