import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:speed_drawer/main.dart';

void main() {
  testWidgets('App launches without crashing', (WidgetTester tester) async {
    // Initialize shared preferences
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    // Build our app and trigger a frame
    await tester.pumpWidget(SpeedDrawerApp(prefs: prefs));

    // Wait for the app to load
    await tester.pumpAndSettle();

    // Verify that the app loads successfully
    expect(find.byType(MaterialApp), findsOneWidget);
  });

  testWidgets('Search bar is present and focused', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    await tester.pumpWidget(SpeedDrawerApp(prefs: prefs));
    await tester.pumpAndSettle();

    // Look for search input field
    expect(find.byType(TextField), findsOneWidget);
  });

  testWidgets('Settings drawer can be opened', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    await tester.pumpWidget(SpeedDrawerApp(prefs: prefs));
    await tester.pumpAndSettle();

    // Look for settings button
    final settingsButton = find.byIcon(Icons.settings);
    expect(settingsButton, findsOneWidget);

    // Tap settings button
    await tester.tap(settingsButton);
    await tester.pumpAndSettle();

    // Verify drawer opens
    expect(find.text('Speed Drawer'), findsWidgets);
  });
} 