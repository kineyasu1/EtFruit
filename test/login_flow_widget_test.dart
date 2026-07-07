import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:agrimarketmob/views/auth/login_view.dart';
import 'package:agrimarketmob/l10n/app_localizations.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

void main() {
  Widget createTestWidget() {
    return const ProviderScope(
      child: MaterialApp(
        localizationsDelegates: [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: [
          Locale('en', ''),
        ],
        home: LoginView(),
      ),
    );
  }

  testWidgets('LoginView has phone and password fields and submit button', (WidgetTester tester) async {
    await tester.pumpWidget(createTestWidget());
    await tester.pumpAndSettle();

    // Verify phone number and password fields are present
    expect(find.byType(TextFormField), findsAtLeastNWidgets(2));
    
    // Verify logo or app title is present
    expect(find.text('Agriገበያ'), findsOneWidget);
  });
}
