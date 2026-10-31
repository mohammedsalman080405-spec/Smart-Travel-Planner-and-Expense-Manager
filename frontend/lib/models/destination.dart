class Destination {
  final int destinationId;
  final String name;
  final String city;
  final String country;
  final String? description;
  final double latitude;
  final double longitude;
  final String? imageUrl;

  Destination({
    required this.destinationId,
    required this.name,
    required this.city,
    required this.country,
    this.description,
    required this.latitude,
    required this.longitude,
    this.imageUrl,
  });

  factory Destination.fromJson(Map<String, dynamic> json) {
    return Destination(
      destinationId: json['destination_id'] ?? 0,
      name: json['name'] ?? '',
      city: json['city'] ?? '',
      country: json['country'] ?? '',
      description: json['description'],
      latitude: (json['latitude'] as num?)?.toDouble() ?? 0.0,
      longitude: (json['longitude'] as num?)?.toDouble() ?? 0.0,
      imageUrl: json['image_url'],
    );
  }
}
