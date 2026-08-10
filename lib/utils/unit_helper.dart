import 'package:flutter/material.dart';

class UnitHelper {
  static String getLocalizedUnit(BuildContext context, String? unit) {
    if (unit == null || unit.isEmpty) return '';
    final lang = Localizations.localeOf(context).languageCode;
    final lower = unit.toLowerCase().trim();

    final Map<String, Map<String, String>> unitTranslations = {
      'quintal': {
        'en': 'quintal',
        'am': 'ኩንታል',
        'om': 'Kuntaala',
        'so': 'Kuntaal',
        'ti': 'ኩንታል',
      },
      'kg': {
        'en': 'kg',
        'am': 'ኪሎግራም',
        'om': 'Kiilograama',
        'so': 'Kiiloogram',
        'ti': 'ኪሎግራም',
      },
      'liter': {
        'en': 'liter',
        'am': 'ሊትር',
        'om': 'Liitira',
        'so': 'Liitar',
        'ti': 'ሊትር',
      },
      'box': {
        'en': 'box',
        'am': 'ሳጥን',
        'om': 'Saandoqii',
        'so': 'Sanduuq',
        'ti': 'ሳንዱቕ',
      },
      'bag': {
        'en': 'bag',
        'am': 'ጆንያ',
        'om': 'Dawaa',
        'so': 'Boorsa',
        'ti': 'ኒሸታ',
      },
      'piece': {
        'en': 'piece',
        'am': 'ፍሬ',
        'om': 'Qooda',
        'so': 'Xabado',
        'ti': 'ፍረ',
      },
      'crate': {
        'en': 'crate',
        'am': 'ካርቶን',
        'om': 'Kaartonii',
        'so': 'Kaartoon',
        'ti': 'ካርቶን',
      },
      'ton': {
        'en': 'ton',
        'am': 'ቶን',
        'om': 'Toonii',
        'so': 'Tan',
        'ti': 'ቶን',
      },
      'head': {
        'en': 'head',
        'am': 'ራስ',
        'om': 'Mataa',
        'so': 'Neefer',
        'ti': 'ርእሲ',
      },
    };

    if (unitTranslations.containsKey(lower)) {
      return unitTranslations[lower]![lang] ?? unitTranslations[lower]!['en']!;
    }
    return unit;
  }
}
