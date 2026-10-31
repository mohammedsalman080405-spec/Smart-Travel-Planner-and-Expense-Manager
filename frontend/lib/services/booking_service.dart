import '../config/api_config.dart';
import '../models/booking.dart';
import 'api_service.dart';

class BookingService {
  static Future<Booking> createBooking({
    required int hotelId,
    required int roomId,
    required String checkIn,
    required String checkOut,
    int guestCount = 1,
    int? tripId,
  }) async {
    final response = await ApiService.post(
      ApiConfig.bookings,
      body: {
        'hotel_id': hotelId,
        'room_id': roomId,
        'check_in': checkIn,
        'check_out': checkOut,
        'guest_count': guestCount,
        'trip_id': tripId,
      },
      needsAuth: true,
    );
    return Booking.fromJson(response['booking']);
  }

  static Future<List<Booking>> getUserBookings() async {
    final response = await ApiService.get(ApiConfig.bookings, needsAuth: true);
    if (response is List) {
      return response.map((b) => Booking.fromJson(b)).toList();
    }
    return [];
  }

  static Future<Booking> cancelBooking(int bookingId) async {
    final response = await ApiService.patch(ApiConfig.cancelBooking(bookingId), needsAuth: true);
    return Booking.fromJson(response['booking']);
  }
}
