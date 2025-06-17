import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_displaymode/flutter_displaymode.dart';

import 'providers/app_provider.dart';
import 'providers/theme_provider.dart';
import 'providers/settings_provider.dart';
import 'screens/home_screen.dart';
import 'services/cache_service.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize cache service early for better performance
  await CacheService.instance.initialize();
  
  // Set system UI overlays for immersive experience
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      systemNavigationBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );

  // Set high refresh rate if available
  try {
    await FlutterDisplayMode.setHighRefreshRate();
  } catch (e) {
    // Ignore if not supported
  }

  // Initialize SharedPreferences
  final prefs = await SharedPreferences.getInstance();

  runApp(SpeedDrawerApp(prefs: prefs));
}

class SpeedDrawerApp extends StatelessWidget {
  final SharedPreferences prefs;

  const SpeedDrawerApp({super.key, required this.prefs});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider(prefs)),
        ChangeNotifierProvider(create: (_) => SettingsProvider(prefs)),
        ChangeNotifierProvider(create: (_) => AppProvider()),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          return MaterialApp(
            title: 'Speed Drawer',
            debugShowCheckedModeBanner: false,
            theme: themeProvider.lightTheme,
            darkTheme: themeProvider.darkTheme,
            themeMode: themeProvider.themeMode,
            home: const HomeScreen(),
            routes: {
              '/home': (context) => const HomeScreen(),
            },
          );
        },
      ),
    );
  }
} 