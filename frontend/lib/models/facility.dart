class Facility {
  final int facilityId;
  final int hotelId;
  final String facilityName;
  final String? description;

  Facility({
    required this.facilityId,
    required this.hotelId,
    required this.facilityName,
    this.description,
  });

  factory Facility.fromJson(Map<String, dynamic> json) {
    return Facility(
      facilityId: json['facility_id'] ?? 0,
      hotelId: json['hotel_id'] ?? 0,
      facilityName: json['facility_name'] ?? '',
      description: json['description'],
    );
  }
}
