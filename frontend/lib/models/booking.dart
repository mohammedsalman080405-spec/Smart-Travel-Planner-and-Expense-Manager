class Booking {
  final int bookingId;
  final int userId;
  final int hotelId;
  final int roomId;
  final int? tripId;
  final String? hotelName;
  final String? hotelImage;
  final String? hotelAddress;
  final String? roomName;
  final String? roomType;
  final String? roomImage;
  final String checkIn;
  final String checkOut;
  final int guestCount;
  final int numberOfNights;
  final double pricePerNight;
  final double totalAmount;
  final String currency;
  final String bookingStatus;
  final String? createdAt;

  Booking({
    required this.bookingId,
    required this.userId,
    required this.hotelId,
    required this.roomId,
    this.tripId,
    this.hotelName,
    this.hotelImage,
    this.hotelAddress,
    this.roomName,
    this.roomType,
    this.roomImage,
    required this.checkIn,
    required this.checkOut,
    this.guestCount = 1,
    required this.numberOfNights,
    required this.pricePerNight,
    required this.totalAmount,
    this.currency = 'INR',
    this.bookingStatus = 'confirmed',
    this.createdAt,
  });

  factory Booking.fromJson(Map<String, dynamic> json) {
    return Booking(
      bookingId: json['booking_id'] ?? 0,
      userId: json['user_id'] ?? 0,
      hotelId: json['hotel_id'] ?? 0,
      roomId: json['room_id'] ?? 0,
      tripId: json['trip_id'],
      hotelName: json['hotel_name'],
      hotelImage: json['hotel_image'],
      hotelAddress: json['hotel_address'],
      roomName: json['room_name'],
      roomType: json['room_type'],
      roomImage: json['room_image'],
      checkIn: json['check_in'] ?? '',
      checkOut: json['check_out'] ?? '',
      guestCount: json['guest_count'] ?? 1,
      numberOfNights: json['number_of_nights'] ?? 1,
      pricePerNight: (json['price_per_night'] as num?)?.toDouble() ?? 0.0,
      totalAmount: (json['total_amount'] as num?)?.toDouble() ?? 0.0,
      currency: json['currency'] ?? 'INR',
      bookingStatus: json['booking_status'] ?? 'confirmed',
      createdAt: json['created_at'],
    );
  }
}
