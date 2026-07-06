import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:agrimarketmob/main.dart';

void main() {
  testWidgets('App boots and renders Agriገበያ', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(
      const ProviderScope(
        child: MyApp(hasSelectedLanguage: false),
      ),
    );

    // Verify that our app name is rendered.
    expect(find.text('Agriገበያ'), findsOneWidget);
  });
}
