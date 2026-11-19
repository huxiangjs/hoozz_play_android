///
/// App-wide locale selection (shared_preferences-persisted).
///
/// The selection is one of 'system' / 'en' / 'zh'. 'system' follows the
/// OS locale (MaterialApp.locale is then null); the other two apply an
/// explicit locale. A ChangeNotifier: the app (and any listening widget)
/// rebuilds when the selection changes.
///

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocaleManager extends ChangeNotifier {
  static final LocaleManager instance = LocaleManager._();

  LocaleManager._();

  static const String _storageKey = 'app_locale';
  static const String system = 'system';

  SharedPreferences? _prefs;
  String _selection = system;

  // The current selection ('system' / 'en' / 'zh')
  String get selection => _selection;

  // The locale to apply to the MaterialApp: null = follow the system
  Locale? get locale => _selection == system ? null : Locale(_selection);

  Future<void> load() async {
    _prefs = await SharedPreferences.getInstance();
    _selection = _prefs!.getString(_storageKey) ?? system;
    notifyListeners();
  }

  Future<void> setSelection(String selection) async {
    if (selection == _selection) return;
    _selection = selection;
    notifyListeners();
    _prefs ??= await SharedPreferences.getInstance();
    await _prefs!.setString(_storageKey, selection);
  }
}
