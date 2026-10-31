import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../config/theme.dart';
import '../models/hotel.dart';
import '../providers/hotel_provider.dart';

class HotelSidePanel extends StatelessWidget {
  final Hotel hotel;
  final VoidCallback onClose;

  const HotelSidePanel({
    super.key,
    required this.hotel,
    required this.onClose,
  });

  Future<void> _openGoogleMaps(Hotel h) async {
    final query = Uri.encodeComponent('${h.hotelName}, ${h.address}, ${h.city}');
    final url = Uri.parse('https://www.google.com/maps/search/?api=1&query=$query');
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _pickDate(BuildContext context, bool isCheckIn) async {
    final hotelProvider = context.read<HotelProvider>();
    final initialDate = isCheckIn ? hotelProvider.checkInDate : hotelProvider.checkOutDate;
    final firstDate = isCheckIn ? DateTime.now() : hotelProvider.checkInDate.add(const Duration(days: 1));
    final lastDate = DateTime.now().add(const Duration(days: 365));

    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: firstDate,
      lastDate: lastDate,
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
      if (isCheckIn) {
        DateTime newCheckOut = hotelProvider.checkOutDate;
        if (!newCheckOut.isAfter(picked)) {
          newCheckOut = picked.add(const Duration(days: 1));
        }
        hotelProvider.setDates(picked, newCheckOut);
      } else {
        hotelProvider.setDates(hotelProvider.checkInDate, picked);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final hotelProvider = context.watch<HotelProvider>();
    final dateFormat = DateFormat('MMM dd, yyyy');

    return Container(
      width: 440,
      decoration: BoxDecoration(
        color: const Color(0xFF0D172E).withOpacity(0.97),
        border: const Border(
          left: BorderSide(color: AppTheme.borderNavy, width: 1.5),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.6),
            blurRadius: 30,
            offset: const Offset(-8, 0),
          )
        ],
      ),
      child: Column(
        children: [
          // Header with Close Button and Title
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: AppTheme.borderNavy, width: 1)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppTheme.accentCyan.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppTheme.accentCyan.withOpacity(0.4)),
                      ),
                      child: const Text(
                        'FEATURED PROPERTY',
                        style: TextStyle(
                          color: AppTheme.accentCyan,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.1,
                        ),
                      ),
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white70, size: 22),
                  onPressed: onClose,
                  tooltip: 'Close Panel',
                ),
              ],
            ),
          ),

          // Scrollable Content
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              children: [
                // 1. HOTEL EXTERIOR PHOTOGRAPH (CLICKABLE -> EXPLORE HOTEL)
                MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: GestureDetector(
                    onTap: () {
                      context.push('/hotel/${hotel.hotelId}');
                    },
                    child: Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: Container(
                            height: 220,
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: AppTheme.cardNavy,
                              image: hotel.exteriorImageUrl != null
                                  ? DecorationImage(
                                      image: NetworkImage(hotel.exteriorImageUrl!),
                                      fit: BoxFit.cover,
                                    )
                                  : null,
                            ),
                            child: hotel.exteriorImageUrl == null
                                ? const Center(child: Icon(Icons.apartment, size: 60, color: Colors.white30))
                                : null,
                          ),
                        ),
                        // Hover hint badge
                        Positioned(
                          bottom: 12,
                          right: 12,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.75),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: AppTheme.accentCyan.withOpacity(0.8)),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.touch_app, color: AppTheme.accentCyan, size: 14),
                                SizedBox(width: 6),
                                Text(
                                  'Click to Explore Interior & 3D',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        // Demo badge if applicable
                        if (hotel.isDemo)
                          Positioned(
                            top: 12,
                            left: 12,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.75),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Text(
                                'DEMO PROPERTY',
                                style: TextStyle(color: AppTheme.accentGold, fontSize: 10, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 18),

                // Hotel Name & Star Rating
                Text(
                  hotel.hotelName,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: -0.3,
                  ),
                ),

                const SizedBox(height: 8),

                // Ratings & Reviews
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppTheme.accentGold.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.star, color: AppTheme.accentGold, size: 16),
                          const SizedBox(width: 4),
                          Text(
                            hotel.starRating.toStringAsFixed(1),
                            style: const TextStyle(
                              color: AppTheme.accentGold,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '★ ${hotel.reviewRating.toStringAsFixed(1)} (${hotel.reviewCount} reviews)',
                      style: const TextStyle(color: AppTheme.textMuted, fontSize: 13),
                    ),
                    const Spacer(),
                    if (hotel.formattedDistance != null)
                      Text(
                        hotel.formattedDistance!,
                        style: const TextStyle(color: AppTheme.accentCyan, fontSize: 12, fontWeight: FontWeight.w600),
                      ),
                  ],
                ),

                const SizedBox(height: 12),

                // Address
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.location_on, color: AppTheme.accentCyan, size: 18),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        hotel.address,
                        style: const TextStyle(color: AppTheme.textMuted, fontSize: 13, height: 1.4),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 14),

                // Description
                Text(
                  hotel.description,
                  style: const TextStyle(color: Colors.white70, fontSize: 13.5, height: 1.5),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),

                const SizedBox(height: 20),
                const Divider(color: AppTheme.borderNavy),
                const SizedBox(height: 12),

                // 2. HOTEL INFORMATION & FACILITIES
                const Text(
                  'HOTEL AMENITIES & FACILITIES',
                  style: TextStyle(
                    color: AppTheme.accentCyan,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.0,
                  ),
                ),
                const SizedBox(height: 12),

                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: (hotel.facilitiesList.isNotEmpty
                          ? hotel.facilitiesList
                          : [
                              'High-Speed Wi-Fi',
                              'Infinity Swimming Pool',
                              'Fine Dining',
                              'Wellness Spa',
                              'Valet Parking',
                              '24/7 Concierge'
                            ])
                      .take(6)
                      .map((fac) {
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppTheme.cardNavy,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppTheme.borderNavy),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.check_circle_outline, color: AppTheme.accentEmerald, size: 14),
                          const SizedBox(width: 6),
                          Text(
                            fac,
                            style: const TextStyle(color: Colors.white, fontSize: 12),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),

                const SizedBox(height: 20),
                const Divider(color: AppTheme.borderNavy),
                const SizedBox(height: 12),

                // 3. EXPENSE ESTIMATION MODULE
                const Text(
                  'ESTIMATED TRIP ACCOMMODATION EXPENSE',
                  style: TextStyle(
                    color: AppTheme.accentCyan,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.0,
                  ),
                ),
                const SizedBox(height: 14),

                // Date Selectors
                Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: () => _pickDate(context, true),
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppTheme.cardNavy,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppTheme.borderNavy),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Check-In', style: TextStyle(color: AppTheme.textMuted, fontSize: 11)),
                              const SizedBox(height: 4),
                              Text(
                                dateFormat.format(hotelProvider.checkInDate),
                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: InkWell(
                        onTap: () => _pickDate(context, false),
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppTheme.cardNavy,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppTheme.borderNavy),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Check-Out', style: TextStyle(color: AppTheme.textMuted, fontSize: 11)),
                              const SizedBox(height: 4),
                              Text(
                                dateFormat.format(hotelProvider.checkOutDate),
                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 14),

                // Price Breakdown Card
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF13203C),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppTheme.borderNavy),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '\$${hotel.startingPrice.toStringAsFixed(0)} × ${hotelProvider.estimatedNights} nights',
                            style: const TextStyle(color: Colors.white70, fontSize: 13),
                          ),
                          Text(
                            '\$${hotelProvider.estimatedAccommodationCost.toStringAsFixed(2)}',
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Estimated Taxes & Service (12%)',
                            style: TextStyle(color: AppTheme.textMuted, fontSize: 12),
                          ),
                          Text(
                            '\$${hotelProvider.estimatedTaxesAndFees.toStringAsFixed(2)}',
                            style: const TextStyle(color: Colors.white70, fontSize: 12),
                          ),
                        ],
                      ),
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 10),
                        child: Divider(color: AppTheme.borderNavy, height: 1),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Estimated Total',
                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                          ),
                          Text(
                            '\$${hotelProvider.estimatedTotalCost.toStringAsFixed(2)} ${hotel.currency}',
                            style: const TextStyle(
                              color: AppTheme.accentCyan,
                              fontWeight: FontWeight.bold,
                              fontSize: 17,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // 4. PANEL ACTIONS
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.map, size: 18),
                        label: const Text('Google Maps'),
                        onPressed: () => _openGoogleMaps(hotel),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.travel_explore, size: 20),
                        label: const Text('Explore Hotel & 3D'),
                        onPressed: () {
                          context.push('/hotel/${hotel.hotelId}');
                        },
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
