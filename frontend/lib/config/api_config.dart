class ApiConfig {
  // Base URL for the Flask Backend API
  // Using localhost / 127.0.0.1 for local execution on port 5001
  static const String baseUrl = 'http://127.0.0.1:5001/api';

  // Auth endpoints
  static const String login = '$baseUrl/auth/login';
  static const String register = '$baseUrl/auth/register';
  static const String logout = '$baseUrl/auth/logout';
  static const String profile = '$baseUrl/auth/profile';

  // Destinations endpoints
  static const String destinations = '$baseUrl/destinations';
  static const String destinationSearch = '$baseUrl/destinations/search';
  static const String destinationGeocode = '$baseUrl/destinations/geocode';

  // Hotels endpoints
  static const String hotelSearch = '$baseUrl/hotels/search';
  static String hotelDetails(int id) => '$baseUrl/hotels/$id';
  static String hotelImages(int id) => '$baseUrl/hotels/$id/images';
  static String hotelFacilities(int id) => '$baseUrl/hotels/$id/facilities';
  static String hotelSpaces(int id) => '$baseUrl/hotels/$id/spaces';
  static String hotelRooms(int id) => '$baseUrl/hotels/$id/rooms';

  // Spaces & Rooms
  static String roomDetails(int id) => '$baseUrl/rooms/$id';
  static String spaceDetails(int id) => '$baseUrl/hotel-spaces/$id';

  // Bookings
  static const String bookings = '$baseUrl/bookings';
  static String bookingDetails(int id) => '$baseUrl/bookings/$id';
  static String cancelBooking(int id) => '$baseUrl/bookings/$id/cancel';

  // Trips
  static const String trips = '$baseUrl/trips';
  static String tripDetails(int id) => '$baseUrl/trips/$id';
  static String tripActivities(int id) => '$baseUrl/trips/$id/activities';
  static String deleteActivity(int id) => '$baseUrl/trips/activities/$id';

  // Budgets
  static String budget(int tripId) => '$baseUrl/budgets/$tripId';

  // Expenses
  static const String expenses = '$baseUrl/expenses';
  static String tripExpenses(int tripId) => '$baseUrl/expenses/$tripId';
  static String expenseDetails(int id) => '$baseUrl/expenses/$id';
}
