class Room {
  final int roomId;
  final int hotelId;
  final String roomName;
  final String roomType;
  final String? description;
  final double pricePerNight;
  final String currency;
  final String bedType;
  final String roomSize;
  final int maximumOccupancy;
  final List<String> amenities;
  final String availabilityStatus;
  final String? imageUrl;
  final String? modelUrl;
  final bool has3dModel;

  Room({
    required this.roomId,
    required this.hotelId,
    required this.roomName,
    required this.roomType,
    this.description,
    required this.pricePerNight,
    this.currency = 'INR',
    this.bedType = 'King Bed',
    this.roomSize = '45 sq.m',
    this.maximumOccupancy = 2,
    this.amenities = const [],
    this.availabilityStatus = 'available',
    this.imageUrl,
    this.modelUrl,
    this.has3dModel = false,
  });

  factory Room.fromJson(Map<String, dynamic> json) {
    List<String> amList = [];
    if (json['amenities'] is List) {
      for (var a in json['amenities']) {
        amList.add(a.toString());
      }
    }

    return Room(
      roomId: json['room_id'] ?? 0,
      hotelId: json['hotel_id'] ?? 0,
      roomName: json['room_name'] ?? '',
      roomType: json['room_type'] ?? '',
      description: json['description'],
      pricePerNight: (json['price_per_night'] as num?)?.toDouble() ?? 0.0,
      currency: json['currency'] ?? 'INR',
      bedType: json['bed_type'] ?? 'King Bed',
      roomSize: json['room_size'] ?? '45 sq.m',
      maximumOccupancy: json['maximum_occupancy'] ?? 2,
      amenities: amList,
      availabilityStatus: json['availability_status'] ?? 'available',
      imageUrl: json['image_url'],
      modelUrl: json['model_url'],
      has3dModel: json['has_3d_model'] ?? (json['model_url'] != null && json['model_url'].toString().isNotEmpty),
    );
  }
}
