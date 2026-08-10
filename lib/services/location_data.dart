class LocationData {
  static const Map<String, Map<String, List<String>>> hierarchy = {
    'Addis Ababa': {
      'Sub-Cities': [
        'Addis Ketema',
        'Akaki Kality',
        'Arada',
        'Bole',
        'Gullele',
        'Kirkos',
        'Kolfe Keranio',
        'Lemi Kura',
        'Lideta',
        'Nifas Silk-Lafto',
        'Yeka'
      ],
    },
    'Afar Region': {
      'Zone 1 (Awusi Rasu)': ['Asaita', 'Chifra', 'Dubti', 'Elidar', 'Kori', 'Mille', 'Semera'],
      'Zone 2 (Kilbet Rasu)': ['Abala', 'Afdera', 'Berhale', 'Dallol', 'Erebti', 'Koneba'],
      'Zone 3 (Gabi Rasu)': ['Amibara', 'Awash Fentale', 'Bure Mudaytu', 'Dewe', 'Gewane'],
      'Zone 4 (Fantena Rasu)': ['Ewa', 'Gulina', 'Yalo'],
      'Zone 5 (Hari Rasu)': ['Dewi', 'Dulecha', 'Telalak'],
    },
    'Amhara Region': {
      'Awi': ['Chagni', 'Dangila', 'Injibara', 'Kossoye'],
      'East Gojjam': ['Bichena', 'Debre Markos', 'Dejen', 'Motta'],
      'North Gondar': ['Dabat', 'Debark', 'Gondar Zuria'],
      'North Shewa (Amhara)': ['Ankober', 'Ataye', 'Debre Berhan', 'Shewarobit'],
      'North Wollo': ['Kobo', 'Lalibela', 'Meket', 'Weldiya'],
      'Oromia Special Zone': ['Bati', 'Jille Timuga', 'Kemise'],
      'South Gondar': ['Debre Tabor', 'Lay Gayint', 'Nefas Mewcha', 'Woreta'],
      'South Wollo': ['Dessie', 'Hayq', 'Kombolcha', 'Tehuledere'],
      'Wag Hemra': ['Dehana', 'Sekota', 'Zaquala'],
      'West Gojjam': ['Bahar Dar Zuria', 'Dembacha', 'Finote Selam', 'Jiga'],
    },
    'Benishangul-Gumuz Region': {
      'Asosa': ['Asosa', 'Bambasi', 'Kurmuk', 'Sherkole'],
      'Kamashi': ['Kamashi', 'Oda Buldigilu', 'Yaso'],
      'Metekel': ['Bulen', 'Gilgel Beles', 'Guba', 'Mandura'],
    },
    'Central Ethiopia Regional State': {
      'Gurage': ['Agena', 'Butajira', 'Endibir', 'Welkite'],
      'Hadiya': ['Gimbichu', 'Hosaina', 'Limo', 'Shone'],
      'Halaba': ['Halaba Kulito', 'Wera'],
      'Kembata Tembaro': ['Angacha', 'Durame', 'Shinshicho'],
      'Silte': ['Kibet', 'Sankura', 'Tora', 'Worabe'],
    },
    'Dire Dawa': {
      'Administration': ['Dire Dawa Town', 'Gurgura', 'Melka Jebdu'],
    },
    'Gambela Region': {
      'Anywaa': ['Abobo', 'Gambela Town', 'Gog', 'Itang'],
      'Majang': ['Mennesha', 'Meti'],
      'Nuer': ['Akobo', 'Jikow', 'Lare', 'Wanthoa'],
    },
    'Harari Region': {
      'Administration': ['Arfan Kalle', 'Erer', 'Harar Town', 'Sofi'],
    },
    'Oromia Region': {
      'Arsi': ['Asella', 'Bekoji', 'Kofele', 'Sagure'],
      'Bale': ['Agarfa', 'Goba', 'Robe', 'Sinana'],
      'Borena': ['Mega', 'Moyale', 'Yabelo'],
      'East Hararghe': ['Babili', 'Dadgata', 'Harar Zuria', 'Kersa'],
      'East Shewa': ['Adama (Nazret)', 'Batu (Ziway)', 'Bishoftu (Debre Zeyit)', 'Dera', 'Mojo'],
      'East Wollega': ['Bako', 'Gimbi', 'Nekemte'],
      'Guji': ['Adola (Kibre Mengist)', 'Negele Borena', 'Shakisso'],
      'Illubabor': ['Bedele', 'Hurumu', 'Metu', 'Yayu'],
      'Jimma': ['Agaro', 'Jimma Town', 'Limmu Genet', 'Sekoru'],
      'North Shewa (Oromia)': ['Chancho', 'Fitche', 'Gerba Guracha', 'Sendafa'],
      'South West Shewa': ['Harbu Chulul', 'Tulu Bolo', 'Wolisso'],
      'West Arsi': ['Adaba', 'Dodola', 'Kofele', 'Shashemene'],
      'West Guji': ['Bule Hora', 'Hagere Mariam'],
      'West Hararghe': ['Bedessa', 'Chiro (Asebe Teferi)', 'Gelemso', 'Hirna'],
      'West Shewa': ['Ambo', 'Ginci', 'Guder', 'Wolisso'],
      'West Wollega': ['Dembidolo', 'Gimbi', 'Mendi'],
    },
    'Sidama Region': {
      'Hawassa': ['Hawassa City', 'Hawassa Zuria'],
      'Sidama Zone': ['Aleta Wendo', 'Dila', 'Hula', 'Leku', 'Yirgalem'],
    },
    'Somali Region': {
      'Afder': ['Bare', 'Elkere', 'Hargele'],
      'Fafan': ['Babili', 'Gabile', 'Jijiga', 'Warder'],
      'Liben': ['Dolo Odo', 'Filtu', 'Moyale'],
      'Shabelle': ['Gode', 'Kelafo', 'Mustahil'],
      'Sitti': ['Afdem', 'Erer', 'Shinile'],
    },
    'South Ethiopia Regional State': {
      'Gamo': ['Arba Minch', 'Chencha', 'Mirab Abaya'],
      'Gofa': ['Bulki', 'Sawla'],
      'Segen Area': ['Amaro', 'Darashe', 'Konso'],
      'South Omo': ['Jinka', 'Key Afer', 'Turmi'],
      'Wolayta': ['Areka', 'Boditi', 'Gununo', 'Wolaita Sodo'],
    },
    'South West Ethiopia Peoples\' Region': {
      'Bench Sheko': ['Aman', 'Mizan Teferi', 'Shena'],
      'Dawro': ['Loma', 'Tercha', 'Waka'],
      'Keffa': ['Bonga', 'Chenna', 'Gimbo'],
      'Kontas': ['Ameya'],
      'Sheka': ['Anderacha', 'Masha', 'Tippi'],
    },
    'Tigray Region': {
      'Central': ['Adwa', 'Abiy Addi', 'Axum'],
      'Eastern': ['Adigrat', 'Atsbi', 'Wukro'],
      'Mekelle': ['Mekelle Town', 'Quiha'],
      'North Western': ['Sheraro', 'Shire (Inda Selassie)'],
      'North Eastern': ['Adigrat', 'Bizan'],
      'Southern': ['Alamata', 'Maichew', 'Mehoni'],
      'Western': ['Humera', 'Wolkayt', 'Tsegede'],
    },
  };

  static List<String> getRegions() {
    final list = hierarchy.keys.toList();
    list.sort();
    return list;
  }

  static List<String> getZones(String region) {
    if (!hierarchy.containsKey(region)) return [];
    final list = hierarchy[region]!.keys.toList();
    list.sort();
    return list;
  }

  static List<String> getWoredas(String region, String zone) {
    if (!hierarchy.containsKey(region)) return [];
    if (!hierarchy[region]!.containsKey(zone)) return [];
    final list = List<String>.from(hierarchy[region]![zone]!);
    list.sort();
    return list;
  }
}
