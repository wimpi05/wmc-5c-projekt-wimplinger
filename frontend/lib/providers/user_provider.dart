import 'package:flutter/material.dart';
import '../models/user.dart';
import '../services/api_service.dart';

class UserProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();
  
  User? _currentUser;
  bool _isLoading = false;

  User? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  bool get hasProfile => _currentUser != null;

  Future<void> loginDefaultUser() async {
    _isLoading = true;
    notifyListeners();
    try {
      // Für den Anfang laden wir einfach den ersten User aus deiner DB
      _currentUser = await _apiService.getUserById(1);
    } catch (e) {
      print("Kein Profil gefunden: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> register(String name, String email) async {
    _isLoading = true;
    notifyListeners();
    try {
      _currentUser = await _apiService.createUser(name: name, email: email);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}