import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../config/theme.dart';
import '../../models/hotel.dart';
import '../../services/hotel_service.dart';
import '../../widgets/error_widget.dart';
import '../../widgets/exterior_gallery.dart';
import '../../widgets/hotel_space_card.dart';
import '../../widgets/loading_widget.dart';
import '../../widgets/room_card.dart';
import '../../services/currency_formatter.dart';

class HotelDetailsScreen extends StatefulWidget {
  final int hotelId;

  const HotelDetailsScreen({super.key, required this.hotelId});

  @override
  State<HotelDetailsScreen> createState() => _HotelDetailsScreenState();
}

class _HotelDetailsScreenState extends State<HotelDetailsScreen> with SingleTickerProviderStateMixin {
  late Future<Hotel> _hotelFuture;
  late TabController _tabController;

  final List<String> _categories = [
    'Rooms & Suites',
    'Banquet & Conference Halls',
    'Restaurants & Lounges',
    'Spa, Pool & Wellness',
  ];

  @override
  void initState() {
    super.initState();
    _hotelFuture = HotelService.getHotelDetails(widget.hotelId);
    _tabController = TabController(length: _categories.length, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _openGoogleMaps(Hotel h) async {
    final query = Uri.encodeComponent('${h.hotelName}, ${h.address}, ${h.city}');
    final url = Uri.parse('https://www.google.com/maps/search/?api=1&query=$query');
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.darkNavy,
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A1224),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => context.pop(),
        ),
        title: const Text(
          'HOTEL PROPERTY EXPLORATION',
          style: TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
          ),
        ),
        actions: [
          TextButton.icon(
            icon: const Icon(Icons.public, color: AppTheme.accentCyan, size: 18),
            label: const Text('Back to Globe', style: TextStyle(color: AppTheme.accentCyan)),
            onPressed: () => context.go('/'),
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: FutureBuilder<Hotel>(
        future: _hotelFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const LoadingWidget(message: 'Loading luxury property details...');
          }
          if (snapshot.hasError) {
            return CustomErrorWidget(
              message: 'Failed to load hotel: ${snapshot.error}',
              onRetry: () {
                setState(() {
                  _hotelFuture = HotelService.getHotelDetails(widget.hotelId);
                });
              },
            );
          }

          final hotel = snapshot.data!;

          return SingleChildScrollView(
            child: Center(
              child: Container(
                constraints: const BoxConstraints(maxWidth: 1200),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 1. HOTEL EXTERIOR GALLERY
                    ExteriorGallery(
                      images: hotel.images,
                      defaultHeroUrl: hotel.exteriorImageUrl,
                    ),

                    const SizedBox(height: 28),

                    // 2. HOTEL HEADER & BASIC INFORMATION
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: AppTheme.accentGold.withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Row(
                                      children: [
                                        const Icon(Icons.star, color: AppTheme.accentGold, size: 16),
                                        const SizedBox(width: 4),
                                        Text(
                                          '${hotel.starRating.toStringAsFixed(1)} Star Luxury',
                                          style: const TextStyle(
                                            color: AppTheme.accentGold,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 13,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Text(
                                    '★ ${hotel.reviewRating.toStringAsFixed(1)} rating (${hotel.reviewCount} verified guest reviews)',
                                    style: const TextStyle(color: AppTheme.textMuted, fontSize: 13),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              Text(
                                hotel.hotelName,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 32,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: -0.5,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  const Icon(Icons.location_on, color: AppTheme.accentCyan, size: 18),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      '${hotel.address}, ${hotel.city}, ${hotel.country}',
                                      style: const TextStyle(color: AppTheme.textMuted, fontSize: 14),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),

                        // Starting Price Card
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: AppTheme.cardNavy,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: AppTheme.borderNavy),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              const Text('Starting from', style: TextStyle(color: AppTheme.textMuted, fontSize: 12)),
                              const SizedBox(height: 4),
                              RichText(
                                text: TextSpan(
                                  children: [
                                    TextSpan(
                                      text: CurrencyFormatter.format(hotel.startingPrice),
                                      style: const TextStyle(
                                        color: AppTheme.accentCyan,
                                        fontSize: 28,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const TextSpan(
                                      text: ' / night',
                                      style: TextStyle(color: AppTheme.textMuted, fontSize: 13),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 12),
                              ElevatedButton.icon(
                                icon: const Icon(Icons.map, size: 18),
                                label: const Text('View on Map'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppTheme.cardNavyHover,
                                ),
                                onPressed: () => _openGoogleMaps(hotel),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    // Hotel Description
                    Text(
                      hotel.description,
                      style: const TextStyle(color: Colors.white70, fontSize: 15, height: 1.6),
                    ),

                    const SizedBox(height: 24),

                    // Verified Property Facilities
                    const Text(
                      'VERIFIED PROPERTY FACILITIES',
                      style: TextStyle(
                        color: AppTheme.accentCyan,
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: hotel.facilitiesList.map((fac) {
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: AppTheme.cardNavy,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: AppTheme.borderNavy),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.check_circle, color: AppTheme.accentEmerald, size: 16),
                              const SizedBox(width: 8),
                              Text(fac, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500)),
                            ],
                          ),
                        );
                      }).toList(),
                    ),

                    const SizedBox(height: 40),
                    const Divider(color: AppTheme.borderNavy),
                    const SizedBox(height: 24),

                    // 3. EXPLORE THE HOTEL SECTION (Rooms, Suites, Halls, Lounges)
                    const Text(
                      'EXPLORE THE HOTEL',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Browse guest suites, conference facilities, and rooftop dining spaces. Click "Explore 3D" on any space to launch the interactive 3D model viewer.',
                      style: TextStyle(color: AppTheme.textMuted, fontSize: 14),
                    ),

                    const SizedBox(height: 20),

                    // Category Tabs
                    Container(
                      decoration: const BoxDecoration(
                        border: Border(bottom: BorderSide(color: AppTheme.borderNavy)),
                      ),
                      child: TabBar(
                        controller: _tabController,
                        isScrollable: true,
                        tabAlignment: TabAlignment.start,
                        indicatorColor: AppTheme.accentCyan,
                        labelColor: AppTheme.accentCyan,
                        unselectedLabelColor: AppTheme.textMuted,
                        labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                        tabs: _categories.map((c) => Tab(text: c)).toList(),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Tab View Content
                    SizedBox(
                      height: 820,
                      child: TabBarView(
                        controller: _tabController,
                        children: [
                          // Tab 1: Rooms & Suites
                          _buildRoomsGrid(hotel.rooms, hotel),

                          // Tab 2: Banquet & Conference Halls
                          _buildSpacesGrid(
                            hotel.spaces.where((s) => s.category.contains('hall')).toList(),
                          ),

                          // Tab 3: Restaurants & Lounges
                          _buildSpacesGrid(
                            hotel.spaces.where((s) => s.category == 'restaurant' || s.category == 'lounge').toList(),
                          ),

                          // Tab 4: Spa, Pool & Wellness
                          _buildSpacesGrid(
                            hotel.spaces.where((s) => s.category == 'spa' || s.category == 'pool' || s.category == 'gym').toList(),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildRoomsGrid(List rooms, Hotel hotel) {
    if (rooms.isEmpty) {
      return const Center(
        child: Text('No rooms found for this property.', style: TextStyle(color: AppTheme.textMuted)),
      );
    }
    return GridView.builder(
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 380,
        mainAxisExtent: 440,
        crossAxisSpacing: 18,
        mainAxisSpacing: 18,
      ),
      itemCount: rooms.length,
      itemBuilder: (context, index) {
        final room = rooms[index];
        return RoomCard(
          room: room,
          onBook: () {
            context.push('/book?hotel_id=${hotel.hotelId}&room_id=${room.roomId}');
          },
        );
      },
    );
  }

  Widget _buildSpacesGrid(List spaces) {
    if (spaces.isEmpty) {
      return const Center(
        child: Text('No spaces in this category.', style: TextStyle(color: AppTheme.textMuted)),
      );
    }
    return GridView.builder(
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 380,
        mainAxisExtent: 390,
        crossAxisSpacing: 18,
        mainAxisSpacing: 18,
      ),
      itemCount: spaces.length,
      itemBuilder: (context, index) {
        final space = spaces[index];
        return HotelSpaceCard(space: space);
      },
    );
  }
}
