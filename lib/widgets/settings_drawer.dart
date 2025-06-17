import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/theme_provider.dart';
import '../providers/settings_provider.dart';
import '../providers/app_provider.dart';
import '../utils/constants.dart';

class SettingsDrawer extends StatelessWidget {
  final VoidCallback? onRefreshApps;
  
  const SettingsDrawer({
    super.key,
    this.onRefreshApps,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer3<ThemeProvider, SettingsProvider, AppProvider>(
      builder: (context, themeProvider, settingsProvider, appProvider, child) {
        return Drawer(
          backgroundColor: themeProvider.getBackgroundColor(context),
          child: SafeArea(
            child: Column(
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.all(AppConstants.paddingLarge),
                  decoration: BoxDecoration(
                    color: themeProvider.getAccentColor(context),
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(AppConstants.borderRadius),
                      bottomRight: Radius.circular(AppConstants.borderRadius),
                    ),
                  ),
                  child: const Row(
                    children: [
                      Icon(
                        Icons.speed,
                        color: Colors.white,
                        size: 32,
                      ),
                      SizedBox(width: AppConstants.paddingMedium),
                      Text(
                        'Speed Drawer',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),

                // Settings list
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.all(AppConstants.paddingMedium),
                    children: [
                      // Theme section
                      _buildSectionHeader(context, 'Appearance', themeProvider),
                      _buildThemeSelector(context, themeProvider),
                      _buildSliderSetting(
                        context,
                        'Icon Size',
                        settingsProvider.iconSize,
                        AppConstants.smallIconSize,
                        AppConstants.extraLargeIconSize,
                        settingsProvider.getIconSizeLabel(),
                        (value) => settingsProvider.setIconSize(value),
                        themeProvider,
                      ),
                      _buildSliderSetting(
                        context,
                        'Background Opacity',
                        settingsProvider.backgroundOpacity,
                        0.3,
                        1.0,
                        settingsProvider.getBackgroundOpacityLabel(),
                        (value) => settingsProvider.setBackgroundOpacity(value),
                        themeProvider,
                      ),

                      const SizedBox(height: AppConstants.paddingLarge),

                      // Behavior section
                      _buildSectionHeader(context, 'Behavior', themeProvider),
                      _buildSwitchSetting(
                        context,
                        'Auto Focus Search',
                        'Automatically focus search bar when app opens',
                        settingsProvider.autoFocus,
                        (value) => settingsProvider.setAutoFocus(value),
                        themeProvider,
                      ),
                      _buildSwitchSetting(
                        context,
                        'Show Keyboard',
                        'Show keyboard automatically so you can type immediately',
                        settingsProvider.showKeyboard,
                        (value) => settingsProvider.setShowKeyboard(value),
                        themeProvider,
                      ),
                      _buildSwitchSetting(
                        context,
                        'Show Search History',
                        'Display previous searches for quick access',
                        settingsProvider.showSearchHistory,
                        (value) => settingsProvider.setShowSearchHistory(value),
                        themeProvider,
                      ),
                      _buildSwitchSetting(
                        context,
                        'Clear Search on Close',
                        'Clear search text when app is closed or minimized',
                        settingsProvider.clearSearchOnClose,
                        (value) => settingsProvider.setClearSearchOnClose(value),
                        themeProvider,
                      ),
                      _buildSwitchSetting(
                        context,
                        'Fuzzy Search',
                        'Enable smart search with partial matches',
                        settingsProvider.fuzzySearch,
                        (value) => settingsProvider.setFuzzySearch(value),
                        themeProvider,
                      ),
                      _buildSwitchSetting(
                        context,
                        'Show Most Used',
                        'Display frequently used apps when not searching',
                        settingsProvider.showMostUsed,
                        (value) => settingsProvider.setShowMostUsed(value),
                        themeProvider,
                      ),
                      _buildSwitchSetting(
                        context,
                        'Vibration',
                        'Haptic feedback when interacting with apps',
                        settingsProvider.vibrationEnabled,
                        (value) => settingsProvider.setVibrationEnabled(value),
                        themeProvider,
                      ),
                      _buildSwitchSetting(
                        context,
                        'Animations',
                        'Enable smooth animations (disable for better performance)',
                        settingsProvider.animationsEnabled,
                        (value) => settingsProvider.setAnimationsEnabled(value),
                        themeProvider,
                      ),

                      const SizedBox(height: AppConstants.paddingLarge),

                      // Data section
                      _buildSectionHeader(context, 'Data', themeProvider),
                      if (settingsProvider.showSearchHistory)
                        _buildActionButton(
                          context,
                          'Clear Search History',
                          Icons.history,
                          () => appProvider.clearSearchHistory(),
                          themeProvider,
                        ),
                      _buildActionButton(
                        context,
                        'Refresh Apps',
                        Icons.refresh,
                        () {
                          if (onRefreshApps != null) {
                            onRefreshApps!();
                          } else {
                            appProvider.refreshApps();
                          }
                        },
                        themeProvider,
                      ),
                      _buildActionButton(
                        context,
                        'Reset Settings',
                        Icons.restore,
                        () => _showResetDialog(context, settingsProvider),
                        themeProvider,
                      ),

                      const SizedBox(height: AppConstants.paddingLarge),

                      // App info
                      _buildAppInfo(context, themeProvider),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSectionHeader(
    BuildContext context,
    String title,
    ThemeProvider themeProvider,
  ) {
    return Padding(
      padding: const EdgeInsets.only(
        top: AppConstants.paddingMedium,
        bottom: AppConstants.paddingSmall,
      ),
      child: Text(
        title,
        style: TextStyle(
          color: themeProvider.getAccentColor(context),
          fontSize: 14,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildThemeSelector(
    BuildContext context,
    ThemeProvider themeProvider,
  ) {
    return Card(
      color: themeProvider.getCardColor(context),
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.paddingMedium),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Theme',
              style: TextStyle(
                color: themeProvider.getTextColor(context),
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: AppConstants.paddingSmall),
            Row(
              children: [
                Expanded(
                  child: _buildThemeOption(
                    context,
                    'Light',
                    ThemeMode.light,
                    themeProvider,
                  ),
                ),
                const SizedBox(width: AppConstants.paddingSmall),
                Expanded(
                  child: _buildThemeOption(
                    context,
                    'Dark',
                    ThemeMode.dark,
                    themeProvider,
                  ),
                ),
                const SizedBox(width: AppConstants.paddingSmall),
                Expanded(
                  child: _buildThemeOption(
                    context,
                    'System',
                    ThemeMode.system,
                    themeProvider,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildThemeOption(
    BuildContext context,
    String label,
    ThemeMode mode,
    ThemeProvider themeProvider,
  ) {
    final isSelected = themeProvider.themeMode == mode;
    return GestureDetector(
      onTap: () => themeProvider.setThemeMode(mode),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: AppConstants.paddingSmall),
        decoration: BoxDecoration(
          color: isSelected
              ? themeProvider.getAccentColor(context)
              : themeProvider.getSurfaceColor(context),
          borderRadius: BorderRadius.circular(AppConstants.borderRadius),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: isSelected
                ? Colors.white
                : themeProvider.getTextColor(context),
            fontWeight: isSelected ? FontWeight.w500 : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildSwitchSetting(
    BuildContext context,
    String title,
    String subtitle,
    bool value,
    Function(bool) onChanged,
    ThemeProvider themeProvider,
  ) {
    return Card(
      color: themeProvider.getCardColor(context),
      child: SwitchListTile(
        title: Text(
          title,
          style: TextStyle(
            color: themeProvider.getTextColor(context),
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(
            color: themeProvider.getTextColor(context).withOpacity(0.7),
            fontSize: 12,
          ),
        ),
        value: value,
        onChanged: onChanged,
        activeColor: themeProvider.getAccentColor(context),
      ),
    );
  }

  Widget _buildSliderSetting(
    BuildContext context,
    String title,
    double value,
    double min,
    double max,
    String valueLabel,
    Function(double) onChanged,
    ThemeProvider themeProvider,
  ) {
    return Card(
      color: themeProvider.getCardColor(context),
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.paddingMedium),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: themeProvider.getTextColor(context),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  valueLabel,
                  style: TextStyle(
                    color: themeProvider.getAccentColor(context),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            Slider(
              value: value,
              min: min,
              max: max,
              onChanged: onChanged,
              activeColor: themeProvider.getAccentColor(context),
              inactiveColor: themeProvider.getSurfaceColor(context),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton(
    BuildContext context,
    String title,
    IconData icon,
    VoidCallback onPressed,
    ThemeProvider themeProvider,
  ) {
    return Card(
      color: themeProvider.getCardColor(context),
      child: ListTile(
        leading: Icon(
          icon,
          color: themeProvider.getAccentColor(context),
        ),
        title: Text(
          title,
          style: TextStyle(
            color: themeProvider.getTextColor(context),
          ),
        ),
        onTap: onPressed,
        trailing: Icon(
          Icons.chevron_right,
          color: themeProvider.getTextColor(context).withOpacity(0.5),
        ),
      ),
    );
  }

  Widget _buildAppInfo(BuildContext context, ThemeProvider themeProvider) {
    return Card(
      color: themeProvider.getCardColor(context),
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.paddingMedium),
        child: Column(
          children: [
            Text(
              'Speed Drawer',
              style: TextStyle(
                color: themeProvider.getTextColor(context),
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              'Version 1.0.0',
              style: TextStyle(
                color: themeProvider.getTextColor(context).withOpacity(0.7),
                fontSize: 12,
              ),
            ),
            const SizedBox(height: AppConstants.paddingSmall),
            Text(
              'A high-performance custom app drawer focused on speed and productivity.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: themeProvider.getTextColor(context).withOpacity(0.7),
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showResetDialog(BuildContext context, SettingsProvider settingsProvider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset Settings'),
        content: const Text(
          'This will reset all settings to their default values. This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              settingsProvider.resetToDefaults();
              Navigator.pop(context);
            },
            child: const Text('Reset'),
          ),
        ],
      ),
    );
  }
} 