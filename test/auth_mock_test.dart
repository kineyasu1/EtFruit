import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:agrimarketmob/providers/auth_provider.dart';
import 'package:agrimarketmob/services/auth_service.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    AuthService.isFirebaseAvailable = false;
  });

  test('Mock registration and sign in flow works correctly', () async {
    final container = ProviderContainer();
    final authNotifier = container.read(authProvider.notifier);

    // Verify initial state is null
    expect(container.read(authProvider), isNull);

    // Register a new user
    final registerSuccess = await authNotifier.signUpWithPassword(
      phoneNumber: '+251942723424',
      password: 'password123',
    );
    expect(registerSuccess, isTrue);

    // Verify user profile is loaded in state
    final userAfterRegister = container.read(authProvider);
    expect(userAfterRegister, isNotNull);
    expect(userAfterRegister!.phoneNumber, equals('+251942723424'));
    expect(userAfterRegister.name, isEmpty);

    // Sign out
    await AuthService().signOut();
    await Future.delayed(const Duration(milliseconds: 50));
    expect(container.read(authProvider), isNull);

    // Sign in back
    final signInSuccess = await authNotifier.signInWithPassword(
      phoneNumber: '+251942723424',
      password: 'password123',
    );
    expect(signInSuccess, isTrue);
    await Future.delayed(const Duration(milliseconds: 50));

    // Verify user profile is loaded in state after sign in
    final userAfterSignIn = container.read(authProvider);
    expect(userAfterSignIn, isNotNull);
    expect(userAfterSignIn!.phoneNumber, equals('+251942723424'));
  });
}
