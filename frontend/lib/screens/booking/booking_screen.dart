import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../models/hotel.dart';
import '../../models/room.dart';
import '../../providers/auth_provider.dart';
import '../../providers/booking_provider.dart';
import '../../services/hotel_service.dart';
import '../../widgets/error_widget.dart';
import '../../widgets/loading_widget.dart';

class BookingScreen extends StatefulWidget {
  final int hotelId;
  final int roomId;

  const BookingScreen({
    super.key,
    required this.hotelId,
    required this.roomId,
  });

  @override
  State<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends State<BookingScreen> {
  DateTime _checkIn = DateTime.now().add(const Duration(days: 7));
  DateTime _checkOut = DateTime.now().add(const Duration(days: 10));
  int _adults = 2;
  int _children = 0;
  bool _isSubmitting = false;

  late Future<Map<String, dynamic>> _dataFuture;

  @override
  void initState() {
    super.initState();
    _dataFuture = _loadData();
  }

  Future<Map<String, dynamic>> _loadData() async {
    final hotel = await HotelService.getHotelDetails(widget.hotelId);
    final room = await HotelService.getRoomDetails(widget.roomId);
    return {'hotel': hotel, 'room': room};
  }

  int get _nights {
    final diff = _checkOut.difference(_checkIn).inDays;
    return diff > 0 ? diff : 1;
  }

  Future<void> _pickDate(bool isCheckIn) async {
    final initial = isCheckIn ? _checkIn : _checkOut;
    final first = isCheckIn ? DateTime.now() : _checkIn.add(const Duration(days: 1));
    final last = DateTime.now().add(const Duration(days: 365));

    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: first,
      lastDate: last,
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: const ColorScheme.dark(
              primary: AppTheme.accentCyan,
              surface: AppTheme.cardNavy,
              onSurface: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        if (isCheckIn) {
          _checkIn = picked;
          if (!_checkOut.isAfter(_checkIn)) {
            _checkOut = _checkIn.add(const Duration(days: 1));
          }
        } else {
          _checkOut = picked;
        }
      });
    }
  }

  Future<void> _handleConfirmBooking(Room room) async {
    final auth = context.read<AuthProvider>();
    if (!auth.isAuthenticated) {
      final shouldLogin = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: AppTheme.cardNavy,
          title: const Text('Authentication Required', style: TextStyle(color: Colors.white)),
          content: const Text(
            'Please sign in to securely link this hotel reservation to your travel profile.',
            style: TextStyle(color: AppTheme.textMuted),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel', style: TextStyle(color: AppTheme.textMuted)),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Sign In'),
            ),
          ],
        ),
      );

      if (shouldLogin == true && mounted) {
        context.push('/login');
      }
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    final dateFormat = DateFormat('yyyy-MM-dd');
    final checkInStr = dateFormat.format(_checkIn);
    final checkOutStr = dateFormat.format(_checkOut);

    final success = await context.read<BookingProvider>().createBooking(
      hotelId: widget.hotelId,
      roomId: widget.roomId,
      checkIn: checkInStr,
      checkOut: checkOutStr,
      guestCount: _adults + _children,
    );

    if (mounted) {
      setState(() {
        _isSubmitting = false;
      });

      if (success) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (ctx) => AlertDialog(
            backgroundColor: AppTheme.cardNavy,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: const Row(
              children: [
                Icon(Icons.check_circle, color: AppTheme.accentEmerald, size: 28),
                SizedBox(width: 10),
                Text('Booking Confirmed!', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Your reservation for ${room.roomName} has been recorded in the MySQL database.',
                  style: const TextStyle(color: Colors.white70),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0F1B34),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Dates: $checkInStr to $checkOutStr ($_nights nights)', style: const TextStyle(color: Colors.white, fontSize: 13)),
                      const SizedBox(height: 4),
                      Text('Guests: ${_adults + _children} ($adultsSummary)', style: const TextStyle(color: AppTheme.textMuted, fontSize: 12)),
                      const SizedBox(height: 4),
                      const Text('Payment: Demonstration Instant Confirmation', style: TextStyle(color: AppTheme.accentGold, fontSize: 12, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  context.go('/bookings');
                },
                child: const Text('View All Bookings', style: TextStyle(color: AppTheme.accentCyan)),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  context.go('/');
                },
                child: const Text('Return to Globe'),
              ),
            ],
          ),
        );
      } else {
        final err = context.read<BookingProvider>().errorMessage ?? 'Failed to complete booking';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(err), backgroundColor: AppTheme.accentRose),
        );
      }
    }
  }

  String get adultsSummary => '$_adults Adults${_children > 0 ? ', $_children Children' : ''}';

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('EEE, MMM dd, yyyy');

    return Scaffold(
      backgroundColor: AppTheme.darkNavy,
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A1224),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => context.pop(),
        ),
        title: const Text(
          'CONFIRM HOTEL RESERVATION',
          style: TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
          ),
        ),
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _dataFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const LoadingWidget(message: 'Loading booking summary...');
          }
          if (snapshot.hasError) {
            return CustomErrorWidget(
              message: 'Failed to load details: ${snapshot.error}',
              onRetry: () {
                setState(() {
                  _dataFuture = _loadData();
                });
              },
            );
          }

          final hotel = snapshot.data!['hotel'] as Hotel;
          final room = snapshot.data!['room'] as Room;

          final subtotal = room.pricePerNight * _nights;
          final taxes = subtotal * 0.12;
          final total = subtotal + taxes;

          return Center(
            child: Container(
              constraints: const BoxConstraints(maxWidth: 860),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
              child: ListView(
                children: [
                  // Property Overview Card
                  Container(
                    padding: const EdgeInsets.all(18),
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
                            width: 140,
                            height: 100,
                            decoration: BoxDecoration(
                              image: DecorationImage(
                                image: NetworkImage(room.imageUrl ?? hotel.exteriorImageUrl ?? ''),
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
                              Text(
                                hotel.hotelName,
                                style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                room.roomName,
                                style: const TextStyle(color: AppTheme.accentCyan, fontSize: 15, fontWeight: FontWeight.w600),
                              ),
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  const Icon(Icons.location_on, color: AppTheme.textMuted, size: 14),
                                  const SizedBox(width: 4),
                                  Expanded(
                                    child: Text(
                                      hotel.address,
                                      style: const TextStyle(color: AppTheme.textMuted, fontSize: 12),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Dates and Guests Picker Card
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppTheme.cardNavy,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppTheme.borderNavy),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'STAY DATES & GUEST CONFIGURATION',
                          style: TextStyle(color: AppTheme.accentCyan, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.1),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: InkWell(
                                onTap: () => _pickDate(true),
                                borderRadius: BorderRadius.circular(12),
                                child: Container(
                                  padding: const EdgeInsets.all(14),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF13203C),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: AppTheme.borderNavy),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text('Check-In Date', style: TextStyle(color: AppTheme.textMuted, fontSize: 12)),
                                      const SizedBox(height: 4),
                                      Text(dateFormat.format(_checkIn), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: InkWell(
                                onTap: () => _pickDate(false),
                                borderRadius: BorderRadius.circular(12),
                                child: Container(
                                  padding: const EdgeInsets.all(14),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF13203C),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: AppTheme.borderNavy),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text('Check-Out Date', style: TextStyle(color: AppTheme.textMuted, fontSize: 12)),
                                      const SizedBox(height: 4),
                                      Text(dateFormat.format(_checkOut), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        // Guests Selector
                        Row(
                          children: [
                            const Text('Adults:', style: TextStyle(color: Colors.white70, fontSize: 14)),
                            const SizedBox(width: 10),
                            IconButton(
                              icon: const Icon(Icons.remove_circle_outline, color: AppTheme.accentCyan),
                              onPressed: _adults > 1 ? () => setState(() => _adults--) : null,
                            ),
                            Text('$_adults', style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                            IconButton(
                              icon: const Icon(Icons.add_circle_outline, color: AppTheme.accentCyan),
                              onPressed: _adults < room.maximumOccupancy ? () => setState(() => _adults++) : null,
                            ),
                            const SizedBox(width: 24),
                            const Text('Children:', style: TextStyle(color: Colors.white70, fontSize: 14)),
                            const SizedBox(width: 10),
                            IconButton(
                              icon: const Icon(Icons.remove_circle_outline, color: AppTheme.accentCyan),
                              onPressed: _children > 0 ? () => setState(() => _children--) : null,
                            ),
                            Text('$_children', style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                            IconButton(
                              icon: const Icon(Icons.add_circle_outline, color: AppTheme.accentCyan),
                              onPressed: (_adults + _children) < room.maximumOccupancy ? () => setState(() => _children++) : null,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Pricing Breakdown Card
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppTheme.cardNavy,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppTheme.borderNavy),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'PRICE CALCULATION BREAKDOWN',
                          style: TextStyle(color: AppTheme.accentCyan, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.1),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('\$${room.pricePerNight.toStringAsFixed(0)} × $_nights nights', style: const TextStyle(color: Colors.white70, fontSize: 14)),
                            Text('\$${subtotal.toStringAsFixed(2)}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14)),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Configured Taxes & Fees (12%)', style: TextStyle(color: AppTheme.textMuted, fontSize: 13)),
                            Text('\$${taxes.toStringAsFixed(2)}', style: const TextStyle(color: Colors.white70, fontSize: 13)),
                          ],
                        ),
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 14),
                          child: Divider(color: AppTheme.borderNavy, height: 1),
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Total Accommodation Cost', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                            Text(
                              '\$${total.toStringAsFixed(2)} ${hotel.currency}',
                              style: const TextStyle(color: AppTheme.accentCyan, fontWeight: FontWeight.bold, fontSize: 22),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 28),

                  // Confirm Button
                  SizedBox(
                    height: 52,
                    child: ElevatedButton(
                      onPressed: _isSubmitting ? null : () => _handleConfirmBooking(room),
                      child: _isSubmitting
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.2),
                            )
                          : const Text('Confirm & Reserve Room', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
