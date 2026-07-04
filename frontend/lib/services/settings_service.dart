import 'package:flutter/material.dart';
import 'package:hive/hive.dart';

class SettingsService extends ChangeNotifier {
  final Box _box = Hive.box('settings_box');

  ThemeMode get themeMode {
    final val = _box.get('theme', defaultValue: 'system');
    if (val == 'light') return ThemeMode.light;
    if (val == 'dark') return ThemeMode.dark;
    return ThemeMode.system;
  }

  String get language => _box.get('language', defaultValue: 'en');

  void setTheme(String mode) {
    _box.put('theme', mode);
    notifyListeners();
  }

  void setLanguage(String lang) {
    _box.put('language', lang);
    notifyListeners();
  }
}

class AppStrings {
  static const Map<String, Map<String, String>> _strings = {
    'en': {
      'explore': 'Explore',
      'add_skill': 'Add Skill',
      'profile': 'Profile',
      'my_skills': 'My Skills',
      'settings': 'Settings',
      'logout': 'Logout',
      'nearby': 'Explore Nearby',
      'my_society': 'My Society',
      'no_skills_nearby': 'No skills found nearby.',
      'no_skills_society': 'No skills in your society yet.',
      'publish_skill': 'Publish Skill',
      'update_skill': 'Update Skill',
      'create_society': 'Create Society',
      'leave_society': 'Leave Society',
      'disclaimer': 'We do not verify any person. Use at your own risk.',
      'language': 'Language',
      'theme': 'Theme',
      'light': 'Light',
      'dark': 'Dark',
      'system': 'System',
      'privacy': 'Privacy Policy',
      'terms': 'Terms & Conditions',
    },
    'hi': {
      'explore': 'खोजें',
      'add_skill': 'कौशल जोड़ें',
      'profile': 'प्रोफ़ाइल',
      'my_skills': 'मेरे कौशल',
      'settings': 'सेटिंग्स',
      'logout': 'लॉग आउट',
      'nearby': 'आस-पास खोजें',
      'my_society': 'मेरा समाज',
      'no_skills_nearby': 'आस-पास कोई कौशल नहीं मिला।',
      'no_skills_society': 'आपके समाज में अभी तक कोई कौशल नहीं।',
      'publish_skill': 'कौशल प्रकाशित करें',
      'update_skill': 'कौशल अपडेट करें',
      'create_society': 'समाज बनाएँ',
      'leave_society': 'समाज छोड़ें',
      'disclaimer': 'हम किसी की पुष्टि नहीं करते। अपने जोखिम पर उपयोग करें।',
      'language': 'भाषा',
      'theme': 'थीम',
      'light': 'हल्का',
      'dark': 'गहरा',
      'system': 'सिस्टम',
      'privacy': 'गोपनीयता नीति',
      'terms': 'नियम और शर्तें',
    },
  };

  static String get(String key, {String lang = 'en'}) {
    return _strings[lang]?[key] ?? _strings['en']?[key] ?? key;
  }
}
