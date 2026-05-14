import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'app_constants.dart';

class LocalizationService extends ChangeNotifier {
  Locale _locale = Locale('ta'); // Default Tamil
  Map<String, String> _localizedStrings = {};

  Locale get locale => _locale;

  LocalizationService() {
    _loadSavedLanguage();
  }

  Future<void> _loadSavedLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    final String? languageCode = prefs.getString(AppConstants.keyLanguage);
    if (languageCode != null) {
      _locale = Locale(languageCode);
    }
    await load();
    notifyListeners();
  }

  Future<void> changeLanguage(Locale locale) async {
    _locale = locale;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(AppConstants.keyLanguage, locale.languageCode);
    await load();
    notifyListeners();
  }

  Future<void> load() async {
    try {
      String jsonString = await rootBundle.loadString(
        'assets/i18n/${_locale.languageCode}.json',
      );
      Map<String, dynamic> jsonMap = json.decode(jsonString);
      _localizedStrings = jsonMap.map(
        (key, value) => MapEntry(key, value.toString()),
      );
    } catch (e) {
      debugPrint('Error loading localization: $e');
      _localizedStrings = {};
    }
  }

  String translate(String key) {
    return _localizedStrings[key] ?? key;
  }
}
