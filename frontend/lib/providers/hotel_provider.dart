import 'package:flutter/material.dart';

import '../models/hotel.dart';
import '../services/hotel_service.dart';

class HotelProvider extends ChangeNotifier {
  List<Hotel> _hotels = [];
  Hotel? _selectedHotel;
  final List<Hotel> _openTabs = [];
  int _activeTabIndex = -1;
  bool _isLoading = false;
  String? _errorMessage;
  double _searchRadiusKm = 30.0;
  String _currentDestination = '';
  double? _currentLat;
  double? _currentLng;
  int _searchGeneration = 0;

  // Selected dates for estimated trip expense
  DateTime _checkInDate = DateTime.now().add(const Duration(days: 7));
  DateTime _checkOutDate = DateTime.now().add(const Duration(days: 10));

  List<Hotel> get hotels => _hotels;
  Hotel? get selectedHotel => _selectedHotel;
  List<Hotel> get openTabs => _openTabs;
  int get activeTabIndex => _activeTabIndex;
  bool get hasOpenTabs => _openTabs.isNotEmpty;
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
    final existingIndex = _openTabs.indexWhere(
      (h) => h.hotelId == hotel.hotelId,
    );
    if (existingIndex >= 0) {
      _activeTabIndex = existingIndex;
      _selectedHotel = _openTabs[existingIndex];
    } else {
      _openTabs.add(hotel);
      _activeTabIndex = _openTabs.length - 1;
      _selectedHotel = hotel;
    }
    notifyListeners();
  }

  void switchToTab(int index) {
    if (index >= 0 && index < _openTabs.length) {
      _activeTabIndex = index;
      _selectedHotel = _openTabs[index];
      notifyListeners();
    }
  }

  void closeTab(int index) {
    if (index >= 0 && index < _openTabs.length) {
      _openTabs.removeAt(index);
      if (_openTabs.isEmpty) {
        _activeTabIndex = -1;
        _selectedHotel = null;
      } else {
        if (_activeTabIndex >= _openTabs.length) {
          _activeTabIndex = _openTabs.length - 1;
        }
        _selectedHotel = _openTabs[_activeTabIndex];
      }
      notifyListeners();
    }
  }

  void closePanel() {
    closeAllTabs();
  }

  void closeAllTabs() {
    _openTabs.clear();
    _activeTabIndex = -1;
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
    final generation = ++_searchGeneration;
    _isLoading = true;
    _hotels = []; // Clear previous markers immediately so old dots vanish
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
      if (generation != _searchGeneration) return;
      if (res['hotels'] is List<Hotel>) {
        _hotels = res['hotels'] as List<Hotel>;
      } else if (res['hotels'] is List) {
        _hotels = (res['hotels'] as List)
            .map(
              (h) => h is Hotel ? h : Hotel.fromJson(h as Map<String, dynamic>),
            )
            .toList();
      } else {
        _hotels = [];
      }
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      if (generation != _searchGeneration) return;
      _isLoading = false;
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
    }
  }

  void clearSearch() {
    _searchGeneration++;
    _hotels = [];
    _selectedHotel = null;
    _openTabs.clear();
    _activeTabIndex = -1;
    _currentDestination = '';
    _currentLat = null;
    _currentLng = null;
    _isLoading = false;
    _errorMessage = null;
    notifyListeners();
  }
}
