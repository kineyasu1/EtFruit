import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'dart:async';
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
import 'views/listing/listing_detail_view.dart';
import 'views/cart/order_detail_view.dart';
import 'views/profile/user_profile_view.dart';
import 'package:app_links/app_links.dart';

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
      _firebaseInitError = e.toString();
    } else {
      debugPrint('Running app in sandbox/mock database mode.');
    }
  }

  final prefs = await SharedPreferences.getInstance();
  final hasSelectedLanguage = prefs.containsKey('language_code');

  runApp(ProviderScope(child: MyApp(
    hasSelectedLanguage: hasSelectedLanguage,
    initError: _firebaseInitError,
  )));
}

String? _firebaseInitError;

class MyApp extends ConsumerWidget {
  const MyApp({super.key, required this.hasSelectedLanguage, this.initError});

  final bool hasSelectedLanguage;
  final String? initError;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Set the global Riverpod container context for push notifications Tap Navigation
    NotificationService().refProviderContext = ProviderScope.containerOf(context);

    if (initError != null) {
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Scaffold(
          body: Container(
            color: const Color(0xFFD32F2F),
            padding: const EdgeInsets.all(24.0),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.error_outline_rounded,
                    color: Colors.white,
                    size: 80,
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'FATAL INITIALIZATION ERROR',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Firebase failed to initialize in release mode. Production builds require a valid google-services.json configuration.',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                      height: 1.4,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.black26,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      initError!,
                      style: const TextStyle(
                        color: Colors.white,
                        fontFamily: 'monospace',
                        fontSize: 11,
                      ),
                      textAlign: TextAlign.left,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

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

class AppRootNavigator extends ConsumerStatefulWidget {
  const AppRootNavigator({super.key, required this.hasSelectedLanguage});

  final bool hasSelectedLanguage;

  @override
  ConsumerState<AppRootNavigator> createState() => _AppRootNavigatorState();
}

class _AppRootNavigatorState extends ConsumerState<AppRootNavigator> {
  late final AppLinks _appLinks;
  StreamSubscription<Uri>? _linkSubscription;

  @override
  void initState() {
    super.initState();
    _initDeepLinks();
  }

  @override
  void dispose() {
    _linkSubscription?.cancel();
    super.dispose();
  }

  Future<void> _initDeepLinks() async {
    _appLinks = AppLinks();

    try {
      final initialUri = await _appLinks.getInitialLink();
      if (initialUri != null) {
        _handleDeepLink(initialUri);
      }
    } catch (e) {
      debugPrint('Error getting initial deep link: $e');
    }

    _linkSubscription = _appLinks.uriLinkStream.listen(
      (uri) => _handleDeepLink(uri),
      onError: (err) {
        debugPrint('Error listening to deep links: $err');
      },
    );
  }

  void _handleDeepLink(Uri uri) {
    debugPrint('Received deep link: $uri');
    final context = NavigationService.navigatorKey.currentContext;
    if (context == null) return;

    final pathSegments = uri.pathSegments;
    if (pathSegments.isEmpty) return;

    final type = pathSegments[0].toLowerCase();
    if (type == 'product' && pathSegments.length > 1) {
      final productId = pathSegments[1];
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => ListingDetailView(listingId: productId)),
      );
    } else if (type == 'order' && pathSegments.length > 1) {
      final orderId = pathSegments[1];
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => OrderDetailView(orderId: orderId)),
      );
    } else if (type == 'user' && pathSegments.length > 1) {
      final userId = pathSegments[1];
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => UserProfileView(userId: userId)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider);

    // Flow 1: If language hasn't been chosen yet, show Language Selector
    if (!widget.hasSelectedLanguage) {
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
