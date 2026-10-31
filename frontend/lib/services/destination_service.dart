import '../config/api_config.dart';
import '../models/destination.dart';
import 'api_service.dart';

class DestinationService {
  static Future<List<Destination>> getDestinations() async {
    final response = await ApiService.get(ApiConfig.destinations);
    if (response is List) {
      return response.map((d) => Destination.fromJson(d)).toList();
    }
    return [];
  }

  static Future<Map<String, dynamic>> geocode(String query) async {
    final response = await ApiService.get('${ApiConfig.destinationGeocode}?q=${Uri.encodeComponent(query)}');
    return response as Map<String, dynamic>;
  }

  static Future<List<Destination>> search(String query) async {
    final response = await ApiService.get('${ApiConfig.destinationSearch}?q=${Uri.encodeComponent(query)}');
    if (response is List) {
      return response.map((d) => Destination.fromJson(d)).toList();
    }
    return [];
  }
}
