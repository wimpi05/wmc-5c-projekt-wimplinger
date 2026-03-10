import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/user.dart';
import '../models/ride.dart';
import '../models/passenger.dart';
import '../models/group.dart';

class ApiService {
  static const String baseUrl = 'http://10.0.2.2:3000';

  // ------------------------
  // User Endpoints
  // ------------------------

  Future<List<User>> getUsers() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/users'));
      
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) => User.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load users: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching users: $e');
    }
  }

  Future<User> getUserById(int userId) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/users/$userId'));
      
      if (response.statusCode == 200) {
        return User.fromJson(json.decode(response.body));
      } else {
        throw Exception('Failed to load user: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching user: $e');
    }
  }

  Future<User> createUser({
    required String name,
    required String email,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/users'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'name': name,
          'email': email,
        }),
      );
      
      if (response.statusCode == 201) {
        return User.fromJson(json.decode(response.body));
      } else {
        throw Exception('Failed to create user: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error creating user: $e');
    }
  }

  // ------------------------
  // Ride Endpoints
  // ------------------------

  Future<List<Ride>> getRides() async {
    try {
      // Das Backend sollte hier den SQL-JOIN für driver_username und seats_occupied nutzen
      final response = await http.get(Uri.parse('$baseUrl/rides'));
      
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) => Ride.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load rides: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching rides: $e');
    }
  }

  Future<Ride> getRideById(int rideId) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/rides/$rideId'));
      
      if (response.statusCode == 200) {
        return Ride.fromJson(json.decode(response.body));
      } else {
        throw Exception('Failed to load ride: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching ride: $e');
    }
  }

  Future<Ride> createRide(Ride ride) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/rides'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(ride.toJson()),
      );
      
      if (response.statusCode == 201) {
        final Map<String, dynamic> responseData = json.decode(response.body);
        return ride.copyWith(
          id: responseData['id'],
          createdAt: DateTime.now(),
        );
      } else {
        throw Exception('Failed to create ride: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error creating ride: $e');
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
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'user_id': userId,
        }),
      );
      
      if (response.statusCode == 201) {
        return Passenger.fromJson(json.decode(response.body));
      } else {
        throw Exception('Failed to join ride: ${response.body}');
      }
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
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'user_id': userId,
        }),
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

  Future<Map<String, dynamic>> getRideStats() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/stats/rides'));
      
      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to load ride stats: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching ride stats: $e');
    }
  }

  // ------------------------
  // Group Endpoints
  // ------------------------

  Future<List<Group>> getGroupsForUser(int userId) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/groups?user_id=$userId'));
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
        headers: {'Content-Type': 'application/json'},
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
        headers: {'Content-Type': 'application/json'},
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
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'user_id': userId}),
      );
      if (response.statusCode != 200) {
        throw Exception('Failed to leave group: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error leaving group: $e');
    }
  }
}