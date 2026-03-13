import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/user.dart';
import '../services/api_service.dart';

enum AuthStatus {
  unknown,
  authenticated,
  unauthenticated,
}

class UserProvider with ChangeNotifier {
  static const _kAccessTokenKey = 'auth_access_token';
  static const _kRefreshTokenKey = 'auth_refresh_token';

  final ApiService _apiService = ApiService();

  User? _currentUser;
  bool _isLoading = false;
  AuthStatus _authStatus = AuthStatus.unknown;

  User? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  bool get hasProfile => _currentUser != null;
  bool get isAuthenticated => _authStatus == AuthStatus.authenticated;
  AuthStatus get authStatus => _authStatus;

  Future<void> bootstrapSession() async {
    _isLoading = true;
    notifyListeners();

    try {
      final prefs = await _getPrefsSafely();
      if (prefs == null) {
        _authStatus = AuthStatus.unauthenticated;
        _currentUser = null;
        return;
      }
      final access = prefs.getString(_kAccessTokenKey);
      final refresh = prefs.getString(_kRefreshTokenKey);

      if (access == null || refresh == null) {
        _authStatus = AuthStatus.unauthenticated;
        _currentUser = null;
        return;
      }

      _apiService.setSession(accessToken: access, refreshToken: refresh);

      try {
        _currentUser = await _apiService.getMe();
        _authStatus = AuthStatus.authenticated;
        return;
      } catch (_) {}

      await _apiService.refreshAccessToken();
      _currentUser = await _apiService.getMe();
      _authStatus = AuthStatus.authenticated;

      await prefs.setString(_kAccessTokenKey, _apiService.accessToken!);
      await prefs.setString(_kRefreshTokenKey, _apiService.refreshToken!);
    } catch (_) {
      await _clearLocalSession();
      _authStatus = AuthStatus.unauthenticated;
      _currentUser = null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> login({required String email, required String password}) async {
    _isLoading = true;
    notifyListeners();
    try {
      final result = await _apiService.login(email: email, password: password);
      _currentUser = result.user;
      _authStatus = AuthStatus.authenticated;
      await _persistTokens(result.accessToken, result.refreshToken);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> register({
    required String email,
    required String password,
    required String name,
  }) async {
    _isLoading = true;
    notifyListeners();
    try {
      final result = await _apiService.register(
        email: email,
        password: password,
        name: name,
      );
      _currentUser = result.user;
      _authStatus = AuthStatus.authenticated;
      await _persistTokens(result.accessToken, result.refreshToken);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    _isLoading = true;
    notifyListeners();
    try {
      await _apiService.logout();
    } finally {
      await _clearLocalSession();
      _currentUser = null;
      _authStatus = AuthStatus.unauthenticated;
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateProfileName(String name) async {
    final cleanName = name.trim();
    if (cleanName.isEmpty) return;

    _isLoading = true;
    notifyListeners();

    try {
      _currentUser = await _apiService.updateMyProfile(name: cleanName);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _persistTokens(String access, String refresh) async {
    final prefs = await _getPrefsSafely();
    if (prefs == null) return;
    await prefs.setString(_kAccessTokenKey, access);
    await prefs.setString(_kRefreshTokenKey, refresh);
  }

  Future<void> _clearLocalSession() async {
    final prefs = await _getPrefsSafely();
    if (prefs != null) {
      await prefs.remove(_kAccessTokenKey);
      await prefs.remove(_kRefreshTokenKey);
    }
    _apiService.clearSession();
  }

  Future<SharedPreferences?> _getPrefsSafely() async {
    try {
      return await SharedPreferences.getInstance();
    } on MissingPluginException {
      return null;
    }
  }
}
