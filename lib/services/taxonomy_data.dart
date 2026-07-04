class TaxonomyCategory {
  final String id;
  final Map<String, String> names;
  final List<String> suggestedUnits;

  const TaxonomyCategory({
    required this.id,
    required this.names,
    required this.suggestedUnits,
  });

  String getName(String languageCode) {
    return names[languageCode] ?? names['en'] ?? id;
  }
}

class TaxonomyProduct {
  final String id;
  final String categoryId;
  final Map<String, String> names;
  final String suggestedUnit;

  const TaxonomyProduct({
    required this.id,
    required this.categoryId,
    required this.names,
    required this.suggestedUnit,
  });

  String getName(String languageCode) {
    return names[languageCode] ?? names['en'] ?? id;
  }
}

class TaxonomyData {
  static const List<TaxonomyCategory> categories = [
    TaxonomyCategory(
      id: 'cereals_grains',
      suggestedUnits: ['quintal', 'kg'],
      names: {
        'en': 'Cereals & Grains',
        'am': 'እህል እና ጥራጥሬዎች',
        'om': 'Midhaan',
        'so': 'Mishaarka & Firileyda',
        'ti': 'ጥረታት',
      },
    ),
    TaxonomyCategory(
      id: 'pulses_oilseeds',
      suggestedUnits: ['quintal', 'kg'],
      names: {
        'en': 'Pulses & Oilseeds',
        'am': 'የቅባት እህሎች እና ባቄላዎች',
        'om': 'Kuduraa fi Muka',
        'so': 'Saliidaha & Digirta',
        'ti': 'ጥረታት ዘይቲ',
      },
    ),
    TaxonomyCategory(
      id: 'coffee_cash_crops',
      suggestedUnits: ['kg', 'quintal', 'crate'],
      names: {
        'en': 'Coffee & Cash Crops',
        'am': 'ቡና እና የገንዘብ ሰብሎች',
        'om': 'Buna fi Oomishaalee Gabaa',
        'so': 'Bunka & Dalagyada Lacagta',
        'ti': 'ቡናን ካልኦት ዘፈርን',
      },
    ),
    TaxonomyCategory(
      id: 'vegetables',
      suggestedUnits: ['kg', 'crate', 'sack'],
      names: {
        'en': 'Vegetables',
        'am': 'አትክልቶች',
        'om': 'Muduraa',
        'so': 'Khudaarta',
        'ti': 'ኣሕምልቲ',
      },
    ),
    TaxonomyCategory(
      id: 'fruits',
      suggestedUnits: ['kg', 'crate', 'piece'],
      names: {
        'en': 'Fruits',
        'am': 'ፍራፍሬዎች',
        'om': 'Fuduraalee',
        'so': 'Miroha',
        'ti': 'ፍራፍረታት',
      },
    ),
    TaxonomyCategory(
      id: 'livestock',
      suggestedUnits: ['head'],
      names: {
        'en': 'Livestock',
        'am': 'ከብት እና እንስሳት',
        'om': 'Horii',
        'so': 'Xoolaha',
        'ti': 'ኸብቲ',
      },
    ),
    TaxonomyCategory(
      id: 'dairy_animal_products',
      suggestedUnits: ['liter', 'kg', 'piece', 'crate'],
      names: {
        'en': 'Dairy & Animal Products',
        'am': 'የወተት እና የእንስሳት ተዋጽኦዎች',
        'om': 'Aanan fi Oomisha Hori',
        'so': 'Caanaha & Waxyaabaha Xoolaha',
        'ti': 'ፍርያት ጸባን ከብትን',
      },
    ),
  ];

  static const List<TaxonomyProduct> products = [
    // Cereals & Grains
    TaxonomyProduct(
      id: 'teff',
      categoryId: 'cereals_grains',
      suggestedUnit: 'quintal',
      names: {'en': 'Teff', 'am': 'ጤፍ', 'om': 'Xaafii', 'so': 'Teff', 'ti': 'ጣፍ'},
    ),
    TaxonomyProduct(
      id: 'wheat',
      categoryId: 'cereals_grains',
      suggestedUnit: 'quintal',
      names: {'en': 'Wheat', 'am': 'ስንዴ', 'om': 'Kamadii', 'so': 'Qamadi', 'ti': 'ስርናይ'},
    ),
    TaxonomyProduct(
      id: 'maize',
      categoryId: 'cereals_grains',
      suggestedUnit: 'quintal',
      names: {'en': 'Maize (Corn)', 'am': 'በቆሎ', 'om': 'Baqqollo', 'so': 'Gelay', 'ti': 'ዕፉን'},
    ),
    TaxonomyProduct(
      id: 'barley',
      categoryId: 'cereals_grains',
      suggestedUnit: 'quintal',
      names: {'en': 'Barley', 'am': 'ገብስ', 'om': 'Garbuu', 'so': 'Shaciir', 'ti': 'ስገም'},
    ),
    TaxonomyProduct(
      id: 'sorghum',
      categoryId: 'cereals_grains',
      suggestedUnit: 'quintal',
      names: {'en': 'Sorghum', 'am': 'ማሽላ', 'om': 'Misingaa', 'so': 'Masago', 'ti': 'መሸላ'},
    ),
    TaxonomyProduct(
      id: 'rice',
      categoryId: 'cereals_grains',
      suggestedUnit: 'quintal',
      names: {'en': 'Rice', 'am': 'ሩዝ', 'om': 'Ruuzii', 'so': 'Bariis', 'ti': 'ሩዝ'},
    ),

    // Pulses & Oilseeds
    TaxonomyProduct(
      id: 'chickpeas',
      categoryId: 'pulses_oilseeds',
      suggestedUnit: 'quintal',
      names: {'en': 'Chickpeas', 'am': 'ሽምብራ', 'om': 'Shumburaa', 'so': 'Digir shimbir', 'ti': 'ዓተር'},
    ),
    TaxonomyProduct(
      id: 'lentils',
      categoryId: 'pulses_oilseeds',
      suggestedUnit: 'quintal',
      names: {'en': 'Lentils', 'am': 'ምስር', 'om': 'Misira', 'so': 'Misir', 'ti': 'ብርሽን'},
    ),
    TaxonomyProduct(
      id: 'faba_beans',
      categoryId: 'pulses_oilseeds',
      suggestedUnit: 'quintal',
      names: {'en': 'Faba Beans', 'am': 'ባቄላ', 'om': 'Baqelaa', 'so': 'Kaluun', 'ti': 'ባሊና'},
    ),
    TaxonomyProduct(
      id: 'sesame',
      categoryId: 'pulses_oilseeds',
      suggestedUnit: 'quintal',
      names: {'en': 'Sesame', 'am': 'ሰሊጥ', 'om': 'Saliita', 'so': 'Sanjabiil', 'ti': 'ሰሊጥ'},
    ),
    TaxonomyProduct(
      id: 'niger_seed',
      categoryId: 'pulses_oilseeds',
      suggestedUnit: 'quintal',
      names: {'en': 'Niger Seed (Nug)', 'am': 'ኑግ', 'om': 'Nuugii', 'so': 'Nug', 'ti': 'ኑግ'},
    ),

    // Coffee & Cash Crops
    TaxonomyProduct(
      id: 'coffee_green',
      categoryId: 'coffee_cash_crops',
      suggestedUnit: 'kg',
      names: {'en': 'Coffee (Green Beans)', 'am': 'ቡና (ጥሬ)', 'om': 'Buna Dheedhi', 'so': 'Bun cagaar', 'ti': 'ቡና (ጥረ)'},
    ),
    TaxonomyProduct(
      id: 'coffee_cherry',
      categoryId: 'coffee_cash_crops',
      suggestedUnit: 'kg',
      names: {'en': 'Coffee (Cherry)', 'am': 'ቡና (ፍሬ)', 'om': 'Buna Nyara', 'so': 'Bun cherry', 'ti': 'ቡና (ጭሪ)'},
    ),
    TaxonomyProduct(
      id: 'chat',
      categoryId: 'coffee_cash_crops',
      suggestedUnit: 'kg',
      names: {'en': 'Chat (Khat)', 'am': 'ጫት', 'om': 'Caatii', 'so': 'Qaad (Khat)', 'ti': 'ጫት'},
    ),
    TaxonomyProduct(
      id: 'sugarcane',
      categoryId: 'coffee_cash_crops',
      suggestedUnit: 'piece',
      names: {'en': 'Sugarcane', 'am': 'ሸንኮራ አገዳ', 'om': 'Shankoraa', 'so': 'Kassab', 'ti': 'ሽኮር ኣገዳ'},
    ),

    // Vegetables
    TaxonomyProduct(
      id: 'onion',
      categoryId: 'vegetables',
      suggestedUnit: 'quintal',
      names: {'en': 'Onion', 'am': 'ሽንኩርት (ቀይ)', 'om': 'Qullubbii Diimaa', 'so': 'Basal', 'ti': 'ቀይሕ ሽጉርቲ'},
    ),
    TaxonomyProduct(
      id: 'tomato',
      categoryId: 'vegetables',
      suggestedUnit: 'crate',
      names: {'en': 'Tomato', 'am': 'ቲማቲም', 'om': 'Timaatimi', 'so': 'Yaanyo', 'ti': 'ኮሚደረ'},
    ),
    TaxonomyProduct(
      id: 'potato',
      categoryId: 'vegetables',
      suggestedUnit: 'sack',
      names: {'en': 'Potato', 'am': 'ድንች', 'om': 'Dinicha', 'so': 'Baradhada', 'ti': 'ድንች'},
    ),
    TaxonomyProduct(
      id: 'garlic',
      categoryId: 'vegetables',
      suggestedUnit: 'kg',
      names: {'en': 'Garlic', 'am': 'ነጭ ሽንኩርት', 'om': 'Qullubbii Addii', 'so': 'Toom', 'ti': 'ጻዕዳ ሽጉርቲ'},
    ),
    TaxonomyProduct(
      id: 'pepper',
      categoryId: 'vegetables',
      suggestedUnit: 'kg',
      names: {'en': 'Green/Red Pepper', 'am': 'ቃሪያ / በርበሬ', 'om': 'Mimmixa', 'so': 'Basbaas', 'ti': 'በርበረ'},
    ),

    // Fruits
    TaxonomyProduct(
      id: 'banana',
      categoryId: 'fruits',
      suggestedUnit: 'crate',
      names: {'en': 'Banana', 'am': 'ሙዝ', 'om': 'Muuzii', 'so': 'Moos', 'ti': 'ሙዝ'},
    ),
    TaxonomyProduct(
      id: 'avocado',
      categoryId: 'fruits',
      suggestedUnit: 'crate',
      names: {'en': 'Avocado', 'am': 'አቮካዶ', 'om': 'Avokaadoo', 'so': 'Avocado', 'ti': 'አቮካዶ'},
    ),
    TaxonomyProduct(
      id: 'mango',
      categoryId: 'fruits',
      suggestedUnit: 'crate',
      names: {'en': 'Mango', 'am': 'ማንጎ', 'om': 'Maangoo', 'so': 'Cambe', 'ti': 'ማንጎ'},
    ),

    // Livestock
    TaxonomyProduct(
      id: 'cattle',
      categoryId: 'livestock',
      suggestedUnit: 'head',
      names: {'en': 'Cattle (Cows/Bulls)', 'am': 'ከብት (ላም/ኮርማ)', 'om': 'Sa’a fi Kormaa', 'so': 'Lo\'da', 'ti': 'ከብቲ (ላምን በትሪን)'},
    ),
    TaxonomyProduct(
      id: 'goats',
      categoryId: 'livestock',
      suggestedUnit: 'head',
      names: {'en': 'Goats', 'am': 'ፍየል', 'om': 'Re’ee', 'so': 'Riyaha', 'ti': 'ጤል'},
    ),
    TaxonomyProduct(
      id: 'sheep',
      categoryId: 'livestock',
      suggestedUnit: 'head',
      names: {'en': 'Sheep', 'am': 'በግ', 'om': 'Hoolaa', 'so': 'Idaha', 'ti': 'በጊዕ'},
    ),
    TaxonomyProduct(
      id: 'poultry',
      categoryId: 'livestock',
      suggestedUnit: 'head',
      names: {'en': 'Poultry (Chicken)', 'am': 'ዶሮ', 'om': 'Lukkuu', 'so': 'Digaag', 'ti': 'ደርሆ'},
    ),
    TaxonomyProduct(
      id: 'beehives_honey',
      categoryId: 'livestock',
      suggestedUnit: 'kg',
      names: {'en': 'Honey', 'am': 'ማር', 'om': 'Damma', 'so': 'Malab', 'ti': 'መዓር'},
    ),

    // Dairy & Animal Products
    TaxonomyProduct(
      id: 'milk',
      categoryId: 'dairy_animal_products',
      suggestedUnit: 'liter',
      names: {'en': 'Milk', 'am': 'ወተት', 'om': 'Aanan', 'so': 'Cano', 'ti': 'ጸባ'},
    ),
    TaxonomyProduct(
      id: 'butter',
      categoryId: 'dairy_animal_products',
      suggestedUnit: 'kg',
      names: {'en': 'Butter', 'am': 'ቅቤ', 'om': 'Dhadhaa', 'so': 'Subag', 'ti': 'ጠስሚ'},
    ),
    TaxonomyProduct(
      id: 'eggs',
      categoryId: 'dairy_animal_products',
      suggestedUnit: 'crate',
      names: {'en': 'Eggs', 'am': 'እንቁላል', 'om': 'Hanqaaquu', 'so': 'Ukun', 'ti': 'እንቋቑሖ'},
    ),
  ];

  static List<TaxonomyProduct> getProductsByCategory(String categoryId) {
    return products.where((p) => p.categoryId == categoryId).toList();
  }
}
