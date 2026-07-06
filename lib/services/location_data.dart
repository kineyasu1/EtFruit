class LocationData {
  static const Map<String, Map<String, List<String>>> hierarchy = {
    'Addis Ababa': {
      'City Administration': ['Addis Ababa (Finfinnee)'],
    },
    'Dire Dawa': {
      'City Administration': ['Dire Dawa'],
    },
    'Oromia Region': {
      'Capitals': ['Addis Ababa (Finfinnee)'],
      'Major Cities': [
        'Adama (Nazret)',
        'Jimma',
        'Bishoftu (Debre Zeyit)',
        'Shashemene',
        'Nekemte',
        'Asella',
        'Robe',
      ],
    },
    'Amhara Region': {
      'Capitals': ['Bahir Dar'],
      'Major Cities': [
        'Gondar',
        'Dessie',
        'Kombolcha',
        'Debre Berhan',
        'Weldiya',
        'Debre Markos',
      ],
    },
    'Tigray Region': {
      'Capitals': ['Mek\'ele'],
      'Major Cities': [
        'Adigrat',
        'Shire (Inda Selassie)',
        'Axum',
        'Alamata',
        'Humera',
      ],
    },
    'Somali Region': {
      'Capitals': ['Jijiga'],
      'Major Cities': ['Gode', 'Kebri Dahar', 'Degehabur', 'Warder'],
    },
    'Sidama Region': {
      'Capitals': ['Hawassa'],
      'Major Cities': ['Yirgalem', 'Aleta Wendo', 'Leku'],
    },
    'South Ethiopia Regional State': {
      'Capitals': ['Wolaita Sodo'],
      'Major Cities': ['Arba Minch', 'Dilla', 'Jinka', 'Sawla'],
    },
    'Central Ethiopia Regional State': {
      'Capitals': ['Hosaina'],
      'Major Cities': ['Butajira', 'Welkite', 'Alaba Kulito', 'Durame'],
    },
    'South West Ethiopia Peoples\' Region': {
      'Capitals': ['Bonga'],
      'Major Cities': ['Mizan Teferi', 'Tippi', 'Tercha'],
    },
    'Afar Region': {
      'Capitals': ['Semera'],
      'Major Cities': ['Logia', 'Asaita', 'Awash', 'Gewane'],
    },
    'Benishangul-Gumuz Region': {
      'Capitals': ['Asosa'],
      'Major Cities': ['Gilgel Beles', 'Kamashi', 'Metekel'],
    },
    'Gambela Region': {
      'Capitals': ['Gambela'],
      'Major Cities': ['Itang', 'Abobo', 'Fugnido'],
    },
    'Harari Region': {
      'Capitals & Cities': ['Harar'],
    },
  };

  static List<String> getRegions() {
    return hierarchy.keys.toList();
  }

  static List<String> getZones(String region) {
    if (!hierarchy.containsKey(region)) return [];
    return hierarchy[region]!.keys.toList();
  }

  static List<String> getWoredas(String region, String zone) {
    if (!hierarchy.containsKey(region)) return [];
    if (!hierarchy[region]!.containsKey(zone)) return [];
    return hierarchy[region]![zone]!;
  }
}
