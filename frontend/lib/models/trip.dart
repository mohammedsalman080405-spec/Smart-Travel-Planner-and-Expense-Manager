import 'booking.dart';
import 'budget.dart';
import 'expense.dart';

class TripActivity {
  final int activityId;
  final int tripId;
  final int? destinationId;
  final String activityName;
  final String activityDate;
  final String? startTime;
  final String? endTime;
  final String? location;
  final double? latitude;
  final double? longitude;
  final String? notes;

  TripActivity({
    required this.activityId,
    required this.tripId,
    this.destinationId,
    required this.activityName,
    required this.activityDate,
    this.startTime,
    this.endTime,
    this.location,
    this.latitude,
    this.longitude,
    this.notes,
  });

  factory TripActivity.fromJson(Map<String, dynamic> json) {
    return TripActivity(
      activityId: json['activity_id'] ?? 0,
      tripId: json['trip_id'] ?? 0,
      destinationId: json['destination_id'],
      activityName: json['activity_name'] ?? '',
      activityDate: json['activity_date'] ?? '',
      startTime: json['start_time'],
      endTime: json['end_time'],
      location: json['location'],
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      notes: json['notes'],
    );
  }
}

class Trip {
  final int tripId;
  final int userId;
  final String tripName;
  final String destination;
  final String startDate;
  final String endDate;
  final int travellerCount;
  final String status;
  final List<TripActivity> activities;
  final List<Booking> bookings;
  final Budget? budget;
  final List<Expense> expenses;

  Trip({
    required this.tripId,
    required this.userId,
    required this.tripName,
    required this.destination,
    required this.startDate,
    required this.endDate,
    this.travellerCount = 1,
    this.status = 'planned',
    this.activities = const [],
    this.bookings = const [],
    this.budget,
    this.expenses = const [],
  });

  factory Trip.fromJson(Map<String, dynamic> json) {
    List<TripActivity> acts = [];
    if (json['activities'] is List) {
      for (var a in json['activities']) {
        if (a is Map<String, dynamic>) {
          acts.add(TripActivity.fromJson(a));
        }
      }
    }

    List<Booking> bks = [];
    if (json['bookings'] is List) {
      for (var b in json['bookings']) {
        if (b is Map<String, dynamic>) {
          bks.add(Booking.fromJson(b));
        }
      }
    }

    List<Expense> exps = [];
    if (json['expenses'] is List) {
      for (var e in json['expenses']) {
        if (e is Map<String, dynamic>) {
          exps.add(Expense.fromJson(e));
        }
      }
    }

    Budget? bdgt;
    if (json['budget'] is Map<String, dynamic>) {
      bdgt = Budget.fromJson(json['budget']);
    }

    return Trip(
      tripId: json['trip_id'] ?? 0,
      userId: json['user_id'] ?? 0,
      tripName: json['trip_name'] ?? '',
      destination: json['destination'] ?? '',
      startDate: json['start_date'] ?? '',
      endDate: json['end_date'] ?? '',
      travellerCount: json['traveller_count'] ?? 1,
      status: json['status'] ?? 'planned',
      activities: acts,
      bookings: bks,
      budget: bdgt,
      expenses: exps,
    );
  }
}
