class LocationData {
  static const Map<String, Map<String, List<String>>> hierarchy = {
    'Addis Ababa': {
      'Bole Sub-City': ['Bole Woreda 01', 'Bole Woreda 02', 'Bole Woreda 03'],
      'Yeka Sub-City': ['Yeka Woreda 01', 'Yeka Woreda 02'],
      'Kirkos Sub-City': ['Kirkos Woreda 01', 'Kirkos Woreda 02'],
    },
    'Oromia': {
      'East Shewa': ['Adama', 'Bishoftu', 'Mojo', 'Batu'],
      'West Shewa': ['Ambo', 'Guder', 'Ginchi'],
      'Jimma': ['Jimma City', 'Gomma Woreda', 'Limmu Seka'],
      'East Hararghe': ['Haramaya', 'Chiro', 'Babille'],
    },
    'Amhara': {
      'West Gojjam': ['Bahir Dar', 'Merawi', 'Finote Selam'],
      'South Wollo': ['Dessie', 'Kombolcha', 'Kalu'],
      'North Gondar': ['Gondar City', 'Debark', 'Dabat'],
      'East Gojjam': ['Debre Markos', 'Bichena'],
    },
    'Tigray': {
      'Mekelle Zone': ['Mekelle City', 'Ayder', 'Kedamay Weyane'],
      'Eastern Zone': ['Adigrat', 'Wukro', 'Bizet'],
      'North Western': ['Shire Indaselassie', 'Sheraro'],
      'Central Zone': ['Axum City', 'Adwa City'],
    },
    'Somali': {
      'Fafan (Jigjiga)': ['Jigjiga City', 'Babilli Woreda', 'Gursum'],
      'Sitti': ['Shinile', 'Erer'],
      'Shabelle': ['Gode City', 'Kelafo'],
    },
    'Sidama': {
      'Hawassa Zone': ['Hawassa City', 'Hawassa Zuria'],
      'Aleta Wondo': ['Wondo City', 'Aleta Wondo Woreda'],
    },
    'Afar': {
      'Zone 1 (Awusi Rasu)': ['Semera', 'Asaita', 'Dubti'],
      'Zone 3 (Gabi Rasu)': ['Awash Sub-basin', 'Gewane'],
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
