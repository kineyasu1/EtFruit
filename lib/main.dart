import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:agrimarketmob/l10n/app_localizations.dart';

import 'providers/language_provider.dart';
import 'providers/auth_provider.dart';
import 'services/auth_service.dart';
import 'services/notification_service.dart';
import 'views/language_selection_view.dart';
import 'views/auth/login_view.dart';
import 'views/auth/profile_setup_view.dart';
import 'views/auth/onboarding_choice_view.dart';
import 'views/home/home_view.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase with fallback support for offline/mock development
  try {
    // Note: If google-services.json is missing or invalid, this will throw.
    await Firebase.initializeApp();
    AuthService.isFirebaseAvailable = true;
    debugPrint('Firebase successfully initialized.');
    
    // Initialize push notifications
    await NotificationService().initialize();
  } catch (e) {
    AuthService.isFirebaseAvailable = false;
    debugPrint('Firebase initialization failed: $e');
    if (kReleaseMode) {
      throw StateError(
        'CRITICAL: Firebase failed to initialize in release mode. '
        'Verify google-services.json configuration. Error details: $e'
      );
    } else {
      debugPrint('Running app in sandbox/mock database mode.');
    }
  }

  final prefs = await SharedPreferences.getInstance();
  final hasSelectedLanguage = prefs.containsKey('language_code');

  runApp(ProviderScope(child: MyApp(hasSelectedLanguage: hasSelectedLanguage)));
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key, required this.hasSelectedLanguage});

  final bool hasSelectedLanguage;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeLocale = ref.watch(languageProvider);

    return MaterialApp(
      title: 'Agriገበያ',
      navigatorKey: NavigationService.navigatorKey,
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        primaryColor: const Color(0xFF1B5E20),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1B5E20),
          primary: const Color(0xFF1B5E20),
          secondary: const Color(0xFFFBC02D),
          background: const Color(0xFFF9FBF7),
        ),
        scaffoldBackgroundColor: const Color(0xFFF9FBF7),
        cardTheme: const CardThemeData(color: Colors.white, elevation: 2),
      ),
      locale: activeLocale,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        FallbackMaterialLocalizationsDelegate(),
        FallbackCupertinoLocalizationsDelegate(),
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('en', ''), // English
        Locale('am', ''), // Amharic
        Locale('om', ''), // Afaan Oromo
        Locale('so', ''), // Somali
        Locale('ti', ''), // Tigrinya
      ],
      home: AppRootNavigator(hasSelectedLanguage: hasSelectedLanguage),
    );
  }
}

class AppRootNavigator extends ConsumerWidget {
  const AppRootNavigator({super.key, required this.hasSelectedLanguage});

  final bool hasSelectedLanguage;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider);

    // Flow 1: If language hasn't been chosen yet, show Language Selector
    if (!hasSelectedLanguage) {
      return const LanguageSelectionView(isFromSettings: false);
    }

    // Flow 2: If user is not authenticated, show Login View
    if (user == null) {
      return const LoginView();
    }

    // Flow 3: If authenticated but profile details are blank, show Profile Setup
    if (user.name.isEmpty || user.region.isEmpty) {
      return ProfileSetupView(phoneNumber: user.phoneNumber);
    }

    // Flow 3.5: If profile is complete but role is not chosen, show Onboarding Choice
    if (user.role.isEmpty) {
      return const OnboardingChoiceView();
    }

    // Flow 4: Profile & Role are complete, route to Home
    return const HomeView();
  }
}

class FallbackMaterialLocalizationsDelegate
    extends LocalizationsDelegate<MaterialLocalizations> {
  const FallbackMaterialLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) =>
      ['om', 'so', 'ti'].contains(locale.languageCode);

  @override
  Future<MaterialLocalizations> load(Locale locale) =>
      GlobalMaterialLocalizations.delegate.load(const Locale('en', ''));

  @override
  bool shouldReload(FallbackMaterialLocalizationsDelegate old) => false;
}

class FallbackCupertinoLocalizationsDelegate
    extends LocalizationsDelegate<CupertinoLocalizations> {
  const FallbackCupertinoLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) =>
      ['om', 'so', 'ti'].contains(locale.languageCode);

  @override
  Future<CupertinoLocalizations> load(Locale locale) =>
      GlobalCupertinoLocalizations.delegate.load(const Locale('en', ''));

  @override
  bool shouldReload(FallbackCupertinoLocalizationsDelegate old) => false;
}
