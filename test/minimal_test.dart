import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:speed_drawer/main.dart';

void main() {
  testWidgets('App should instantiate without errors', (WidgetTester tester) async {
    // Mock SharedPreferences for testing
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    
    // Test that SpeedDrawerApp can be instantiated
    expect(() => SpeedDrawerApp(prefs: prefs), returnsNormally);
  });
  
  testWidgets('App should build basic widget tree', (WidgetTester tester) async {
    // Mock SharedPreferences for testing
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    
    // Build the app and trigger a frame
    await tester.pumpWidget(SpeedDrawerApp(prefs: prefs));
    
    // Verify that the app builds without throwing
    expect(find.byType(SpeedDrawerApp), findsOneWidget);
  });
} 