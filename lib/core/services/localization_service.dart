import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

class LocalizationService {
  LocalizationService(
    String locale,
    Map<String, String> translations,
    Map<String, String> fallbackTranslations,
  ) : localeName = intl.Intl.canonicalizedLocale(locale.toString()),
      _translations = translations,
      _fallbackTranslations = fallbackTranslations;

  final String localeName;
  final Map<String, String> _translations;
  final Map<String, String> _fallbackTranslations;

  static LocalizationService? of(BuildContext context) {
    return Localizations.of<LocalizationService>(context, LocalizationService);
  }

  static const LocalizationsDelegate<LocalizationService> delegate =
      _LocalizationsDelegate();

  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('vi'),
  ];

  List<String> getList(String key) {
    final List<String> result = [];
    int index = 0;

    while (true) {
      final String itemKey = '$key.$index';
      final String? value =
          _translations[itemKey] ?? _fallbackTranslations[itemKey];

      if (value == null) break;

      result.add(value);
      index++;
    }

    return result;
  }

  String get(String key) {
    return _get(key);
  }

  String _get(String key) {
    return _translations[key] ?? _fallbackTranslations[key] ?? key;
  }
}

class _LocalizationsDelegate
    extends LocalizationsDelegate<LocalizationService> {
  const _LocalizationsDelegate();

  @override
  Future<LocalizationService> load(Locale locale) async {
    final String languageCode = locale.languageCode;
    final Map<String, String> translations = await _loadJsonMap(languageCode);
    final Map<String, String> fallback = languageCode == 'en'
        ? translations
        : await _loadJsonMap('en');
    return SynchronousFuture<LocalizationService>(
      LocalizationService(locale.toString(), translations, fallback),
    );
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'vi'].contains(locale.languageCode);

  @override
  bool shouldReload(_LocalizationsDelegate old) => false;
}

Future<Map<String, String>> _loadJsonMap(String languageCode) async {
  try {
    final String jsonString = await rootBundle.loadString(
      'assets/i18n/$languageCode.json',
    );
    final Map<String, dynamic> raw =
        json.decode(jsonString) as Map<String, dynamic>;
    final Map<String, String> flattened = <String, String>{};
    void flatten(String prefix, dynamic value) {
      if (value is Map<String, dynamic>) {
        value.forEach((String k, dynamic v) {
          final String newPrefix = prefix.isEmpty ? k : '$prefix.$k';
          flatten(newPrefix, v);
        });
      } else if (value is List) {
        for (int i = 0; i < value.length; i++) {
          final String newPrefix = '$prefix.$i';
          flatten(newPrefix, value[i]);
        }
      } else if (value != null) {
        flattened[prefix] = value.toString();
      }
    }

    flatten('', raw);
    return flattened;
  } catch (_) {
    return <String, String>{};
  }
}
