import 'package:flutter/material.dart';
import '../models/booking.dart';
import '../services/booking_service.dart';

class BookingProvider extends ChangeNotifier {
  List<Booking> _bookings = [];
  Booking? _lastBooking;
  bool _isLoading = false;
  String? _errorMessage;

  List<Booking> get bookings => _bookings;
  Booking? get lastBooking => _lastBooking;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> fetchBookings() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _bookings = await BookingService.getUserBookings();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
    }
  }

  Future<bool> createBooking({
    required int hotelId,
    required int roomId,
    required String checkIn,
    required String checkOut,
    int guestCount = 1,
    int? tripId,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final booking = await BookingService.createBooking(
        hotelId: hotelId,
        roomId: roomId,
        checkIn: checkIn,
        checkOut: checkOut,
        guestCount: guestCount,
        tripId: tripId,
      );
      _lastBooking = booking;
      _bookings.insert(0, booking);
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

  Future<void> cancelBooking(int bookingId) async {
    try {
      final updated = await BookingService.cancelBooking(bookingId);
      final idx = _bookings.indexWhere((b) => b.bookingId == bookingId);
      if (idx != -1) {
        _bookings[idx] = updated;
        notifyListeners();
      }
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
    }
  }
}
