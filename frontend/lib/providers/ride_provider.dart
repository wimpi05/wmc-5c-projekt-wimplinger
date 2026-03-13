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

  List<Ride> get todayRides {
    return _rides.where((ride) => ride.isToday).toList();
  }

  List<Ride> get upcomingRides {
    final now = DateTime.now();
    return _rides
        .where((ride) => !ride.isToday && ride.departTime.isAfter(now))
        .toList();
  }

  Future<void> fetchRides() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _rides = await _apiService.getRides();
      _rides.sort((a, b) => a.departTime.compareTo(b.departTime));
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> addRide(Ride ride) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _apiService.createRide(ride);
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
