import 'package:go_router/go_router.dart';
import '../screens/authentication/login_screen.dart';
import '../screens/authentication/register_screen.dart';
import '../screens/booking/booking_history_screen.dart';
import '../screens/booking/booking_screen.dart';
import '../screens/budget/budget_screen.dart';
import '../screens/globe_home/globe_home_screen.dart';
import '../screens/hotel_details/hotel_details_screen.dart';
import '../screens/itinerary/itinerary_screen.dart';
import '../screens/my_trips/my_trips_screen.dart';
import '../screens/profile/profile_screen.dart';
import '../screens/room_details/room_3d_screen.dart';
import '../screens/space_details/space_3d_screen.dart';

class AppRoutes {
  static final router = GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const GlobeHomeScreen(),
      ),
      GoRoute(
        path: '/hotel/:id',
        builder: (context, state) {
          final id = int.tryParse(state.pathParameters['id'] ?? '') ?? 1;
          return HotelDetailsScreen(hotelId: id);
        },
      ),
      GoRoute(
        path: '/room/:id',
        builder: (context, state) {
          final id = int.tryParse(state.pathParameters['id'] ?? '') ?? 1;
          return Room3dScreen(roomId: id);
        },
      ),
      GoRoute(
        path: '/space/:id',
        builder: (context, state) {
          final id = int.tryParse(state.pathParameters['id'] ?? '') ?? 1;
          return Space3dScreen(spaceId: id);
        },
      ),
      GoRoute(
        path: '/book',
        builder: (context, state) {
          final hotelId = int.tryParse(state.uri.queryParameters['hotel_id'] ?? '') ?? 1;
          final roomId = int.tryParse(state.uri.queryParameters['room_id'] ?? '') ?? 1;
          return BookingScreen(hotelId: hotelId, roomId: roomId);
        },
      ),
      GoRoute(
        path: '/bookings',
        builder: (context, state) => const BookingHistoryScreen(),
      ),
      GoRoute(
        path: '/trips',
        builder: (context, state) => const MyTripsScreen(),
      ),
      GoRoute(
        path: '/itinerary/:id',
        builder: (context, state) {
          final id = int.tryParse(state.pathParameters['id'] ?? '') ?? 1;
          return ItineraryScreen(tripId: id);
        },
      ),
      GoRoute(
        path: '/budget/:id',
        builder: (context, state) {
          final id = int.tryParse(state.pathParameters['id'] ?? '') ?? 1;
          return BudgetScreen(tripId: id);
        },
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: '/profile',
        builder: (context, state) => const ProfileScreen(),
      ),
    ],
  );
}
