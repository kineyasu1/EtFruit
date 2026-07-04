import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

final languageProvider = StateNotifierProvider<LanguageNotifier, Locale>((ref) {
  return LanguageNotifier();
});

class LanguageNotifier extends StateNotifier<Locale> {
  LanguageNotifier() : super(const Locale('en')) {
    _loadSavedLanguage();
  }

  static const String _prefKey = 'language_code';

  Future<void> _loadSavedLanguage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final code = prefs.getString(_prefKey);
      if (code != null) {
        state = Locale(code);
      }
    } catch (e) {
      debugPrint('Error loading saved language: $e');
    }
  }

  Future<void> setLocale(String languageCode) async {
    state = Locale(languageCode);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefKey, languageCode);
    } catch (e) {
      debugPrint('Error saving language: $e');
    }
  }
}
