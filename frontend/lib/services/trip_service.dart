import '../config/api_config.dart';
import '../models/trip.dart';
import 'api_service.dart';

class TripService {
  static Future<List<Trip>> getTrips() async {
    final response = await ApiService.get(ApiConfig.trips, needsAuth: true);
    if (response is List) {
      return response.map((t) => Trip.fromJson(t)).toList();
    }
    return [];
  }

  static Future<Trip> getTrip(int tripId) async {
    final response = await ApiService.get(ApiConfig.tripDetails(tripId), needsAuth: true);
    return Trip.fromJson(response);
  }

  static Future<Trip> createTrip({
    required String tripName,
    required String destination,
    required String startDate,
    required String endDate,
    required double totalTripBudget,
    int travellerCount = 1,
  }) async {
    final response = await ApiService.post(
      ApiConfig.trips,
      body: {
        'trip_name': tripName,
        'destination': destination,
        'start_date': startDate,
        'end_date': endDate,
        'traveller_count': travellerCount,
        'total_trip_budget': totalTripBudget,
        'currency': 'INR',
      },
      needsAuth: true,
    );
    return Trip.fromJson(response['trip']);
  }

  static Future<void> deleteTrip(int tripId) async {
    await ApiService.delete(ApiConfig.tripDetails(tripId), needsAuth: true);
  }

  static Future<TripActivity> addActivity({
    required int tripId,
    required String activityName,
    required String activityDate,
    String? startTime,
    String? endTime,
    String? location,
    double? latitude,
    double? longitude,
    String? notes,
  }) async {
    final response = await ApiService.post(
      ApiConfig.tripActivities(tripId),
      body: {
        'activity_name': activityName,
        'activity_date': activityDate,
        'start_time': startTime ?? '10:00',
        'end_time': endTime ?? '12:00',
        'location': location ?? '',
        'latitude': latitude,
        'longitude': longitude,
        'notes': notes ?? '',
      },
      needsAuth: true,
    );
    return TripActivity.fromJson(response['activity']);
  }

  static Future<void> deleteActivity(int activityId) async {
    await ApiService.delete(ApiConfig.deleteActivity(activityId), needsAuth: true);
  }
}
