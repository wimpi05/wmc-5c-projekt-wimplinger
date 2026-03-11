import 'package:flutter/material.dart';
import '../models/ride.dart';
import '../services/api_service.dart';

class RideProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();

  List<Ride> _rides = [];
  bool _isLoading = false;
  String? _error;

  List<Ride> get rides => _rides;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Filter für die Dashboard-Tabs (Konzept Punkt 4.1)
  List<Ride> get todayRides {
    return _rides.where((ride) => ride.isToday).toList();
  }

  List<Ride> get upcomingRides {
    // Fahrten, die nicht heute sind und in der Zukunft liegen
    final now = DateTime.now();
    return _rides
        .where((ride) => !ride.isToday && ride.departTime.isAfter(now))
        .toList();
  }

  // Alle Fahrten vom Server laden
  Future<void> fetchRides() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _rides = await _apiService.getRides();
      // Sortierung: Baldigste Fahrt zuerst
      _rides.sort((a, b) => a.departTime.compareTo(b.departTime));
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Neue Fahrt erstellen (Konzept Punkt 5.1)
  Future<bool> addRide(Ride ride) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _apiService.createRide(ride);
      await fetchRides(); // Holt die saubere Liste inkl. driver_username vom Server
      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> updateRide({required int rideId, required Ride ride}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _apiService.updateRide(rideId: rideId, ride: ride);
      await fetchRides();
      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> deleteRide(int rideId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _apiService.deleteRide(rideId: rideId);
      await fetchRides();
      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Einer Fahrt beitreten (Konzept Punkt 5.2)
  Future<bool> joinRide(int rideId, int userId) async {
    try {
      await _apiService.joinRide(rideId: rideId, userId: userId);

      await fetchRides();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  // Fahrt absagen (Konzept Punkt 5.3)
  Future<bool> cancelRide(int rideId, int userId) async {
    try {
      await _apiService.cancelRide(rideId: rideId, userId: userId);
      await fetchRides();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
