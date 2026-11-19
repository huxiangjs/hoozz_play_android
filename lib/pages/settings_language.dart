///
/// Language selection page: follow system / English / Chinese.
///
/// The selection is persisted by the LocaleManager (shared_preferences);
/// applying it (a MaterialApp rebuild with the new locale) is done by the
/// app, which listens to the LocaleManager.
///

import 'package:flutter/material.dart';
import 'package:hoozz_play/core/locale_manager.dart';
import 'package:hoozz_play/l10n/app_localizations.dart';
import 'package:hoozz_play/themes/theme.dart';

class HoozzPlayLanguagePage extends StatefulWidget {
  const HoozzPlayLanguagePage({super.key});

  @override
  State<HoozzPlayLanguagePage> createState() => _HoozzPlayLanguagePageState();
}

class _HoozzPlayLanguagePageState extends State<HoozzPlayLanguagePage> {
  final LocaleManager _localeManager = LocaleManager.instance;

  @override
  void initState() {
    super.initState();
    // Rebuild when the selection changes (the RadioListTile highlights
    // move as soon as an option is tapped)
    _localeManager.addListener(_onLocaleChanged);
  }

  @override
  void dispose() {
    _localeManager.removeListener(_onLocaleChanged);
    super.dispose();
  }

  void _onLocaleChanged() {
    setState(() {});
  }

  Widget _generateItem(String value, String label) {
    return RadioListTile<String>(
      title: Text(
        label,
        style: const TextStyle(
          fontSize: 20,
          fontFamily: subFontFamily,
          fontWeight: FontWeight.bold,
          color: subTextColor,
        ),
      ),
      value: value,
      groupValue: _localeManager.selection,
      activeColor: mainFillColor,
      onChanged: (String? value) {
        if (value == null) return;
        _localeManager.setSelection(value);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.language)),
      body: Column(
        children: [
          const SizedBox(height: 10),
          _generateItem(LocaleManager.system, l10n.followSystem),
          _generateItem('en', l10n.languageEnglish),
          _generateItem('zh', l10n.languageChinese),
        ],
      ),
    );
  }
}
