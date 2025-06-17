# Speed Drawer

A high-performance custom app drawer for Android focused on speed and productivity. Built with Flutter 3.24.0.

## ✨ Features

- **⚡ Instant Search**: Opens directly to search interface with keyboard auto-focused
- **🔍 Smart Search**: Fuzzy search with partial matching and autocomplete
- **❤️ Favorites**: Pin your most-used apps for quick access
- **📊 Usage Tracking**: Shows most frequently used apps
- **🎨 Customizable**: Dark/light themes, icon sizes, background opacity
- **🏠 Launcher Replacement**: Can replace your default Android launcher
- **📱 Performance Optimized**: Minimal UI, smooth animations, fast app loading
- **🔧 Gestures & Quick Actions**: Widget support and quick tile access

## 🚀 Installation

### Download APK
1. Download the latest APK from the [Releases](../../releases) page
2. Enable "Install from unknown sources" in your Android settings
3. Install the APK
4. Optionally set as default launcher when prompted

### Build from Source
```bash
# Clone the repository
git clone https://github.com/yourusername/speed_drawer.git
cd speed_drawer

# Install dependencies
flutter pub get

# Generate app icons
flutter pub run flutter_launcher_icons:main

# Build APK
flutter build apk --release
```

## 📋 Requirements

- **Android**: 6.0+ (API level 23 or higher)
- **Flutter**: 3.24.0 stable
- **Permissions**: 
  - Query all packages (for app discovery)
  - Vibrate (haptic feedback)
  - System alert window (overlay features)

## 🎯 How to Use

### Basic Usage
1. **Open the app** - Search bar automatically focuses with keyboard open
2. **Start typing** - Apps filter instantly as you type
3. **Tap to launch** - Single tap opens the app
4. **Long press** - Access app options (favorite, info, etc.)

### Setting as Default Launcher
1. Go to Android **Settings** → **Apps** → **Default Apps** → **Home App**
2. Select **Speed Drawer** from the list
3. The app will now open when you press the home button

### Customization
- **Access Settings**: Tap the settings icon in the search bar
- **Themes**: Choose between Light, Dark, or System theme
- **Icon Size**: Adjust from Small to Extra Large
- **Background Opacity**: Customize transparency
- **Search Options**: Enable/disable fuzzy search
- **Behavior**: Auto-focus, vibration, animations

## 🔧 Performance Features

- **Optimized Rendering**: Uses Flutter's performance-optimized widgets
- **Debounced Search**: Prevents excessive filtering during typing
- **Lazy Loading**: Apps load as needed for better memory usage
- **High Refresh Rate**: Supports 90Hz/120Hz displays
- **Minimal Memory**: Lightweight with efficient state management

## 🎨 Customization Options

### Themes
- **Light Theme**: Clean, minimal design
- **Dark Theme**: Easy on the eyes, OLED-friendly
- **System Theme**: Follows Android system settings

### Layout
- **Icon Sizes**: 32px, 48px, 64px, 80px options
- **Grid Layout**: Responsive grid adjusts to screen size
- **Background Opacity**: 30% to 100% transparency

### Behavior
- **Auto Focus**: Keyboard opens automatically
- **Fuzzy Search**: Smart matching algorithms
- **Vibration**: Haptic feedback on interactions
- **Animations**: Smooth transitions (can be disabled)

## 🛠️ Development

### Project Structure
```
lib/
├── main.dart                 # App entry point
├── models/
│   └── app_info.dart        # App data model
├── providers/
│   ├── app_provider.dart    # App management & search
│   ├── theme_provider.dart  # Theme management
│   └── settings_provider.dart # Settings management
├── screens/
│   └── home_screen.dart     # Main app screen
├── widgets/
│   ├── search_bar_widget.dart
│   ├── app_grid_widget.dart
│   ├── app_item_widget.dart
│   ├── quick_actions_widget.dart
│   └── settings_drawer.dart
└── utils/
    └── constants.dart       # App constants
```

### Key Dependencies
- **device_apps**: Access installed applications
- **shared_preferences**: Persistent storage
- **provider**: State management
- **fuzzy**: Smart search functionality
- **flutter_launcher_icons**: App icon generation

### Building
```bash
# Development build
flutter run

# Release build
flutter build apk --release

# Build with optimization
flutter build apk --release --shrink --split-debug-info=build/symbols --obfuscate
```

## 🔒 Permissions Explained

- **QUERY_ALL_PACKAGES**: Required to access the list of installed apps
- **VIBRATE**: Provides haptic feedback when interacting with apps
- **RECEIVE_BOOT_COMPLETED**: Enables quick actions after device restart
- **SYSTEM_ALERT_WINDOW**: Allows overlay features (optional)

## 🐛 Troubleshooting

### Common Issues

**Apps not showing up**
- Ensure the app has proper permissions
- Try refreshing the app list in settings

**Search not working**
- Check if fuzzy search is enabled in settings
- Clear search history and try again

**Performance issues**
- Disable animations in settings
- Reduce icon size
- Clear app cache

### Performance Tips
- Disable animations for maximum speed
- Use smaller icon sizes on older devices
- Enable fuzzy search for better matching
- Clear search history periodically

## 📝 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## 📞 Support

If you encounter any issues or have suggestions:
- Open an [Issue](../../issues) on GitHub
- Check existing issues for solutions
- Contribute to discussions

## 🙏 Acknowledgments

- Flutter team for the amazing framework
- Android team for the platform capabilities
- Open source contributors for the packages used

---

**Note**: This app is designed for Android devices running API level 23 (Android 6.0) or higher. Some features may require specific permissions that need to be granted during installation. 