import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/app_provider.dart';
import '../providers/theme_provider.dart';
import '../providers/settings_provider.dart';
import '../utils/constants.dart';

class QuickActionsWidget extends StatelessWidget {
  final Function(String) onSearchHistoryTap;

  const QuickActionsWidget({
    super.key,
    required this.onSearchHistoryTap,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer3<AppProvider, ThemeProvider, SettingsProvider>(
      builder: (context, appProvider, themeProvider, settingsProvider, child) {
        final hasSearchHistory = appProvider.searchHistory.isNotEmpty && settingsProvider.showSearchHistory;
        final hasFavorites = appProvider.favoriteApps.isNotEmpty;

        if (!hasSearchHistory && !hasFavorites) {
          return const SizedBox.shrink();
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Favorites section
            if (hasFavorites) ...[
              _buildSectionHeader(
                context,
                'Favorites',
                Icons.favorite,
                themeProvider,
              ),
              const SizedBox(height: AppConstants.paddingSmall),
              _buildFavoriteApps(context, appProvider, themeProvider),
              const SizedBox(height: AppConstants.paddingMedium),
            ],

            // Search history section
            if (hasSearchHistory) ...[
              _buildSectionHeader(
                context,
                'Recent Searches',
                Icons.history,
                themeProvider,
                onClear: () => appProvider.clearSearchHistory(),
              ),
              const SizedBox(height: AppConstants.paddingSmall),
              _buildSearchHistory(context, appProvider, themeProvider),
            ],
          ],
        );
      },
    );
  }

  Widget _buildSectionHeader(
    BuildContext context,
    String title,
    IconData icon,
    ThemeProvider themeProvider, {
    VoidCallback? onClear,
  }) {
    return Row(
      children: [
        Icon(
          icon,
          size: 16,
          color: themeProvider.getTextColor(context).withOpacity(0.7),
        ),
        const SizedBox(width: AppConstants.paddingSmall),
        Text(
          title,
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
            color: themeProvider.getTextColor(context).withOpacity(0.7),
            fontWeight: FontWeight.w600,
          ),
        ),
        const Spacer(),
        if (onClear != null)
          TextButton(
            onPressed: onClear,
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(
                horizontal: AppConstants.paddingSmall,
                vertical: 4,
              ),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Text(
              'Clear',
              style: TextStyle(
                color: themeProvider.getAccentColor(context),
                fontSize: 12,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildFavoriteApps(
    BuildContext context,
    AppProvider appProvider,
    ThemeProvider themeProvider,
  ) {
    return SizedBox(
      height: 60,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: appProvider.favoriteApps.length,
        itemBuilder: (context, index) {
          final app = appProvider.favoriteApps[index];
          return Padding(
            padding: EdgeInsets.only(
              right: index < appProvider.favoriteApps.length - 1
                  ? AppConstants.paddingMedium
                  : 0,
            ),
            child: GestureDetector(
              onTap: () => appProvider.launchApp(app),
              child: Column(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 2,
                          offset: const Offset(0, 1),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: app.icon != null
                          ? Image.memory(
                              app.icon!,
                              fit: BoxFit.cover,
                            )
                          : Container(
                              color: themeProvider.getSurfaceColor(context),
                              child: Icon(
                                Icons.android,
                                size: 24,
                                color: themeProvider.getTextColor(context).withOpacity(0.5),
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  SizedBox(
                    width: 40,
                    child: Text(
                      app.displayName,
                      style: TextStyle(
                        color: themeProvider.getTextColor(context),
                        fontSize: 10,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSearchHistory(
    BuildContext context,
    AppProvider appProvider,
    ThemeProvider themeProvider,
  ) {
    return Wrap(
      spacing: AppConstants.paddingSmall,
      runSpacing: AppConstants.paddingSmall,
      children: appProvider.searchHistory.take(6).map((query) {
        return GestureDetector(
          onTap: () => onSearchHistoryTap(query),
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppConstants.paddingMedium,
              vertical: AppConstants.paddingSmall,
            ),
            decoration: BoxDecoration(
              color: themeProvider.getSurfaceColor(context),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: themeProvider.getTextColor(context).withOpacity(0.1),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.history,
                  size: 14,
                  color: themeProvider.getTextColor(context).withOpacity(0.5),
                ),
                const SizedBox(width: 4),
                Text(
                  query,
                  style: TextStyle(
                    color: themeProvider.getTextColor(context),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
} 