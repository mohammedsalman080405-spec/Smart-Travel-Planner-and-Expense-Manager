import '../config/api_config.dart';
import '../models/hotel.dart';
import '../models/room.dart';
import '../models/hotel_space.dart';
import 'api_service.dart';

class HotelService {
  static Future<Map<String, dynamic>> searchHotels({
    double? latitude,
    double? longitude,
    String? destination,
    double radiusKm = 25.0,
    double? minPrice,
    double? maxPrice,
    double? rating,
    String sortBy = 'distance',
  }) async {
    final queryParams = <String, String>{
      'radius_km': radiusKm.toString(),
      'sort_by': sortBy,
      'per_page': '30',
    };
    if (latitude != null && longitude != null) {
      queryParams['latitude'] = latitude.toString();
      queryParams['longitude'] = longitude.toString();
    }
    if (destination != null && destination.isNotEmpty) {
      queryParams['destination'] = destination;
    }
    if (minPrice != null) queryParams['min_price'] = minPrice.toString();
    if (maxPrice != null) queryParams['max_price'] = maxPrice.toString();
    if (rating != null) queryParams['rating'] = rating.toString();

    final uri = Uri.parse(ApiConfig.hotelSearch).replace(queryParameters: queryParams);
    final response = await ApiService.get(uri.toString());

    List<Hotel> hotels = [];
    if (response is Map && response['hotels'] is List) {
      hotels = (response['hotels'] as List).map((h) => Hotel.fromJson(h)).toList();
    }

    return {
      'total': response['total'] ?? hotels.length,
      'hotels': hotels,
      'searched_coordinates': response['searched_coordinates'],
      'radius_km': response['radius_km'] ?? radiusKm,
    };
  }

  static Future<Hotel> getHotelDetails(int hotelId) async {
    final response = await ApiService.get(ApiConfig.hotelDetails(hotelId));
    return Hotel.fromJson(response);
  }

  static Future<List<Room>> getHotelRooms(int hotelId) async {
    final response = await ApiService.get(ApiConfig.hotelRooms(hotelId));
    if (response is List) {
      return response.map((r) => Room.fromJson(r)).toList();
    }
    return [];
  }

  static Future<List<HotelSpace>> getHotelSpaces(int hotelId, {String? category}) async {
    String url = ApiConfig.hotelSpaces(hotelId);
    if (category != null) {
      url += '?category=$category';
    }
    final response = await ApiService.get(url);
    if (response is List) {
      return response.map((s) => HotelSpace.fromJson(s)).toList();
    }
    return [];
  }

  static Future<Room> getRoomDetails(int roomId) async {
    final response = await ApiService.get(ApiConfig.roomDetails(roomId));
    return Room.fromJson(response);
  }

  static Future<HotelSpace> getSpaceDetails(int spaceId) async {
    final response = await ApiService.get(ApiConfig.spaceDetails(spaceId));
    return HotelSpace.fromJson(response);
  }
}
