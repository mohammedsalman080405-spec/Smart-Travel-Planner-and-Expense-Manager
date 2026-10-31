import 'package:flutter/material.dart';
import '../models/trip.dart';
import '../services/trip_service.dart';

class TripProvider extends ChangeNotifier {
  List<Trip> _trips = [];
  Trip? _selectedTrip;
  bool _isLoading = false;
  String? _errorMessage;

  List<Trip> get trips => _trips;
  Trip? get selectedTrip => _selectedTrip;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> fetchTrips() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _trips = await TripService.getTrips();
      if (_trips.isNotEmpty && _selectedTrip == null) {
        _selectedTrip = _trips.first;
      }
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
    }
  }

  Future<void> selectTrip(int tripId) async {
    _isLoading = true;
    notifyListeners();
    try {
      _selectedTrip = await TripService.getTrip(tripId);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
    }
  }

  Future<bool> createTrip({
    required String tripName,
    required String destination,
    required String startDate,
    required String endDate,
    required double totalTripBudget,
    int travellerCount = 1,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final trip = await TripService.createTrip(
        tripName: tripName,
        destination: destination,
        startDate: startDate,
        endDate: endDate,
        totalTripBudget: totalTripBudget,
        travellerCount: travellerCount,
      );
      _trips.insert(0, trip);
      _selectedTrip = trip;
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  Future<void> addActivity({
    required int tripId,
    required String activityName,
    required String activityDate,
    String? startTime,
    String? endTime,
    String? location,
    double? latitude,
    double? longitude,
    String? notes,
  }) async {
    try {
      await TripService.addActivity(
        tripId: tripId,
        activityName: activityName,
        activityDate: activityDate,
        startTime: startTime,
        endTime: endTime,
        location: location,
        latitude: latitude,
        longitude: longitude,
        notes: notes,
      );
      // Refresh current trip
      await selectTrip(tripId);
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
    }
  }

  Future<void> deleteActivity(int activityId, int tripId) async {
    try {
      await TripService.deleteActivity(activityId);
      await selectTrip(tripId);
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
    }
  }

  Future<void> deleteTrip(int tripId) async {
    try {
      await TripService.deleteTrip(tripId);
      _trips.removeWhere((t) => t.tripId == tripId);
      if (_selectedTrip?.tripId == tripId) {
        _selectedTrip = _trips.isNotEmpty ? _trips.first : null;
      }
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
    }
  }
}
