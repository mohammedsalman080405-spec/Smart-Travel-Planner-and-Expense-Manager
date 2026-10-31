import 'facility.dart';
import 'hotel_image.dart';
import 'room.dart';
import 'hotel_space.dart';

class Hotel {
  final int hotelId;
  final int? destinationId;
  final String hotelName;
  final String description;
  final String address;
  final String city;
  final String country;
  final double latitude;
  final double longitude;
  final double starRating;
  final double reviewRating;
  final int reviewCount;
  final double startingPrice;
  final String currency;
  final String? exteriorImageUrl;
  final String? exteriorModelUrl;
  final String? placeId;
  final String dataSource;
  final bool isDemo;
  final double? distanceKm;
  final String? formattedDistance;
  final List<String> facilitiesList;
  final List<Facility> facilities;
  final List<HotelImage> images;
  final List<Room> rooms;
  final List<HotelSpace> spaces;

  Hotel({
    required this.hotelId,
    this.destinationId,
    required this.hotelName,
    required this.description,
    required this.address,
    required this.city,
    required this.country,
    required this.latitude,
    required this.longitude,
    required this.starRating,
    required this.reviewRating,
    required this.reviewCount,
    required this.startingPrice,
    this.currency = 'INR',
    this.exteriorImageUrl,
    this.exteriorModelUrl,
    this.placeId,
    this.dataSource = 'database',
    this.isDemo = true,
    this.distanceKm,
    this.formattedDistance,
    this.facilitiesList = const [],
    this.facilities = const [],
    this.images = const [],
    this.rooms = const [],
    this.spaces = const [],
  });

  factory Hotel.fromJson(Map<String, dynamic> json) {
    List<String> facList = [];
    if (json['facilities'] is List) {
      for (var f in json['facilities']) {
        if (f is String) {
          facList.add(f);
        } else if (f is Map && f['facility_name'] != null) {
          facList.add(f['facility_name']);
        }
      }
    }

    List<Facility> facObjs = [];
    if (json['facilities'] is List) {
      for (var f in json['facilities']) {
        if (f is Map<String, dynamic>) {
          facObjs.add(Facility.fromJson(f));
        }
      }
    }

    List<HotelImage> imgObjs = [];
    if (json['images'] is List) {
      for (var img in json['images']) {
        if (img is Map<String, dynamic>) {
          imgObjs.add(HotelImage.fromJson(img));
        }
      }
    }

    List<Room> roomObjs = [];
    if (json['rooms'] is List) {
      for (var r in json['rooms']) {
        if (r is Map<String, dynamic>) {
          roomObjs.add(Room.fromJson(r));
        }
      }
    }

    List<HotelSpace> spaceObjs = [];
    if (json['spaces'] is List) {
      for (var s in json['spaces']) {
        if (s is Map<String, dynamic>) {
          spaceObjs.add(HotelSpace.fromJson(s));
        }
      }
    }

    return Hotel(
      hotelId: json['hotel_id'] ?? 0,
      destinationId: json['destination_id'],
      hotelName: json['hotel_name'] ?? '',
      description: json['description'] ?? '',
      address: json['address'] ?? '',
      city: json['city'] ?? '',
      country: json['country'] ?? '',
      latitude: (json['latitude'] as num?)?.toDouble() ?? 0.0,
      longitude: (json['longitude'] as num?)?.toDouble() ?? 0.0,
      starRating: (json['star_rating'] as num?)?.toDouble() ?? 0.0,
      reviewRating: (json['review_rating'] as num?)?.toDouble() ?? 0.0,
      reviewCount: json['review_count'] ?? 0,
      startingPrice: (json['starting_price'] as num?)?.toDouble() ?? 0.0,
      currency: json['currency'] ?? 'INR',
      exteriorImageUrl: json['exterior_image_url'],
      exteriorModelUrl: json['exterior_model_url'],
      placeId: json['place_id'],
      dataSource: json['data_source'] ?? 'database',
      isDemo: json['is_demo'] ?? true,
      distanceKm: (json['distance_km'] as num?)?.toDouble(),
      formattedDistance: json['formatted_distance'],
      facilitiesList: facList,
      facilities: facObjs,
      images: imgObjs,
      rooms: roomObjs,
      spaces: spaceObjs,
    );
  }
}
