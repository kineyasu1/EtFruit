import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:agrimarketmob/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('E2E App Integration Test', () {
    testWidgets('App starts and displays initial screen', (WidgetTester tester) async {
      // Clear preferences to start fresh
      SharedPreferences.setMockInitialValues({});
      
      // Start the app
      app.main();
      await tester.pumpAndSettle();

      // Verify the app starts up and has some text or initial view
      expect(find.byType(MaterialApp), findsOneWidget);
    });
  });
}
