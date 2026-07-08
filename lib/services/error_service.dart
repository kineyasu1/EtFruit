import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';

class ErrorService {
  /// Simple logging system for debugging exceptions
  static void log(dynamic error, [StackTrace? stackTrace]) {
    debugPrint('[ERROR] ${DateTime.now().toIso8601String()}: $error');
    if (stackTrace != null) {
      debugPrint(stackTrace.toString());
    }
  }

  /// Parses any exception type and returns a localized, user-friendly string
  static String getReadableError(BuildContext context, dynamic error) {
    log(error);

    // Retrieve active locale code
    String localeCode = 'en';
    try {
      localeCode = Localizations.localeOf(context).languageCode;
    } catch (_) {
      // Fallback to English if Context does not have localized info
    }

    String errorCode = 'unknown';

    if (error is FirebaseException) {
      errorCode = error.code;
    } else {
      final errorStr = error.toString().toLowerCase();
      if (errorStr.contains('socketexception') || 
          errorStr.contains('network') || 
          errorStr.contains('failed host lookup')) {
        errorCode = 'network-error';
      } else if (errorStr.contains('timeout')) {
        errorCode = 'timeout';
      } else if (errorStr.contains('wrong-password') || errorStr.contains('wrong password')) {
        errorCode = 'wrong-password';
      } else if (errorStr.contains('user-not-found') || errorStr.contains('user not found')) {
        errorCode = 'user-not-found';
      } else if (errorStr.contains('user-already-exists') || 
                 errorStr.contains('user already exists') || 
                 errorStr.contains('already-in-use')) {
        errorCode = 'user-already-exists';
      }
    }

    return _getLocalizedMessage(localeCode, errorCode);
  }

  /// Maps the errorCode to the corresponding localized translation
  static String _getLocalizedMessage(String locale, String errorCode) {
    final Map<String, Map<String, String>> localizedDictionary = {
      'en': {
        'network-error': 'Internet connection issue. Please check your network and try again.',
        'timeout': 'Connection timeout. Please try again.',
        'user-not-found': 'No account exists for this phone number.',
        'wrong-password': 'Incorrect password. Please try again.',
        'user-already-exists': 'An account already exists for this phone number.',
        'too-many-requests': 'Too many requests. Please try again later.',
        'weak-password': 'Password is too weak. Please use a stronger password.',
        'permission-denied': 'You do not have permission to perform this action.',
        'unknown': 'An unexpected error occurred. Please try again.',
      },
      'am': {
        'network-error': 'የኢንተርኔት ግንኙነት ችግር። እባክዎን ኔትወርክዎን ፈትሸው እንደገና ይሞክሩ።',
        'timeout': 'የግንኙነት ጊዜ አልፏል። እባክዎ እንደገና ይሞክሩ።',
        'user-not-found': 'ለዚህ ስልክ ቁጥር የተመዘገበ አካውንት የለም።',
        'wrong-password': 'ትክክለኛ ያልሆነ የይለፍ ቃል፤ እባክዎ እንደገና ይሞክሩ።',
        'user-already-exists': 'በዚህ ስልክ ቁጥር ቀድሞ የተመዘገበ አካውንት አለ።',
        'too-many-requests': 'በጣም ብዙ ሙከራዎች ተደርገዋል። እባክዎ ቆይተው እንደገና ይሞክሩ።',
        'weak-password': 'ደካማ የይለፍ ቃል። እባክዎ ጠንከር ያለ የይለፍ ቃል ይጠቀሙ።',
        'permission-denied': 'ይህንን ተግባር ለማከናወን ፈቃድ የለዎትም።',
        'unknown': 'ያልተጠበቀ ስህተት አጋጥሟል። እባክዎ እንደገና ይሞክሩ።',
      },
      'om': {
        'network-error': 'Rakkaataa qunnamtii interneetii. Maaloo networkii keessan mirkaneessaa deebisaatii yaalaa.',
        'timeout': 'Yeroon qunnamtii darbeera. Maaloo irra deebitanii yaalaa.',
        'user-not-found': 'Lakkoofsa bilbilaa kanaan herregni baname hin jiru.',
        'wrong-password': 'Jecha icciitii sirrii hin taane. Maaloo irra deebitanii yaalaa.',
        'user-already-exists': 'Lakkoofsa bilbilaa kanaan herregni duraan baname jira.',
        'too-many-requests': 'Yaalii baay\'ee gootaniittu. Maaloo yeroo booda yaalaa.',
        'weak-password': 'Jecha icciitii laafaa. Maaloo jecha icciitii cimaa fayyadamaa.',
        'permission-denied': 'Gocha kana raawwachuuf heyamamu hin qabdan.',
        'unknown': 'Rakkaataa hin eegamne uumame. Maaloo irra deebitanii yaalaa.',
      },
      'so': {
        'network-error': 'Cillad dhanka internetka ah. Fadlan hubi khadkaaga internetka markalana isku day.',
        'timeout': 'Waqtiga xiriirka waa dhamaaday. Fadlan markale isku day.',
        'user-not-found': 'Wax xisaab ah oo ku diwaan gashan lambarkaan ma jiro.',
        'wrong-password': 'Hasaaraha sirta ah oo khaldan. Fadlan markale isku day.',
        'user-already-exists': 'Xisaab horay u jirtay ayaa ku diwaan gashan lambarkaan.',
        'too-many-requests': 'Isku dayo aad u badan ayaa dhacay. Fadlan dib ka isku day.',
        'weak-password': 'Hasaaraha sirta ah waa mid daciif ah. Fadlan mid ka adag isticmaal.',
        'permission-denied': 'Fadlan ma haysatid ogolaansho aad ku samayso hawshaan.',
        'unknown': 'Cillad aan la fileyn ayaa dhacday. Fadlan markale isku day.',
      },
      'ti': {
        'network-error': 'ጸገም ርክብ ኢንተርኔት። በጃኹም ኔትወርክኹም መርሚርኩም ድሕሪ ሕጂ ፈትኑ።',
        'timeout': 'እቲ ናይ ርክብ እዋን ሓሊፉ እዩ። በጃኹም ድሕሪ ሕጂ ፈትኑ።',
        'user-not-found': 'በዚ ቑፅሪ ቴሌፎን ዝተመዝገበ ኣካውንት የለን።',
        'wrong-password': 'ልክዕ ዘይኮነ መሕለፊ ቓል። በጃኹም ድሕሪ ሕጂ ፈትኑ።',
        'user-already-exists': 'በዚ ቑፅሪ ቴሌፎን ቅድሚ ሕጂ ዝተመዝገበ ኣካውንት ኣሎ።',
        'too-many-requests': 'ብዙሕ ፈተነታት ተገይሩ እዩ። በጃኹም ጸኒሕኩም ድሕሪ ሕጂ ፈትኑ።',
        'weak-password': 'ድኹም መሕለፊ ቃል እዩ። በጃኹም ዝሓየለ መሕለፊ ቃል ተጠቐሙ።',
        'permission-denied': 'ነዚ ተግባር ንምፍጻም ፍቓድ የብልኩምን።',
        'unknown': 'ዘይተጸበናዮ ጌጋ ኣጋጢሙ ኣሎ። በጃኹም ድሕሪ ሕጂ ፈትኑ።',
      }
    };

    // Pick translation dictionary for language (fallback to English if unsupported)
    final dict = localizedDictionary[locale] ?? localizedDictionary['en']!;
    
    // Pick mapped string or fallback to generic unknown error
    return dict[errorCode] ?? dict['unknown']!;
  }
}
