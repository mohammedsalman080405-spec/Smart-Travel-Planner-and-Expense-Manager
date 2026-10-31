import 'package:flutter/material.dart';
import '../models/hotel.dart';
import '../services/hotel_service.dart';

class HotelProvider extends ChangeNotifier {
  List<Hotel> _hotels = [];
  Hotel? _selectedHotel;
  bool _isLoading = false;
  String? _errorMessage;
  double _searchRadiusKm = 30.0;
  String _currentDestination = '';
  double? _currentLat;
  double? _currentLng;

  // Selected dates for side panel estimated trip expense
  DateTime _checkInDate = DateTime.now().add(const Duration(days: 7));
  DateTime _checkOutDate = DateTime.now().add(const Duration(days: 10));

  List<Hotel> get hotels => _hotels;
  Hotel? get selectedHotel => _selectedHotel;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  double get searchRadiusKm => _searchRadiusKm;
  String get currentDestination => _currentDestination;
  DateTime get checkInDate => _checkInDate;
  DateTime get checkOutDate => _checkOutDate;

  int get estimatedNights {
    final diff = _checkOutDate.difference(_checkInDate).inDays;
    return diff > 0 ? diff : 1;
  }

  double get estimatedAccommodationCost {
    if (_selectedHotel == null) return 0.0;
    return _selectedHotel!.startingPrice * estimatedNights;
  }

  double get estimatedTaxesAndFees {
    return estimatedAccommodationCost * 0.12; // 12% standard demo taxes/fees
  }

  double get estimatedTotalCost {
    return estimatedAccommodationCost + estimatedTaxesAndFees;
  }

  void setDates(DateTime checkIn, DateTime checkOut) {
    _checkInDate = checkIn;
    _checkOutDate = checkOut;
    notifyListeners();
  }

  void selectHotel(Hotel hotel) {
    _selectedHotel = hotel;
    notifyListeners();
  }

  void closePanel() {
    _selectedHotel = null;
    notifyListeners();
  }

  void setRadius(double radiusKm) {
    _searchRadiusKm = radiusKm;
    notifyListeners();
    if (_currentLat != null && _currentLng != null) {
      searchHotels(
        latitude: _currentLat,
        longitude: _currentLng,
        destination: _currentDestination,
      );
    }
  }

  Future<void> searchHotels({
    double? latitude,
    double? longitude,
    String? destination,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    _currentLat = latitude;
    _currentLng = longitude;
    if (destination != null) _currentDestination = destination;
    notifyListeners();

    try {
      final res = await HotelService.searchHotels(
        latitude: latitude,
        longitude: longitude,
        destination: destination,
        radiusKm: _searchRadiusKm,
      );
      _hotels = res['hotels'] as List<Hotel>;
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
    }
  }

  void clearSearch() {
    _hotels = [];
    _selectedHotel = null;
    _currentDestination = '';
    _currentLat = null;
    _currentLng = null;
    notifyListeners();
  }
}
