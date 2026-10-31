class HotelImage {
  final int imageId;
  final int hotelId;
  final String imageUrl;
  final String imageCategory;
  final String? caption;
  final int displayOrder;

  HotelImage({
    required this.imageId,
    required this.hotelId,
    required this.imageUrl,
    this.imageCategory = 'exterior',
    this.caption,
    this.displayOrder = 0,
  });

  factory HotelImage.fromJson(Map<String, dynamic> json) {
    return HotelImage(
      imageId: json['image_id'] ?? 0,
      hotelId: json['hotel_id'] ?? 0,
      imageUrl: json['image_url'] ?? '',
      imageCategory: json['image_category'] ?? 'exterior',
      caption: json['caption'],
      displayOrder: json['display_order'] ?? 0,
    );
  }
}
