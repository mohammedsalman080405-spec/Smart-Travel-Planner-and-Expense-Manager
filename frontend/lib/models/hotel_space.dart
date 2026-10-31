class HotelSpace {
  final int spaceId;
  final int hotelId;
  final String spaceName;
  final String category;
  final String? description;
  final int capacity;
  final String size;
  final double price;
  final String currency;
  final String openingHours;
  final List<String> amenities;
  final String? imageUrl;
  final String? modelUrl;
  final bool has3dModel;

  HotelSpace({
    required this.spaceId,
    required this.hotelId,
    required this.spaceName,
    required this.category,
    this.description,
    this.capacity = 50,
    this.size = '120 sq.m',
    this.price = 0.0,
    this.currency = 'INR',
    this.openingHours = '06:00 - 23:00',
    this.amenities = const [],
    this.imageUrl,
    this.modelUrl,
    this.has3dModel = false,
  });

  factory HotelSpace.fromJson(Map<String, dynamic> json) {
    List<String> amList = [];
    if (json['amenities'] is List) {
      for (var a in json['amenities']) {
        amList.add(a.toString());
      }
    }

    return HotelSpace(
      spaceId: json['space_id'] ?? 0,
      hotelId: json['hotel_id'] ?? 0,
      spaceName: json['space_name'] ?? '',
      category: json['category'] ?? '',
      description: json['description'],
      capacity: json['capacity'] ?? 50,
      size: json['size'] ?? '120 sq.m',
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
      currency: json['currency'] ?? 'INR',
      openingHours: json['opening_hours'] ?? '06:00 - 23:00',
      amenities: amList,
      imageUrl: json['image_url'],
      modelUrl: json['model_url'],
      has3dModel: json['has_3d_model'] ?? (json['model_url'] != null && json['model_url'].toString().isNotEmpty),
    );
  }
}
