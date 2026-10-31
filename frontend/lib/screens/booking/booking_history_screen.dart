import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../models/booking.dart';
import '../../providers/auth_provider.dart';
import '../../providers/booking_provider.dart';
import '../../services/currency_formatter.dart';
import '../../widgets/loading_widget.dart';

class BookingHistoryScreen extends StatefulWidget {
  const BookingHistoryScreen({super.key});

  @override
  State<BookingHistoryScreen> createState() => _BookingHistoryScreenState();
}

class _BookingHistoryScreenState extends State<BookingHistoryScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = context.read<AuthProvider>();
      if (auth.isAuthenticated) {
        context.read<BookingProvider>().fetchBookings();
      }
    });
  }

  Future<void> _cancelBooking(Booking booking) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.cardNavy,
        title: const Text('Cancel Booking?', style: TextStyle(color: Colors.white)),
        content: Text('Are you sure you want to cancel your reservation for ${booking.roomName ?? "this room"} at ${booking.hotelName ?? "hotel"}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Keep Booking', style: TextStyle(color: AppTheme.textMuted)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.accentRose),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Cancel Reservation'),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      await context.read<BookingProvider>().cancelBooking(booking.bookingId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Reservation cancelled successfully')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final bookingProvider = context.watch<BookingProvider>();

    return Scaffold(
      backgroundColor: AppTheme.darkNavy,
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A1224),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => context.pop(),
        ),
        title: const Text(
          'MY HOTEL BOOKINGS & RESERVATIONS',
          style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold, letterSpacing: 1.2),
        ),
      ),
      body: !auth.isAuthenticated
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.lock_outline, color: AppTheme.textMuted, size: 52),
                  const SizedBox(height: 16),
                  const Text('Please sign in to view your bookings', style: TextStyle(color: Colors.white, fontSize: 16)),
                  const SizedBox(height: 16),
                  ElevatedButton(onPressed: () => context.push('/login'), child: const Text('Sign In')),
                ],
              ),
            )
          : bookingProvider.isLoading
              ? const LoadingWidget(message: 'Fetching reservations from database...')
              : bookingProvider.bookings.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.bookmark_border, color: AppTheme.textMuted, size: 52),
                          const SizedBox(height: 16),
                          const Text('No bookings found', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 8),
                          const Text('Discover luxury hotels on the 3D globe and make your first reservation.', style: TextStyle(color: AppTheme.textMuted)),
                          const SizedBox(height: 20),
                          ElevatedButton.icon(
                            icon: const Icon(Icons.public, size: 18),
                            label: const Text('Explore Globe'),
                            onPressed: () => context.go('/'),
                          ),
                        ],
                      ),
                    )
                  : Center(
                      child: Container(
                        constraints: const BoxConstraints(maxWidth: 960),
                        padding: const EdgeInsets.all(24),
                        child: ListView.separated(
                          itemCount: bookingProvider.bookings.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 16),
                          itemBuilder: (context, index) {
                            final b = bookingProvider.bookings[index];
                            final isCancelled = b.bookingStatus == 'cancelled';

                            return Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: AppTheme.cardNavy,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: AppTheme.borderNavy),
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(12),
                                    child: Container(
                                      width: 130,
                                      height: 95,
                                      decoration: BoxDecoration(
                                        image: DecorationImage(
                                          image: NetworkImage(b.roomImage ?? b.hotelImage ?? 'https://images.unsplash.com/photo-1566073771259-6a8506099945?auto=format&fit=crop&w=600&q=80'),
                                          fit: BoxFit.cover,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 18),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Expanded(
                                              child: Text(
                                                b.hotelName ?? 'Luxury Hotel',
                                                style: const TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold),
                                              ),
                                            ),
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                              decoration: BoxDecoration(
                                                color: isCancelled ? AppTheme.accentRose.withOpacity(0.2) : AppTheme.accentEmerald.withOpacity(0.2),
                                                borderRadius: BorderRadius.circular(6),
                                              ),
                                              child: Text(
                                                b.bookingStatus.toUpperCase(),
                                                style: TextStyle(
                                                  color: isCancelled ? AppTheme.accentRose : AppTheme.accentEmerald,
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 4),
                                        Text(b.roomName ?? 'Suite', style: const TextStyle(color: AppTheme.accentCyan, fontSize: 14, fontWeight: FontWeight.w500)),
                                        const SizedBox(height: 8),
                                        Text(
                                          'Stay: ${b.checkIn} to ${b.checkOut} (${b.numberOfNights} nights) • ${b.guestCount} Guests',
                                          style: const TextStyle(color: AppTheme.textMuted, fontSize: 13),
                                        ),
                                        const SizedBox(height: 6),
                                        Text(
                                          'Total: ${CurrencyFormatter.format(b.totalAmount)}',
                                          style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
                                        ),
                                      ],
                                    ),
                                  ),
                                  if (!isCancelled) ...[
                                    const SizedBox(width: 16),
                                    OutlinedButton(
                                      style: OutlinedButton.styleFrom(foregroundColor: AppTheme.accentRose),
                                      onPressed: () => _cancelBooking(b),
                                      child: const Text('Cancel'),
                                    ),
                                  ],
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                    ),
    );
  }
}
