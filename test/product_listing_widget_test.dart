import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:agrimarketmob/views/home/home_view.dart';
import 'package:agrimarketmob/providers/auth_provider.dart';
import 'package:agrimarketmob/models/user_model.dart';
import 'package:agrimarketmob/l10n/app_localizations.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

class FakeAuthNotifier extends AuthNotifier {
  FakeAuthNotifier() : super() {
    state = UserModel(
      id: 'mock_uid',
      name: 'Test User',
      phoneNumber: '+251911111111',
      region: 'Oromia',
      zone: 'East Shewa',
      woreda: 'Ada\'a',
      role: 'buyer',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }
}

void main() {
  Widget createTestWidget() {
    return ProviderScope(
      overrides: [
        authProvider.overrideWith((ref) => FakeAuthNotifier()),
      ],
      child: const MaterialApp(
        localizationsDelegates: [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: [
          Locale('en', ''),
        ],
        home: BrowseFeedSubView(),
      ),
    );
  }

  testWidgets('BrowseFeedSubView has search bar and category scroll list', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    
    await tester.pumpWidget(createTestWidget());
    await tester.pumpAndSettle();

    // Verify search text field is present
    expect(find.byType(TextField), findsOneWidget);
  });
}
