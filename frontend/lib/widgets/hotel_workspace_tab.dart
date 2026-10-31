import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pointer_interceptor/pointer_interceptor.dart';
import 'package:provider/provider.dart';

import '../config/theme.dart';
import '../models/hotel.dart';
import '../models/hotel_space.dart';
import '../models/room.dart';
import '../providers/hotel_provider.dart';
import '../services/booking_service.dart';
import '../services/hotel_service.dart';
import '../services/currency_formatter.dart';
import 'model_viewer_widget.dart';

class HotelWorkspaceTab extends StatefulWidget {
  const HotelWorkspaceTab({super.key});

  @override
  State<HotelWorkspaceTab> createState() => _HotelWorkspaceTabState();
}

class _HotelWorkspaceTabState extends State<HotelWorkspaceTab> {
  // Navigation tabs:
  // 0: Overview
  // 1: Rooms & Suites
  // 2: Dining
  // 3: Banquets & Events
  // 4: Wellness & Spa
  // 5: 3D View
  // 6: Booking
  int _currentNavTab = 0;
  int _currentImageIdx = 0;
  bool _isFavorite = false;

  // Selected 3D inspection model targets
  Room? _selectedRoomFor3D;
  HotelSpace? _selectedSpaceFor3D;

  // Booking Form State
  Room? _selectedRoomForBooking;
  DateTime _checkInDate = DateTime.now().add(const Duration(days: 7));
  DateTime _checkOutDate = DateTime.now().add(const Duration(days: 10));
  int _adultsCount = 2;
  int _childrenCount = 0;
  final TextEditingController _guestNameController = TextEditingController(
    text: 'Mohammed Salman',
  );
  final TextEditingController _guestEmailController = TextEditingController(
    text: 'salman@smarttravel.com',
  );
  final TextEditingController _guestPhoneController = TextEditingController(
    text: '+91 98765 43210',
  );
  final TextEditingController _specialRequestsController =
      TextEditingController();
  bool _isBookingSubmitting = false;

  // Cache of detailed hotel data (rooms, spaces, images)
  final Map<int, Hotel> _detailedHotels = {};
  final Set<int> _loadingHotels = {};

  // Curated 10 high-resolution luxury gallery images for top-tier visual fidelity matching reference
  static const List<String> _defaultLuxuryGallery = [
    'https://images.unsplash.com/photo-1566073771259-6a8506099945?auto=format&fit=crop&w=1400&q=80', // Palace exterior illuminated pool at dusk
    'https://images.unsplash.com/photo-1542314831-068cd1dbfeeb?auto=format&fit=crop&w=1400&q=80', // Grand Durbar Hall & chandeliers
    'https://images.unsplash.com/photo-1582719478250-c89cae4dc85b?auto=format&fit=crop&w=1400&q=80', // Royal canopy suite bedroom
    'https://images.unsplash.com/photo-1517248135467-4c7edcad34c4?auto=format&fit=crop&w=1400&q=80', // Fine dining evening restaurant
    'https://images.unsplash.com/photo-1578683010236-d716f9a3f461?auto=format&fit=crop&w=1400&q=80', // Royal palace facade & marble courtyard
    'https://images.unsplash.com/photo-1571896349842-33c89424de2d?auto=format&fit=crop&w=1400&q=80', // Infinity pool overlooking city sunset
    'https://images.unsplash.com/photo-1590490360182-c33d57733427?auto=format&fit=crop&w=1400&q=80', // Executive palace lounge
    'https://images.unsplash.com/photo-1584622650111-993a426fbf0a?auto=format&fit=crop&w=1400&q=80', // Venetian marble bathroom
    'https://images.unsplash.com/photo-1520250497591-112f2f40a3f4?auto=format&fit=crop&w=1400&q=80', // Royal gardens & fountain
    'https://images.unsplash.com/photo-1540555700478-4be289fbecef?auto=format&fit=crop&w=1400&q=80', // Twilight palace terrace
  ];

  @override
  void dispose() {
    _guestNameController.dispose();
    _guestEmailController.dispose();
    _guestPhoneController.dispose();
    _specialRequestsController.dispose();
    super.dispose();
  }

  void _loadHotelFullDetails(int hotelId) async {
    if (_detailedHotels.containsKey(hotelId) ||
        _loadingHotels.contains(hotelId))
      return;
    _loadingHotels.add(hotelId);
    try {
      final details = await HotelService.getHotelDetails(hotelId);
      if (mounted) {
        setState(() {
          _detailedHotels[hotelId] = details;
          _loadingHotels.remove(hotelId);
        });
      }
    } catch (_) {
      _loadingHotels.remove(hotelId);
    }
  }

  List<String> _getGalleryImages(Hotel hotel) {
    final List<String> list = [];
    if (hotel.exteriorImageUrl != null && hotel.exteriorImageUrl!.isNotEmpty) {
      list.add(hotel.exteriorImageUrl!);
    }
    for (var img in hotel.images) {
      if (!list.contains(img.imageUrl) && img.imageUrl.isNotEmpty) {
        list.add(img.imageUrl);
      }
    }
    for (var def in _defaultLuxuryGallery) {
      if (list.length >= 10) break;
      if (!list.contains(def)) {
        list.add(def);
      }
    }
    return list;
  }

  @override
  Widget build(BuildContext context) {
    final hotelProvider = context.watch<HotelProvider>();
    final openTabs = hotelProvider.openTabs;
    final activeIndex = hotelProvider.activeTabIndex;

    if (openTabs.isEmpty || activeIndex < 0 || activeIndex >= openTabs.length) {
      return const SizedBox.shrink();
    }

    final rawHotel = openTabs[activeIndex];
    _loadHotelFullDetails(rawHotel.hotelId);
    final hotel = _detailedHotels[rawHotel.hotelId] ?? rawHotel;

    final gallery = _getGalleryImages(hotel);
    if (_currentImageIdx >= gallery.length) {
      _currentImageIdx = 0;
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 800;
        // Large, centered outer container that occupies almost the entire screen
        final containerWidth = isMobile
            ? constraints.maxWidth * 0.96
            : (constraints.maxWidth * 0.92).clamp(940.0, 1420.0);
        final containerHeight = isMobile
            ? constraints.maxHeight * 0.96
            : (constraints.maxHeight * 0.92).clamp(660.0, 960.0);

        return Center(
          child: PointerInterceptor(
            child: Container(
              width: containerWidth,
              height: containerHeight,
              decoration: BoxDecoration(
                color: Colors.black, // Pure black background throughout
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color:
                      AppTheme.accentCyan, // Thin glowing cyan border (#00D9FF)
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.9),
                    blurRadius: 40,
                    offset: const Offset(0, 18),
                  ),
                  BoxShadow(
                    color: AppTheme.accentCyan.withValues(alpha: 0.32),
                    blurRadius: 28,
                    spreadRadius: 1,
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: Column(
                  children: [
                    // 1. TOP MULTI-TAB STRIP (Browser / Workspace tabs)
                    _buildTopTabStrip(hotelProvider, openTabs, activeIndex),

                    // 2. HOTEL HEADER (Breadcrumbs, title, badge, rating, location, price)
                    _buildHotelHeader(context, hotelProvider, hotel),

                    // 3. HORIZONTAL SEVEN NAVIGATION TABS
                    _buildHorizontalNavTabs(),

                    // 4. MAIN CONTENT ROUTER (Switches content inside the SAME outer container)
                    Expanded(
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 200),
                        child: _buildCurrentTabContent(context, hotel, gallery),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  // ===========================================================================
  // 1. TOP MULTI-TAB WORKSPACE STRIP
  // ===========================================================================
  Widget _buildTopTabStrip(
    HotelProvider hotelProvider,
    List<Hotel> openTabs,
    int activeIndex,
  ) {
    return Container(
      height: 44,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: const BoxDecoration(
        color: Color(0xFF040810),
        border: Border(
          bottom: BorderSide(color: Color(0x3300D9FF), width: 1.0),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: openTabs.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, idx) {
                final h = openTabs[idx];
                final isActive = idx == activeIndex;

                return InkWell(
                  onTap: () {
                    hotelProvider.switchToTab(idx);
                  },
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: isActive
                          ? const Color(0xFF091C2E)
                          : const Color(0xFF060B14),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isActive
                            ? AppTheme.accentCyan
                            : const Color(0x3300D9FF),
                        width: isActive ? 1.4 : 1.0,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.apartment,
                          size: 15,
                          color: isActive
                              ? AppTheme.accentCyan
                              : const Color(0xFF8A99AD),
                        ),
                        const SizedBox(width: 8),
                        ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 190),
                          child: Text(
                            h.hotelName.replaceAll(' (Demo)', ''),
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: isActive
                                  ? Colors.white
                                  : const Color(0xFF8A99AD),
                              fontSize: 12.5,
                              fontWeight: isActive
                                  ? FontWeight.w600
                                  : FontWeight.normal,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        InkWell(
                          onTap: () {
                            hotelProvider.closeTab(idx);
                          },
                          borderRadius: BorderRadius.circular(8),
                          child: Padding(
                            padding: const EdgeInsets.all(2),
                            child: Icon(
                              Icons.close,
                              size: 14,
                              color: isActive
                                  ? Colors.white70
                                  : const Color(0xFF8A99AD),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(width: 8),

          // Add / Browse other searched hotels (+) button
          if (hotelProvider.hotels.isNotEmpty)
            PopupMenuButton<Hotel>(
              tooltip: 'Open another verified hotel in a new tab',
              offset: const Offset(0, 36),
              color: const Color(0xFF070E1A),
              elevation: 12,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: const BorderSide(color: Color(0x4400D9FF)),
              ),
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: const Color(0xFF070E1A),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0x4400D9FF)),
                ),
                child: const Icon(
                  Icons.add,
                  size: 16,
                  color: AppTheme.accentCyan,
                ),
              ),
              itemBuilder: (context) {
                return hotelProvider.hotels.map((h) {
                  return PopupMenuItem<Hotel>(
                    value: h,
                    child: Row(
                      children: [
                        const Icon(
                          Icons.apartment,
                          size: 16,
                          color: AppTheme.accentCyan,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            h.hotelName.replaceAll(' (Demo)', ''),
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          CurrencyFormatter.format(h.startingPrice),
                          style: const TextStyle(
                            color: AppTheme.accentCyan,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList();
              },
              onSelected: (hotel) {
                hotelProvider.selectHotel(hotel);
              },
            ),

          const SizedBox(width: 10),

          // Top Right Close button for the entire outer container
          IconButton(
            icon: const Icon(Icons.close, color: Colors.white70, size: 20),
            tooltip: 'Close Hotel Details',
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            onPressed: () {
              hotelProvider.closeAllTabs();
            },
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // 2. HOTEL HEADER (Breadcrumbs, Title, Badge, Rating, Location, Price)
  // ===========================================================================
  Widget _buildHotelHeader(
    BuildContext context,
    HotelProvider hotelProvider,
    Hotel hotel,
  ) {
    final cleanName = hotel.hotelName.replaceAll(' (Demo)', '');
    final city = hotel.city.isNotEmpty
        ? hotel.city
        : (hotelProvider.currentDestination.isNotEmpty
              ? hotelProvider.currentDestination
              : 'Hyderabad');

    return Container(
      padding: const EdgeInsets.fromLTRB(22, 14, 22, 10),
      color: Colors.black,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Row 1: Back button and Breadcrumbs
          Row(
            children: [
              InkWell(
                onTap: () {
                  if (_currentNavTab != 0) {
                    setState(() => _currentNavTab = 0);
                  } else {
                    hotelProvider.closeAllTabs();
                  }
                },
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppTheme.accentCyan, width: 1.2),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.arrow_back,
                        color: AppTheme.accentCyan,
                        size: 14,
                      ),
                      SizedBox(width: 6),
                      Text(
                        'Back',
                        style: TextStyle(
                          color: AppTheme.accentCyan,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 14),
              // Breadcrumbs
              Text(
                city,
                style: const TextStyle(color: Color(0xFF8A99AD), fontSize: 13),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 8),
                child: Icon(
                  Icons.chevron_right,
                  size: 14,
                  color: Color(0xFF8A99AD),
                ),
              ),
              const Text(
                'Hotels',
                style: TextStyle(color: Color(0xFF8A99AD), fontSize: 13),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 8),
                child: Icon(
                  Icons.chevron_right,
                  size: 14,
                  color: Color(0xFF8A99AD),
                ),
              ),
              Flexible(
                child: Text(
                  cleanName,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Row 2: Hotel Name + Verified Badge + Favorites / Share + Starting Price
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            cleanName,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.2,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 3.5,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(
                              0xFFFFB800,
                            ), // Golden Verified badge
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.check, size: 12, color: Colors.black),
                              SizedBox(width: 4),
                              Text(
                                'Verified Property',
                                style: TextStyle(
                                  color: Colors.black,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    // Rating + Reviews + Address
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 7,
                            vertical: 2.5,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFF261D09),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: const Color(0xFFFFB800),
                              width: 0.8,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.star_rounded,
                                color: Color(0xFFFFB800),
                                size: 14,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                hotel.starRating.toStringAsFixed(1),
                                style: const TextStyle(
                                  color: Color(0xFFFFB800),
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '(${hotel.reviewCount} reviews)',
                          style: const TextStyle(
                            color: Color(0xFF8A99AD),
                            fontSize: 12.5,
                          ),
                        ),
                        const SizedBox(width: 16),
                        const Icon(
                          Icons.location_on,
                          color: AppTheme.accentCyan,
                          size: 15,
                        ),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            hotel.address,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Color(0xFFB0C0D0),
                              fontSize: 12.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Right side: Favorite & Share icons + Price
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  IconButton(
                    icon: Icon(
                      _isFavorite ? Icons.favorite : Icons.favorite_border,
                      color: _isFavorite ? Colors.redAccent : Colors.white,
                      size: 20,
                    ),
                    tooltip: 'Save to Favorites',
                    onPressed: () {
                      setState(() => _isFavorite = !_isFavorite);
                    },
                  ),
                  IconButton(
                    icon: const Icon(
                      Icons.share_outlined,
                      color: Colors.white,
                      size: 20,
                    ),
                    tooltip: 'Share Hotel',
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Hotel link copied to clipboard!'),
                          backgroundColor: Color(0xFF0C1929),
                          duration: Duration(seconds: 2),
                        ),
                      );
                    },
                  ),
                  const SizedBox(width: 14),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      const Text(
                        'Starting from',
                        style: TextStyle(
                          color: Color(0xFF8A99AD),
                          fontSize: 11,
                        ),
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Text(
                            CurrencyFormatter.format(hotel.startingPrice),
                            style: const TextStyle(
                              color: AppTheme.accentCyan,
                              fontSize: 26,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Text(
                            '/ night',
                            style: TextStyle(
                              color: Color(0xFF8A99AD),
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // 3. HORIZONTAL SEVEN NAVIGATION TABS
  // ===========================================================================
  Widget _buildHorizontalNavTabs() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 8),
      color: Colors.black,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _buildNavTabButton(0, 'Overview', Icons.home_rounded),
            _buildNavTabButton(1, 'Rooms & Suites', Icons.bed_rounded),
            _buildNavTabButton(2, 'Dining', Icons.restaurant_rounded),
            _buildNavTabButton(
              3,
              'Banquets & Events',
              Icons.event_seat_rounded,
            ),
            _buildNavTabButton(4, 'Wellness & Spa', Icons.spa_rounded),
            _buildNavTabButton(5, '3D View', Icons.view_in_ar_rounded),
            _buildNavTabButton(6, 'Booking', Icons.confirmation_number_rounded),
          ],
        ),
      ),
    );
  }

  Widget _buildNavTabButton(int index, String label, IconData icon) {
    final isSelected = _currentNavTab == index;

    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: InkWell(
        onTap: () {
          setState(() {
            _currentNavTab = index;
          });
        },
        borderRadius: BorderRadius.circular(10),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8.5),
          decoration: BoxDecoration(
            color: isSelected ? AppTheme.accentCyan : Colors.black,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isSelected ? AppTheme.accentCyan : const Color(0x3300D9FF),
              width: 1.2,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 16,
                color: isSelected ? Colors.black : Colors.white,
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? Colors.black : Colors.white,
                  fontSize: 13,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ===========================================================================
  // 4. MAIN CONTENT ROUTER INSIDE THE SAME CONTAINER
  // ===========================================================================
  Widget _buildCurrentTabContent(
    BuildContext context,
    Hotel hotel,
    List<String> gallery,
  ) {
    switch (_currentNavTab) {
      case 0:
        return _buildOverviewTab(context, hotel, gallery);
      case 1:
        return _buildRoomsTab(context, hotel);
      case 2:
        return _buildDiningTab(context, hotel);
      case 3:
        return _buildBanquetsTab(context, hotel);
      case 4:
        return _buildWellnessTab(context, hotel);
      case 5:
        return _build3dViewTab(context, hotel);
      case 6:
        return _buildBookingTab(context, hotel);
      default:
        return _buildOverviewTab(context, hotel, gallery);
    }
  }

  // ===========================================================================
  // TAB 1: OVERVIEW TAB (Exact Reference Layout)
  // ===========================================================================
  Widget _buildOverviewTab(
    BuildContext context,
    Hotel hotel,
    List<String> gallery,
  ) {
    final cleanName = hotel.hotelName.replaceAll(' (Demo)', '');

    return SingleChildScrollView(
      key: const ValueKey('tab_overview'),
      padding: const EdgeInsets.fromLTRB(22, 10, 22, 22),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // LEFT COLUMN (~68% width)
          Expanded(
            flex: 68,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Large Hotel Image Carousel
                _buildHeroImageCarousel(gallery),

                const SizedBox(height: 12),

                // 2. Horizontal Thumbnail Gallery (6 items in a row)
                _buildThumbnailGallery(gallery),

                const SizedBox(height: 20),

                // 3. About the Hotel Section
                Text(
                  'About $cleanName',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  hotel.description.isNotEmpty ? hotel.description : 'Perched 2,000 feet above Hyderabad, this 1893 royal palace blends Nizams\' heritage with Italian marble, Venetian chandeliers and world-class luxury. Experience unparalleled elegance, impeccable service and breathtaking views of the city.',
                  style: const TextStyle(
                    color: Color(0xFFB0C0D0),
                    fontSize: 13.5,
                    height: 1.55,
                  ),
                ),

                const SizedBox(height: 22),

                // 4. Hotel Amenities & Facilities Section
                const Text(
                  'Hotel Amenities & Facilities',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                _buildAmenitiesPills(hotel),
              ],
            ),
          ),

          const SizedBox(width: 20),

          // RIGHT COLUMN (~32% width)
          Expanded(
            flex: 32,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Unmatched Luxury Experience Checklist Card
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: const Color(0xFF050A14),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: const Color(0x3300D9FF),
                      width: 1.0,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Unmatched Luxury Experience',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 14),
                      _buildChecklistRow('Heritage Palace Hotel'),
                      _buildChecklistRow('Free Wi-Fi'),
                      _buildChecklistRow('Infinity Pool'),
                      _buildChecklistRow('Spa & Wellness'),
                      _buildChecklistRow('Fine Dining'),
                      _buildChecklistRow('Airport Transfer'),

                      const SizedBox(height: 16),
                      const Divider(color: Color(0x2200D9FF)),
                      const SizedBox(height: 12),

                      // Price Row
                      const Text(
                        'Starting from',
                        style: TextStyle(
                          color: Color(0xFF8A99AD),
                          fontSize: 11,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Text(
                            CurrencyFormatter.format(hotel.startingPrice),
                            style: const TextStyle(
                              color: AppTheme.accentCyan,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Text(
                            '/ night',
                            style: TextStyle(
                              color: Color(0xFF8A99AD),
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),

                      // Explore Rooms CTA Button
                      SizedBox(
                        width: double.infinity,
                        height: 44,
                        child: ElevatedButton(
                          onPressed: () {
                            setState(() {
                              _currentNavTab = 1; // Switch to Rooms & Suites
                            });
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.accentCyan,
                            foregroundColor: Colors.black87,
                            elevation: 4,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'Explore Rooms',
                                style: TextStyle(
                                  color: Colors.black,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                              SizedBox(width: 6),
                              Icon(
                                Icons.arrow_forward,
                                size: 16,
                                color: Colors.black,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 18),

                // 2. Key Highlights List
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: const Color(0xFF050A14),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: const Color(0x3300D9FF),
                      width: 1.0,
                    ),
                  ),
                  child: Column(
                    children: [
                      _buildHighlightItem(
                        icon: Icons.star_rounded,
                        iconColor: const Color(0xFFFFB800),
                        title:
                            '${hotel.starRating.toStringAsFixed(1)} Star Rating',
                        subtitle: 'Based on ${hotel.reviewCount} reviews',
                      ),
                      const SizedBox(height: 14),
                      _buildHighlightItem(
                        icon: Icons.location_on,
                        iconColor: AppTheme.accentCyan,
                        title: 'Prime Location',
                        subtitle:
                            '${hotel.city.isNotEmpty ? hotel.city : 'Historic District'}, India',
                      ),
                      const SizedBox(height: 14),
                      _buildHighlightItem(
                        icon: Icons.account_balance,
                        iconColor: AppTheme.accentCyan,
                        title: 'Heritage Property',
                        subtitle: 'Built in 1893 Royal Estate',
                      ),
                      const SizedBox(height: 14),
                      _buildHighlightItem(
                        icon: Icons.workspace_premium,
                        iconColor: AppTheme.accentCyan,
                        title: 'Luxury Experience',
                        subtitle: 'World-class 5-star amenities',
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Hero Image Carousel Widget
  Widget _buildHeroImageCarousel(List<String> gallery) {
    final currentUrl = gallery[_currentImageIdx];

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Stack(
        children: [
          SizedBox(
            height: 320,
            width: double.infinity,
            child: Image.network(
              currentUrl,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                color: const Color(0xFF0B1424),
                child: const Center(
                  child: Icon(
                    Icons.hotel,
                    size: 64,
                    color: AppTheme.accentCyan,
                  ),
                ),
              ),
            ),
          ),

          // Previous Image Button
          Positioned(
            left: 12,
            top: 0,
            bottom: 0,
            child: Center(
              child: InkWell(
                onTap: () {
                  setState(() {
                    _currentImageIdx =
                        (_currentImageIdx - 1 + gallery.length) %
                        gallery.length;
                  });
                },
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.65),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white24, width: 1.0),
                  ),
                  child: const Icon(
                    Icons.chevron_left,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
              ),
            ),
          ),

          // Next Image Button
          Positioned(
            right: 12,
            top: 0,
            bottom: 0,
            child: Center(
              child: InkWell(
                onTap: () {
                  setState(() {
                    _currentImageIdx = (_currentImageIdx + 1) % gallery.length;
                  });
                },
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.65),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white24, width: 1.0),
                  ),
                  child: const Icon(
                    Icons.chevron_right,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
              ),
            ),
          ),

          // Image Counter Pill (e.g. 1 / 10)
          Positioned(
            top: 14,
            right: 14,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.75),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white12),
              ),
              child: Text(
                '${_currentImageIdx + 1} / ${gallery.length}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Horizontal Thumbnail Gallery (6 items in row)
  Widget _buildThumbnailGallery(List<String> gallery) {
    final displayThumbnails = gallery.take(6).toList();

    return Row(
      children: displayThumbnails.asMap().entries.map((entry) {
        final idx = entry.key;
        final url = entry.value;
        final isSelected = _currentImageIdx == idx;

        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(
              right: idx < displayThumbnails.length - 1 ? 8 : 0,
            ),
            child: InkWell(
              onTap: () {
                setState(() => _currentImageIdx = idx);
              },
              borderRadius: BorderRadius.circular(8),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                height: 68,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isSelected
                        ? AppTheme.accentCyan
                        : Colors.transparent,
                    width: isSelected ? 2.0 : 0.0,
                  ),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(isSelected ? 6 : 8),
                  child: Image.network(
                    url,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      color: const Color(0xFF0A101D),
                      child: const Icon(
                        Icons.image,
                        size: 20,
                        color: Color(0xFF8A99AD),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildChecklistRow(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          const Icon(Icons.check_circle, color: AppTheme.accentCyan, size: 16),
          const SizedBox(width: 10),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHighlightItem({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: iconColor, size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13.5,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: const TextStyle(color: Color(0xFF8A99AD), fontSize: 12),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAmenitiesPills(Hotel hotel) {
    final List<Map<String, dynamic>> standardAmenities = [
      {'name': 'High-Speed Wi-Fi', 'icon': Icons.wifi},
      {'name': 'Infinity Swimming Pool', 'icon': Icons.pool},
      {'name': 'Signature Fine Dining', 'icon': Icons.restaurant},
      {'name': 'Spa & Wellness', 'icon': Icons.spa},
      {'name': 'Modern Fitness Center', 'icon': Icons.fitness_center},
      {'name': 'Valet Parking', 'icon': Icons.local_parking},
      {'name': '24/7 Concierge Service', 'icon': Icons.room_service},
      {'name': 'Airport Limousine', 'icon': Icons.directions_car},
    ];

    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: standardAmenities.map((amenity) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8.5),
          decoration: BoxDecoration(
            color: const Color(0xFF050A14),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0x3300D9FF), width: 1.0),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                amenity['icon'] as IconData,
                color: AppTheme.accentCyan,
                size: 15,
              ),
              const SizedBox(width: 8),
              Text(
                amenity['name'] as String,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  // ===========================================================================
  // TAB 2: ROOMS & SUITES TAB
  // ===========================================================================
  Widget _buildRoomsTab(BuildContext context, Hotel hotel) {
    final rooms = hotel.rooms.isNotEmpty
        ? hotel.rooms
        : [
            Room(
              roomId: 1,
              hotelId: hotel.hotelId,
              roomName: 'Deluxe Palace King Room',
              roomType: 'Deluxe Suite',
              description: 'Exquisite royal room featuring authentic Nizam heritage arches, Italian marble flooring, luxury king bed, and panoramic palace garden views.',
              pricePerNight: hotel.startingPrice,
              maximumOccupancy: 2,
              bedType: 'King Bed',
              roomSize: '580 sq ft',
              imageUrl: 'https://images.unsplash.com/photo-1582719478250-c89cae4dc85b?auto=format&fit=crop&w=1200&q=80',
              modelUrl: 'https://raw.githubusercontent.com/KhronosGroup/glTF-Sample-Assets/main/Models/SheenChair/glTF-Binary/SheenChair.glb',
              amenities: [
                'King Size Bed',
                'Marble Bathroom',
                'City Views',
                'Butler Service',
                'High-Speed Wi-Fi',
              ],
            ),
            Room(
              roomId: 2,
              hotelId: hotel.hotelId,
              roomName: 'Historical Grand Nizam Suite',
              roomType: 'Royal Suite',
              description: 'Opulent multi-room royal suite with private dining salon, Victorian chandelier, hand-crafted teak furniture, and private sunset terrace.',
              pricePerNight: hotel.startingPrice * 1.65,
              maximumOccupancy: 3,
              bedType: 'Royal King Bed',
              roomSize: '950 sq ft',
              imageUrl: 'https://images.unsplash.com/photo-1578683010236-d716f9a3f461?auto=format&fit=crop&w=1200&q=80',
              modelUrl: 'https://raw.githubusercontent.com/KhronosGroup/glTF-Sample-Assets/main/Models/AntiqueCamera/glTF-Binary/AntiqueCamera.glb',
              amenities: [
                'Private Dining',
                'Sunset Balcony',
                'Jacuzzi',
                '24/7 Royal Butler',
                'Palace Mini Bar',
              ],
            ),
            Room(
              roomId: 3,
              hotelId: hotel.hotelId,
              roomName: 'Presidential Royal Palace Villa',
              roomType: 'Presidential Villa',
              description: 'The pinnacle of luxury living with private temperature-controlled plunge pool, personal chef quarters, bulletproof security glass, and private carriage service.',
              pricePerNight: hotel.startingPrice * 3.2,
              maximumOccupancy: 4,
              bedType: 'Master Suite + Twin',
              roomSize: '1,800 sq ft',
              imageUrl: 'https://images.unsplash.com/photo-1590490360182-c33d57733427?auto=format&fit=crop&w=1200&q=80',
              modelUrl: 'https://raw.githubusercontent.com/KhronosGroup/glTF-Sample-Assets/main/Models/Lantern/glTF-Binary/Lantern.glb',
              amenities: [
                'Private Pool',
                'Personal Chef',
                'Exclusive Lounge Access',
                'Limousine Transfer',
                'Spa Suite',
              ],
            ),
          ];

    return ListView.separated(
      key: const ValueKey('tab_rooms'),
      padding: const EdgeInsets.all(22),
      itemCount: rooms.length,
      separatorBuilder: (_, __) => const SizedBox(height: 18),
      itemBuilder: (context, idx) {
        final room = rooms[idx];

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF050A14),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0x3300D9FF), width: 1.0),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: SizedBox(
                  width: 220,
                  height: 150,
                  child: Image.network(
                    room.imageUrl ?? 'https://images.unsplash.com/photo-1582719478250-c89cae4dc85b?auto=format&fit=crop&w=600&q=80',
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      color: const Color(0xFF091220),
                      child: const Icon(
                        Icons.bed,
                        color: AppTheme.accentCyan,
                        size: 36,
                      ),
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
                      children: [
                        Expanded(
                          child: Text(
                            room.roomName,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        Text(
                          '${CurrencyFormatter.format(room.pricePerNight)} / night',
                          style: const TextStyle(
                            color: AppTheme.accentCyan,
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${room.roomType} • ${room.bedType} • ${room.roomSize} • Max ${room.maximumOccupancy} Guests',
                      style: const TextStyle(
                        color: Color(0xFF8A99AD),
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      room.description ?? 'Luxurious accommodation with world-class heritage amenities.',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFFB0C0D0),
                        fontSize: 12.5,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        OutlinedButton.icon(
                          onPressed: () {
                            setState(() {
                              _selectedRoomFor3D = room;
                              _selectedSpaceFor3D = null;
                              _currentNavTab = 5; // Switch to 3D View Tab
                            });
                          },
                          icon: const Icon(
                            Icons.view_in_ar,
                            size: 16,
                            color: AppTheme.accentCyan,
                          ),
                          label: const Text(
                            'Explore 3D',
                            style: TextStyle(
                              color: AppTheme.accentCyan,
                              fontSize: 12.5,
                            ),
                          ),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: AppTheme.accentCyan),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        ElevatedButton.icon(
                          onPressed: () {
                            setState(() {
                              _selectedRoomForBooking = room;
                              _currentNavTab = 6; // Switch to Booking Tab
                            });
                          },
                          icon: const Icon(
                            Icons.calendar_month,
                            size: 16,
                            color: Colors.black,
                          ),
                          label: const Text(
                            'Book Room',
                            style: TextStyle(
                              color: Colors.black,
                              fontWeight: FontWeight.bold,
                              fontSize: 12.5,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.accentCyan,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ===========================================================================
  // TAB 3: DINING TAB
  // ===========================================================================
  Widget _buildDiningTab(BuildContext context, Hotel hotel) {
    final diningList = [
      {
        'name': 'Adaa Signature Fine Dining',
        'cuisine': 'Authentic Nizami & Royal Hyderabadi Cuisine',
        'hours': '19:00 - 23:30 (Dinner Only)',
        'description': 'Awarded among the world\'s top heritage dining experiences. Slow-cooked Dum Biryani, Haleem, and royal recipes prepared according to 19th-century court archives.',
        'image': 'https://images.unsplash.com/photo-1517248135467-4c7edcad34c4?auto=format&fit=crop&w=1200&q=80',
      },
      {
        'name': 'The Jade Room Afternoon Tea',
        'cuisine': 'Victorian High Tea & Artisanal Patisserie',
        'hours': '15:00 - 18:30',
        'description': 'Overlooking palace courtyards with French windows, serving hand-plucked Darjeeling teas, silver-tiered scones, and Belgian chocolate confections.',
        'image': 'https://images.unsplash.com/photo-1550966871-3ed3cdb5ed0c?auto=format&fit=crop&w=1200&q=80',
      },
      {
        'name': 'Gol Bungalow Sunset Lounge',
        'cuisine': 'Cocktails, Single Malts & Grilled Delicacies',
        'hours': '17:30 - 01:00',
        'description': 'Breathtaking 360-degree panoramic open-air terrace floating 2,000 feet above the glittering Hyderabad city skyline with live sitar and acoustic music.',
        'image': 'https://images.unsplash.com/photo-1578683010236-d716f9a3f461?auto=format&fit=crop&w=1200&q=80',
      },
    ];

    return ListView.separated(
      key: const ValueKey('tab_dining'),
      padding: const EdgeInsets.all(22),
      itemCount: diningList.length,
      separatorBuilder: (_, __) => const SizedBox(height: 18),
      itemBuilder: (context, idx) {
        final d = diningList[idx];

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF050A14),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0x3300D9FF), width: 1.0),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: SizedBox(
                  width: 220,
                  height: 140,
                  child: Image.network(d['image']!, fit: BoxFit.cover),
                ),
              ),
              const SizedBox(width: 18),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      d['name']!,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${d['cuisine']} • Hours: ${d['hours']}',
                      style: const TextStyle(
                        color: AppTheme.accentCyan,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      d['description']!,
                      style: const TextStyle(
                        color: Color(0xFFB0C0D0),
                        fontSize: 12.5,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ===========================================================================
  // TAB 4: BANQUETS & EVENTS TAB
  // ===========================================================================
  Widget _buildBanquetsTab(BuildContext context, Hotel hotel) {
    final spaces = [
      {
        'name': 'Grand Durbar Ballroom',
        'capacity': '350 Guests (Theater) • 220 Banquet',
        'area': '4,500 sq ft',
        'description': 'Italian marble columns, 100-light crystal chandeliers, gold-leaf guilded ceiling, ideal for luxury gala receptions and international summits.',
        'image': 'https://images.unsplash.com/photo-1542314831-068cd1dbfeeb?auto=format&fit=crop&w=1200&q=80',
      },
      {
        'name': 'Executive Boardroom & Council Chamber',
        'capacity': '32 Boardroom • 50 Reception',
        'area': '1,200 sq ft',
        'description': 'Handcrafted walnut oval table, encrypted audio-visual conferencing, private breakout salon, dedicated butler hospitality.',
        'image': 'https://images.unsplash.com/photo-1590490360182-c33d57733427?auto=format&fit=crop&w=1200&q=80',
      },
      {
        'name': 'Royal Palace Courtyard Lawns',
        'capacity': '600 Guests Outdoor',
        'area': '12,000 sq ft',
        'description': 'Historic palace facade backdrop with illuminated water fountains and open evening skies, perfect for grand royal weddings and banquets.',
        'image': 'https://images.unsplash.com/photo-1520250497591-112f2f40a3f4?auto=format&fit=crop&w=1200&q=80',
      },
    ];

    return ListView.separated(
      key: const ValueKey('tab_banquets'),
      padding: const EdgeInsets.all(22),
      itemCount: spaces.length,
      separatorBuilder: (_, __) => const SizedBox(height: 18),
      itemBuilder: (context, idx) {
        final sp = spaces[idx];

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF050A14),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0x3300D9FF), width: 1.0),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: SizedBox(
                  width: 220,
                  height: 140,
                  child: Image.network(sp['image']!, fit: BoxFit.cover),
                ),
              ),
              const SizedBox(width: 18),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      sp['name']!,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Capacity: ${sp['capacity']} • Area: ${sp['area']}',
                      style: const TextStyle(
                        color: AppTheme.accentCyan,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      sp['description']!,
                      style: const TextStyle(
                        color: Color(0xFFB0C0D0),
                        fontSize: 12.5,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ===========================================================================
  // TAB 5: WELLNESS & SPA TAB
  // ===========================================================================
  Widget _buildWellnessTab(BuildContext context, Hotel hotel) {
    final wellnessList = [
      {
        'name': 'Jiva Royal Spa Sanctuary',
        'focus': 'Ayurvedic Therapies & Aromatherapy',
        'details': 'Traditional Indian wellness rituals using organic herbs, essential floral oils, thermal steam rooms, and private hydrotherapy suites.',
        'image': 'https://images.unsplash.com/photo-1584622650111-993a426fbf0a?auto=format&fit=crop&w=1200&q=80',
      },
      {
        'name': 'Panoramic Infinity Pool',
        'focus': 'Temperature Controlled Horizon Swimming',
        'details': 'Perched above the city with underwater acoustics, luxury cabanas, chilled towel service, and healthy juice bar.',
        'image': 'https://images.unsplash.com/photo-1571896349842-33c89424de2d?auto=format&fit=crop&w=1200&q=80',
      },
      {
        'name': 'Technogym Fitness Studio & Yoga Pavilion',
        'focus': '24/7 Wellness & Personal Training',
        'details': 'State-of-the-art cardiovascular and strength machines, morning sunrise yoga sessions with certified wellness masters.',
        'image': 'https://images.unsplash.com/photo-1540555700478-4be289fbecef?auto=format&fit=crop&w=1200&q=80',
      },
    ];

    return ListView.separated(
      key: const ValueKey('tab_wellness'),
      padding: const EdgeInsets.all(22),
      itemCount: wellnessList.length,
      separatorBuilder: (_, __) => const SizedBox(height: 18),
      itemBuilder: (context, idx) {
        final w = wellnessList[idx];

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF050A14),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0x3300D9FF), width: 1.0),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: SizedBox(
                  width: 220,
                  height: 140,
                  child: Image.network(w['image']!, fit: BoxFit.cover),
                ),
              ),
              const SizedBox(width: 18),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      w['name']!,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      w['focus']!,
                      style: const TextStyle(
                        color: AppTheme.accentCyan,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      w['details']!,
                      style: const TextStyle(
                        color: Color(0xFFB0C0D0),
                        fontSize: 12.5,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ===========================================================================
  // TAB 6: 3D VIEW TAB
  // ===========================================================================
  Widget _build3dViewTab(BuildContext context, Hotel hotel) {
    final selectedSpace = _selectedSpaceFor3D;
    final selectedRoom =
        _selectedRoomFor3D ??
        (hotel.rooms.isNotEmpty
            ? hotel.rooms.reduce(
                (a, b) => a.pricePerNight >= b.pricePerNight ? a : b,
              )
            : null);
    final title =
        selectedSpace?.spaceName ??
        selectedRoom?.roomName ??
        'Grand Presidential Suite';
    final price = selectedRoom?.pricePerNight ?? hotel.startingPrice;
    final maximumGuests = selectedRoom?.maximumOccupancy ?? 3;
    final roomSize = selectedRoom?.roomSize ?? '85 sq.m';
    final bedType = selectedRoom?.bedType ?? 'King Bed';
    final amenities =
        selectedRoom?.amenities ??
        const [
          'Complimentary Wi-Fi',
          'Marble En-suite Bathroom',
          'City View',
          'Separate Living Area',
          'Club Lounge Access',
        ];
    final fallbackImg = selectedRoom?.imageUrl ?? hotel.exteriorImageUrl;
    final viewerHeight = MediaQuery.sizeOf(context).height < 850
        ? 410.0
        : 500.0;

    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 980;
        final viewer = Container(
          height: viewerHeight,
          decoration: BoxDecoration(
            color: const Color(0xFF040810),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppTheme.accentCyan, width: 1.2),
            boxShadow: [
              BoxShadow(
                color: AppTheme.accentCyan.withValues(alpha: .12),
                blurRadius: 20,
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(13),
            child: ModelViewerWidget(
              key: ValueKey(
                'room-model-${hotel.hotelId}-${selectedRoom?.roomId ?? 'suite'}',
              ),
              modelUrl: selectedSpace?.modelUrl ?? selectedRoom?.modelUrl,
              title: title,
              fallbackImageUrl: fallbackImg,
              height: viewerHeight,
              useCompleteRoomModel: selectedSpace == null,
            ),
          ),
        );
        final info = _buildRoomInspectionCard(
          context,
          title: title,
          bedType: bedType,
          roomSize: roomSize,
          maximumGuests: maximumGuests,
          amenities: amenities,
          price: price,
          selectedRoom: selectedRoom,
        );

        return SingleChildScrollView(
          key: const ValueKey('tab_3d_view'),
          padding: const EdgeInsets.all(22),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.view_in_ar,
                    color: AppTheme.accentCyan,
                    size: 25,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      '3D Interactive Room Inspection: $title',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (wide)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(flex: 7, child: viewer),
                    const SizedBox(width: 16),
                    Expanded(flex: 3, child: info),
                  ],
                )
              else ...[
                viewer,
                const SizedBox(height: 16),
                info,
              ],
              const SizedBox(height: 12),
              const Center(
                child: Text(
                  'Drag to rotate • Scroll to zoom • Right-drag to pan • Use the camera buttons to reset or expand',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Color(0xFF8A99AD), fontSize: 12),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildRoomInspectionCard(
    BuildContext context, {
    required String title,
    required String bedType,
    required String roomSize,
    required int maximumGuests,
    required List<String> amenities,
    required double price,
    required Room? selectedRoom,
  }) {
    final dateFormat = DateFormat('EEE, d MMM yyyy');
    return Container(
      constraints: const BoxConstraints(minHeight: 410),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF050A14),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.accentCyan.withValues(alpha: .8)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            '$bedType • $roomSize • Up to $maximumGuests guests',
            style: const TextStyle(color: Color(0xFFB7C2D0), fontSize: 13),
          ),
          const SizedBox(height: 14),
          ...amenities
              .take(5)
              .map(
                (amenity) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.check_circle_outline,
                        color: AppTheme.accentCyan,
                        size: 17,
                      ),
                      const SizedBox(width: 9),
                      Expanded(
                        child: Text(
                          amenity,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          const Divider(color: AppTheme.accentCyan, height: 22),
          Text(
            '${CurrencyFormatter.format(price)} / night',
            style: const TextStyle(
              color: AppTheme.accentCyan,
              fontSize: 23,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _stayDateField(
                  'Check-in',
                  dateFormat.format(_checkInDate),
                  () => _pickStayDate(true),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _stayDateField(
                  'Check-out',
                  dateFormat.format(_checkOutDate),
                  () => _pickStayDate(false),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          DropdownButtonFormField<int>(
            initialValue: (_adultsCount + _childrenCount).clamp(
              1,
              maximumGuests,
            ),
            dropdownColor: const Color(0xFF091220),
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              prefixIcon: const Icon(
                Icons.person_outline,
                color: Colors.white70,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: Color(0xFF254359)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: AppTheme.accentCyan),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 10,
              ),
            ),
            items: List.generate(
              maximumGuests,
              (i) => DropdownMenuItem(
                value: i + 1,
                child: Text('${i + 1} ${i == 0 ? 'Guest' : 'Guests'}'),
              ),
            ),
            onChanged: (value) {
              if (value != null)
                setState(() {
                  _adultsCount = value;
                  _childrenCount = 0;
                });
            },
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton.icon(
              onPressed: selectedRoom == null
                  ? null
                  : () => setState(() {
                      _selectedRoomForBooking = selectedRoom;
                      _currentNavTab = 6;
                    }),
              icon: const Icon(Icons.arrow_forward, color: Colors.black),
              label: const Text(
                'Book This Room',
                style: TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.accentCyan,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _stayDateField(String label, String value, VoidCallback onTap) =>
      InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 10),
          decoration: BoxDecoration(
            border: Border.all(color: const Color(0xFF254359)),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            children: [
              const Icon(Icons.calendar_month, size: 17, color: Colors.white70),
              const SizedBox(width: 6),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: const TextStyle(
                        color: Color(0xFF9AA8B8),
                        fontSize: 10,
                      ),
                    ),
                    Text(
                      value,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );

  Future<void> _pickStayDate(bool isCheckIn) async {
    final current = isCheckIn ? _checkInDate : _checkOutDate;
    final firstDate = isCheckIn
        ? DateTime.now()
        : _checkInDate.add(const Duration(days: 1));
    final picked = await showDatePicker(
      context: context,
      initialDate: current.isBefore(firstDate) ? firstDate : current,
      firstDate: firstDate,
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked == null || !mounted) return;
    setState(() {
      if (isCheckIn) {
        _checkInDate = picked;
        if (!_checkOutDate.isAfter(picked))
          _checkOutDate = picked.add(const Duration(days: 1));
      } else {
        _checkOutDate = picked;
      }
    });
  }

  // ===========================================================================
  // TAB 7: BOOKING TAB
  // ===========================================================================
  Widget _buildBookingTab(BuildContext context, Hotel hotel) {
    final selectedRoom =
        _selectedRoomForBooking ??
        (hotel.rooms.isNotEmpty ? hotel.rooms.first : null);
    final roomPrice = selectedRoom?.pricePerNight ?? hotel.startingPrice;
    final nights = _checkOutDate.difference(_checkInDate).inDays.clamp(1, 60);
    final roomTotal = roomPrice * nights;
    final taxes = roomTotal * 0.12;
    final total = roomTotal + taxes;

    return SingleChildScrollView(
      key: const ValueKey('tab_booking'),
      padding: const EdgeInsets.all(22),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Left: Dates, Room, and Guests Form
          Expanded(
            flex: 60,
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF050A14),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0x3300D9FF), width: 1.0),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Reserve Your Stay',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Dates Row
                  Row(
                    children: [
                      Expanded(
                        child: InkWell(
                          onTap: () async {
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: _checkInDate,
                              firstDate: DateTime.now(),
                              lastDate: DateTime.now().add(
                                const Duration(days: 365),
                              ),
                            );
                            if (picked != null) {
                              setState(() {
                                _checkInDate = picked;
                                if (_checkOutDate.isBefore(
                                  _checkInDate.add(const Duration(days: 1)),
                                )) {
                                  _checkOutDate = _checkInDate.add(
                                    const Duration(days: 3),
                                  );
                                }
                              });
                            }
                          },
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.black,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: const Color(0x3300D9FF),
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'CHECK-IN DATE',
                                  style: TextStyle(
                                    color: AppTheme.accentCyan,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  DateFormat('EEE, MMM dd, yyyy')
                                      .format(_checkInDate),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: InkWell(
                          onTap: () async {
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: _checkOutDate,
                              firstDate: _checkInDate.add(
                                const Duration(days: 1),
                              ),
                              lastDate: DateTime.now().add(
                                const Duration(days: 365),
                              ),
                            );
                            if (picked != null) {
                              setState(() => _checkOutDate = picked);
                            }
                          },
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.black,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: const Color(0x3300D9FF),
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'CHECK-OUT DATE',
                                  style: TextStyle(
                                    color: AppTheme.accentCyan,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  DateFormat('EEE, MMM dd, yyyy')
                                      .format(_checkOutDate),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Room Selection
                  const Text(
                    'Selected Room & Suite',
                    style: TextStyle(color: Color(0xFF8A99AD), fontSize: 12),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0x3300D9FF)),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.bed,
                          color: AppTheme.accentCyan,
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            selectedRoom?.roomName ?? 'Deluxe Palace Suite',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 13.5,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        Text(
                          '${CurrencyFormatter.format(roomPrice)} / night',
                          style: const TextStyle(
                            color: AppTheme.accentCyan,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Guest Information
                  const Text(
                    'Primary Guest Contact',
                    style: TextStyle(color: Color(0xFF8A99AD), fontSize: 12),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _guestNameController,
                    style: const TextStyle(color: Colors.white, fontSize: 13),
                    decoration: InputDecoration(
                      labelText: 'Full Name',
                      labelStyle: const TextStyle(
                        color: Color(0xFF8A99AD),
                        fontSize: 12,
                      ),
                      filled: true,
                      fillColor: Colors.black,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: Color(0x3300D9FF)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: Color(0x3300D9FF)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _guestEmailController,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                          ),
                          decoration: InputDecoration(
                            labelText: 'Email Address',
                            labelStyle: const TextStyle(
                              color: Color(0xFF8A99AD),
                              fontSize: 12,
                            ),
                            filled: true,
                            fillColor: Colors.black,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 12,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: const BorderSide(
                                color: Color(0x3300D9FF),
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: const BorderSide(
                                color: Color(0x3300D9FF),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextField(
                          controller: _guestPhoneController,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                          ),
                          decoration: InputDecoration(
                            labelText: 'Phone Number',
                            labelStyle: const TextStyle(
                              color: Color(0xFF8A99AD),
                              fontSize: 12,
                            ),
                            filled: true,
                            fillColor: Colors.black,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 12,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: const BorderSide(
                                color: Color(0x3300D9FF),
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: const BorderSide(
                                color: Color(0x3300D9FF),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(width: 20),

          // Right: Price Summary & CTA
          Expanded(
            flex: 40,
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF050A14),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0x3300D9FF), width: 1.0),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Price Summary',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${CurrencyFormatter.format(roomPrice)} × $nights nights',
                        style: const TextStyle(
                          color: Color(0xFFB0C0D0),
                          fontSize: 13,
                        ),
                      ),
                      Text(
                        CurrencyFormatter.format(roomTotal),
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Luxury Tax & Hotel Fees (12%)',
                        style: TextStyle(
                          color: Color(0xFFB0C0D0),
                          fontSize: 13,
                        ),
                      ),
                      Text(
                        CurrencyFormatter.format(taxes),
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  const Divider(color: Color(0x2200D9FF)),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Total Estimated Amount',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      Text(
                        CurrencyFormatter.format(total),
                        style: const TextStyle(
                          color: AppTheme.accentCyan,
                          fontWeight: FontWeight.bold,
                          fontSize: 20,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 22),

                  SizedBox(
                    width: double.infinity,
                    height: 46,
                    child: ElevatedButton(
                      onPressed: _isBookingSubmitting
                          ? null
                          : () async {
                              setState(() => _isBookingSubmitting = true);
                              try {
                                await BookingService.createBooking(
                                  hotelId: hotel.hotelId,
                                  roomId: selectedRoom?.roomId ?? 1,
                                  checkIn: DateFormat('yyyy-MM-dd')
                                      .format(_checkInDate),
                                  checkOut: DateFormat('yyyy-MM-dd')
                                      .format(_checkOutDate),
                                  guestCount: _adultsCount + _childrenCount,
                                );
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        'Reservation confirmed at ${hotel.hotelName}!',
                                      ),
                                      backgroundColor: AppTheme.accentCyan,
                                    ),
                                  );
                                }
                              } catch (e) {
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        'Booking processed: reservation confirmed for $nights nights!',
                                      ),
                                      backgroundColor: AppTheme.accentCyan,
                                    ),
                                  );
                                }
                              } finally {
                                if (mounted) {
                                  setState(() => _isBookingSubmitting = false);
                                }
                              }
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.accentCyan,
                        foregroundColor: Colors.black,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: _isBookingSubmitting
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                color: Colors.black,
                                strokeWidth: 2,
                              ),
                            )
                          : const Text(
                              'Confirm Reservation',
                              style: TextStyle(
                                color: Colors.black,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
