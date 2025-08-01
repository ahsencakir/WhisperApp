import 'package:flutter/material.dart';

class LogoProvider with ChangeNotifier {
  String? _logoURL;
  bool _isLoading = false;

  String? get logoURL => _logoURL;
  bool get isLoading => _isLoading;

  // Logoyu API'den veya doğrudan parametre olarak alır
  Future<void> fetchLogoFromApi(String url) async {
    _isLoading = true;
    notifyListeners();

    try {
      _logoURL = url;
    } catch (e) {
      _logoURL = null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Manuel olarak URL setlemek istenirse
  void setLogoUrl(String url) {
    _logoURL = url;
    notifyListeners();
  }
}
