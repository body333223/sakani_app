import 'package:flutter/material.dart';

class LocaleProvider extends ChangeNotifier {
  String _lang = 'ar';

  String get lang => _lang;
  bool get isArabic => _lang == 'ar';

  Locale get locale => Locale(_lang);

  void setLang(String lang) {
    _lang = lang;
    notifyListeners();
  }

  void toggleLang() {
    _lang = _lang == 'ar' ? 'en' : 'ar';
    notifyListeners();
  }
}
