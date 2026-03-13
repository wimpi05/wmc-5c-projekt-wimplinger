import 'dart:convert';
import 'package:http/http.dart' as http;

import '../models/group.dart';
import '../models/passenger.dart';
import '../models/ride.dart';
import '../models/user.dart';

class AuthResult {
  final String accessToken;
  final String refreshToken;
  final User user;

  const AuthResult({
    required this.accessToken,
    required this.refreshToken,
    required this.user,
  });

  factory AuthResult.fromJson(Map<String, dynamic> json) {
    return AuthResult(
      accessToken: json['access_token'] as String,
      refreshToken: json['refresh_token'] as String,
      user: User.fromJson(json['user'] as Map<String, dynamic>),
    );
  }
}

class ApiService {
  static const String baseUrl = 'http://10.0.2.2:3000';

  ApiService._internal();
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;

  String? _accessToken;
  String? _refreshToken;

  String? get accessToken => _accessToken;
  String? get refreshToken => _refreshToken;

  void setSession({required String accessToken, required String refreshToken}) {
    _accessToken = accessToken;
    _refreshToken = refreshToken;
  }

  void clearSession() {
    _accessToken = null;
    _refreshToken = null;
  }

  Map<String, String> _headers({bool withAuth = false}) {
    final headers = <String, String>{'Content-Type': 'application/json'};
    if (withAuth && _accessToken != null) {
      headers['Authorization'] = 'Bearer $_accessToken';
    }
    return headers;
  }

  Future<AuthResult> login({required String email, required String password}) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/login'),
      headers: _headers(),
      body: json.encode({'email': email, 'password': password}),
    );

    if (response.statusCode == 200) {
      final result = AuthResult.fromJson(json.decode(response.body));
      setSession(accessToken: result.accessToken, refreshToken: result.refreshToken);
      return result;
    }

    throw Exception(_extractError(response, 'Login fehlgeschlagen'));
  }

  Future<AuthResult> register({
    required String email,
    required String password,
    required String name,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/register'),
      headers: _headers(),
      body: json.encode({'email': email, 'password': password, 'name': name}),
    );

    if (response.statusCode == 201) {
      final result = AuthResult.fromJson(json.decode(response.body));
      setSession(accessToken: result.accessToken, refreshToken: result.refreshToken);
      return result;
    }

    throw Exception(_extractError(response, 'Registrierung fehlgeschlagen'));
  }

  Future<String> refreshAccessToken() async {
    if (_refreshToken == null) {
      throw Exception('Kein Refresh-Token vorhanden.');
    }

    final response = await http.post(
      Uri.parse('$baseUrl/auth/refresh'),
      headers: _headers(),
      body: json.encode({'refresh_token': _refreshToken}),
    );

    if (response.statusCode == 200) {
      final payload = json.decode(response.body) as Map<String, dynamic>;
      final token = payload['access_token'] as String;
      _accessToken = token;
      return token;
    }

    throw Exception(_extractError(response, 'Token-Refresh fehlgeschlagen'));
  }

  Future<void> logout() async {
    if (_refreshToken == null) {
      clearSession();
      return;
    }

    try {
      await http.post(
        Uri.parse('$baseUrl/auth/logout'),
        headers: _headers(),
        body: json.encode({'refresh_token': _refreshToken}),
      );
    } finally {
      clearSession();
    }
  }

  Future<User> getMe() async {
    final response = await http.get(
      Uri.parse('$baseUrl/auth/me'),
      headers: _headers(withAuth: true),
    );

    if (response.statusCode == 200) {
      return User.fromJson(json.decode(response.body));
    }

    throw Exception(_extractError(response, 'Profil konnte nicht geladen werden'));
  }

  Future<User> updateMyProfile({required String name}) async {
    final response = await http.patch(
      Uri.parse('$baseUrl/users/me'),
      headers: _headers(withAuth: true),
      body: json.encode({'name': name}),
    );

    if (response.statusCode == 200) {
      return User.fromJson(json.decode(response.body));
    }

    throw Exception(_extractError(response, 'Profil konnte nicht aktualisiert werden'));
  }

  // ------------------------
  // Ride Endpoints
  // ------------------------

  Future<List<Ride>> getRides() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/rides'),
        headers: _headers(withAuth: true),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) => Ride.fromJson(json)).toList();
      }
      throw Exception('Failed to load rides: ${response.statusCode}');
    } catch (e) {
      throw Exception('Error fetching rides: $e');
    }
  }

  Future<Ride> createRide(Ride ride) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/rides'),
        headers: _headers(withAuth: true),
        body: json.encode(ride.toJson()),
      );

      if (response.statusCode == 201) {
        final Map<String, dynamic> responseData = json.decode(response.body);
        return ride.copyWith(id: responseData['id'], createdAt: DateTime.now());
      }
      throw Exception('Failed to create ride: ${response.body}');
    } catch (e) {
      throw Exception('Error creating ride: $e');
    }
  }

  Future<void> updateRide({required int rideId, required Ride ride}) async {
    try {
      final response = await http.patch(
        Uri.parse('$baseUrl/rides/$rideId'),
        headers: _headers(withAuth: true),
        body: json.encode(ride.toJson()),
      );

      if (response.statusCode != 200) {
        throw Exception(_extractError(response, 'Fahrt konnte nicht bearbeitet werden'));
      }
    } catch (e) {
      throw Exception('Error updating ride: $e');
    }
  }

  Future<void> deleteRide({required int rideId}) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/rides/$rideId'),
        headers: _headers(withAuth: true),
      );

      if (response.statusCode != 200) {
        throw Exception(_extractError(response, 'Fahrt konnte nicht gelöscht werden'));
      }
    } catch (e) {
      throw Exception('Error deleting ride: $e');
    }
  }

  // ------------------------
  // Passenger Endpoints
  // ------------------------

  Future<Passenger> joinRide({
    required int rideId,
    required int userId,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/rides/$rideId/join'),
        headers: _headers(withAuth: true),
        body: json.encode({'user_id': userId}),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        return Passenger.fromJson(json.decode(response.body));
      }
      throw Exception('Failed to join ride: ${response.body}');
    } catch (e) {
      throw Exception('Error joining ride: $e');
    }
  }

  Future<void> cancelRide({
    required int rideId,
    required int userId,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/rides/$rideId/cancel'),
        headers: _headers(withAuth: true),
        body: json.encode({'user_id': userId}),
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to cancel ride: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error canceling ride: $e');
    }
  }

  // ------------------------
  // Statistics Endpoints
  // ------------------------

  Future<Map<String, dynamic>> getMyRideStats() async {
    final response = await http.get(
      Uri.parse('$baseUrl/stats/me'),
      headers: _headers(withAuth: true),
    );

    if (response.statusCode == 200) {
      return json.decode(response.body) as Map<String, dynamic>;
    }

    throw Exception(_extractError(response, 'Persönliche Statistiken konnten nicht geladen werden'));
  }

  Future<List<Map<String, dynamic>>> getMyWeeklyStats() async {
    final response = await http.get(
      Uri.parse('$baseUrl/stats/me/weekly'),
      headers: _headers(withAuth: true),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body) as List<dynamic>;
      return data.map((row) => row as Map<String, dynamic>).toList();
    }

    throw Exception(_extractError(response, 'Wöchentliche Statistiken konnten nicht geladen werden'));
  }

  // ------------------------
  // Group Endpoints
  // ------------------------

  Future<List<Group>> getGroupsForUser(int userId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/groups?user_id=$userId'),
        headers: _headers(withAuth: true),
      );
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) => Group.fromJson(json)).toList();
      }
      throw Exception('Failed to load groups: ${response.body}');
    } catch (e) {
      throw Exception('Error fetching groups: $e');
    }
  }

  Future<Group> createGroup({required String name, required int userId}) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/groups'),
        headers: _headers(withAuth: true),
        body: json.encode({'name': name, 'user_id': userId}),
      );
      if (response.statusCode == 201) {
        return Group.fromJson(json.decode(response.body));
      }
      throw Exception('Failed to create group: ${response.body}');
    } catch (e) {
      throw Exception('Error creating group: $e');
    }
  }

  Future<Group> joinGroup({required String code, required int userId}) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/groups/join'),
        headers: _headers(withAuth: true),
        body: json.encode({'code': code, 'user_id': userId}),
      );
      if (response.statusCode == 200) {
        return Group.fromJson(json.decode(response.body));
      }
      throw Exception('Failed to join group: ${response.body}');
    } catch (e) {
      throw Exception('Error joining group: $e');
    }
  }

  Future<void> leaveGroup({required int groupId, required int userId}) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/groups/$groupId/leave'),
        headers: _headers(withAuth: true),
        body: json.encode({'user_id': userId}),
      );
      if (response.statusCode != 200) {
        throw Exception('Failed to leave group: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error leaving group: $e');
    }
  }

  String _extractError(http.Response response, String fallback) {
    try {
      final payload = json.decode(response.body) as Map<String, dynamic>;
      final msg = payload['error']?.toString();
      if (msg != null && msg.trim().isNotEmpty) return msg;
    } catch (_) {
      // ignored
    }
    return '$fallback (HTTP ${response.statusCode})';
  }
}
