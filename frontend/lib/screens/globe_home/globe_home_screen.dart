import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:pointer_interceptor/pointer_interceptor.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/globe_provider.dart';
import '../../providers/hotel_provider.dart';
import '../../services/destination_service.dart';
import '../../widgets/destination_search_bar.dart';
import '../../widgets/hotel_workspace_tab.dart';
import '../../widgets/hyderabad_discovery_map.dart';
import '../../widgets/interactive_globe.dart';

enum DiscoveryViewMode { map, list, globe }

class GlobeHomeScreen extends StatefulWidget {
  final String? initialSearch;
  final int? initialHotelId;
  const GlobeHomeScreen({super.key, this.initialSearch, this.initialHotelId});

  @override
  State<GlobeHomeScreen> createState() => _GlobeHomeScreenState();
}

class _GlobeHomeScreenState extends State<GlobeHomeScreen> {
  DiscoveryViewMode _viewMode = DiscoveryViewMode.map;

  @override
  void initState() {
    super.initState();
    // Default to search Hyderabad and load 9 verified hotels immediately
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _runSearch(widget.initialSearch?.trim().isNotEmpty == true ? widget.initialSearch!.trim() : 'Hyderabad');
    });
  }

  Future<void> _runSearch(String query) async {
    try {
      final geo = await DestinationService.geocode(query);
      final double lat = (geo['latitude'] as num).toDouble();
      final double lng = (geo['longitude'] as num).toDouble();
      final String name = geo['name'] ?? query;

      if (mounted) {
        context.read<GlobeProvider>().setCoordinates(lat, lng, animate: true);
        await context.read<HotelProvider>().searchHotels(
          latitude: lat,
          longitude: lng,
          destination: name,
        );
        if (widget.initialHotelId != null && mounted) {
          final hp = context.read<HotelProvider>();
          for (var h in hp.hotels) {
            if (h.hotelId == widget.initialHotelId) {
              hp.selectHotel(h);
              break;
            }
          }
        }
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final hotelProvider = context.watch<HotelProvider>();
    final authProvider = context.watch<AuthProvider>();
    final selectedHotel = hotelProvider.selectedHotel;
    final screenWidth = MediaQuery.sizeOf(context).width;
    final isDesktop = screenWidth >= 780;

    return Scaffold(
      backgroundColor: Colors.black, // Pure Black Background
      body: Stack(
        fit: StackFit.expand,
        children: [
          // ==========================================
          // LAYER 1: BASE HOMEPAGE (Interactive Satellite Map / Globe, Sidebar & Controls)
          // ==========================================

          // 1a. Interactive Map / Globe View (Fullscreen behind sidebar)
          if (_viewMode == DiscoveryViewMode.map)
            Positioned(
              top: 0,
              bottom: 0,
              left: isDesktop ? 175 : 0,
              right: 0,
              child: HyderabadDiscoveryMap(
                isBlurred: hotelProvider.hasOpenTabs,
                onHotelSelected: (hotel) {
                  hotelProvider.selectHotel(hotel);
                },
              ),
            )
          else if (_viewMode == DiscoveryViewMode.globe)
            Positioned.fill(
              child: InteractiveGlobe(
                hotels: hotelProvider.hotels,
                selectedHotel: selectedHotel,
                isBlurred: hotelProvider.hasOpenTabs,
                onHotelSelected: (hotel) {
                  hotelProvider.selectHotel(hotel);
                },
              ),
            )
          else
            Positioned(
              top: 80,
              bottom: 0,
              left: isDesktop ? 195 : 16,
              right: 16,
              child: _buildHotelCardsListView(context, hotelProvider),
            ),

          // 1b. Left Vertical Sidebar (Desktop / Tablet)
          if (isDesktop)
            Positioned(
              top: 0,
              bottom: 0,
              left: 0,
              width: 175,
              child: PointerInterceptor(
                child: _buildLeftSidebar(context, authProvider, hotelProvider),
              ),
            ),

          // 1c. Mobile Top Bar (Compact screens only)
          if (!isDesktop)
            Positioned(
              top: 16,
              left: 16,
              right: 16,
              child: PointerInterceptor(
                child: _buildMobileTopBar(context, hotelProvider),
              ),
            ),

          // 1d. Destination Search Bar (Centered at top between sidebar and toggle)
          Positioned(
            top: isDesktop ? 16 : 76,
            left: isDesktop ? 175 : 0,
            right: isDesktop ? 175 : 0,
            child: Center(
              child: PointerInterceptor(
                child: DestinationSearchBar(
                  initialValue: 'Hyderabad',
                  onDestinationSelected: (query, lat, lng) {
                    // Search updates hotels and coordinates
                  },
                ),
              ),
            ),
          ),

          // 1e. Top-Right Map / List Toggle
          if (isDesktop)
            Positioned(
              top: 16,
              right: 20,
              child: PointerInterceptor(
                child: _buildTopRightToggle(),
              ),
            ),

          // 1f. Hotel Status Indicator Pill (Shown in globe mode)
          if (_viewMode == DiscoveryViewMode.globe && hotelProvider.hotels.isNotEmpty)
            Positioned(
              top: isDesktop ? 88 : 140,
              left: isDesktop ? 195 : 20,
              child: PointerInterceptor(
                child: _buildHotelStatusIndicator(context, hotelProvider),
              ),
            ),

          // 1g. Loading indicator overlay during hotel search
          if (hotelProvider.isLoading)
            Positioned(
              bottom: 36,
              right: 36,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFF091224).withValues(alpha: 0.95),
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(color: AppTheme.accentCyan, width: 1.2),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withValues(alpha: 0.5), blurRadius: 16),
                  ],
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2.2, color: AppTheme.accentCyan),
                    ),
                    SizedBox(width: 12),
                    Text(
                      'Discovering verified hotels...',
                      style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ),
            ),

          // ==========================================
          // LAYER 2: BLUR & DARK TRANSLUCENT OVERLAY
          // ==========================================
          if (hotelProvider.hasOpenTabs)
            Positioned.fill(
              child: GestureDetector(
                onTap: () {
                  hotelProvider.closeAllTabs();
                  context.read<GlobeProvider>().resetView();
                },
                child: TweenAnimationBuilder<double>(
                  tween: Tween<double>(begin: 0.0, end: 1.0),
                  duration: const Duration(milliseconds: 280),
                  curve: Curves.easeOutCubic,
                  builder: (context, value, child) {
                    return Opacity(
                      opacity: value,
                      child: ClipRect(
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 10.0 * value, sigmaY: 10.0 * value),
                          child: Container(
                            color: Colors.black.withValues(alpha: 0.55 * value),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),

          // ==========================================
          // LAYER 3: HOTEL WORKSPACE (RAZOR SHARP FOREGROUND)
          // ==========================================
          if (hotelProvider.hasOpenTabs)
            Positioned(
              top: 0,
              bottom: 0,
              left: isDesktop ? 175 : 0,
              right: 0,
              child: PointerInterceptor(
                child: const HotelWorkspaceTab(),
              ),
            ),
        ],
      ),
    );
  }

  // Top-Right Toggle: Unified pill holding [ Map ] and [ List ] matching visual reference
  Widget _buildTopRightToggle() {
    final isMap = _viewMode == DiscoveryViewMode.map;

    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: const Color(0xFF050E1B).withValues(alpha: 0.90),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFF1E2E4A), width: 1.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.6),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Map Button
          InkWell(
            onTap: () {
              setState(() {
                _viewMode = DiscoveryViewMode.map;
              });
            },
            borderRadius: BorderRadius.circular(18),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
              decoration: BoxDecoration(
                color: isMap ? const Color(0xFF091F38) : Colors.transparent,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: isMap ? AppTheme.accentCyan : Colors.transparent,
                  width: isMap ? 1.4 : 0.0,
                ),
                boxShadow: isMap
                    ? [
                        BoxShadow(
                          color: AppTheme.accentCyan.withValues(alpha: 0.35),
                          blurRadius: 8,
                          spreadRadius: 0.5,
                        ),
                      ]
                    : [],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.map_outlined,
                    size: 16,
                    color: isMap ? AppTheme.accentCyan : Colors.white70,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Map',
                    style: TextStyle(
                      color: isMap ? Colors.white : Colors.white70,
                      fontSize: 12.5,
                      fontWeight: isMap ? FontWeight.w700 : FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // List Button
          InkWell(
            onTap: () {
              setState(() {
                _viewMode = DiscoveryViewMode.list;
              });
            },
            borderRadius: BorderRadius.circular(18),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
              decoration: BoxDecoration(
                color: !isMap ? const Color(0xFF091F38) : Colors.transparent,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: !isMap ? AppTheme.accentCyan : Colors.transparent,
                  width: !isMap ? 1.4 : 0.0,
                ),
                boxShadow: !isMap
                    ? [
                        BoxShadow(
                          color: AppTheme.accentCyan.withValues(alpha: 0.35),
                          blurRadius: 8,
                          spreadRadius: 0.5,
                        ),
                      ]
                    : [],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.format_list_bulleted,
                    size: 16,
                    color: !isMap ? AppTheme.accentCyan : Colors.white70,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'List',
                    style: TextStyle(
                      color: !isMap ? Colors.white : Colors.white70,
                      fontSize: 12.5,
                      fontWeight: !isMap ? FontWeight.w700 : FontWeight.w500,
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

  // Full-page Hotel Cards List View when 'List' mode is toggled
  Widget _buildHotelCardsListView(BuildContext context, HotelProvider hotelProvider) {
    if (hotelProvider.hotels.isEmpty) {
      return const Center(
        child: Text(
          'No hotels found for this destination.',
          style: TextStyle(color: Colors.white70, fontSize: 16),
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = constraints.maxWidth > 1100 ? 3 : (constraints.maxWidth > 700 ? 2 : 1);

        return GridView.builder(
          padding: const EdgeInsets.only(top: 10, bottom: 40),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            childAspectRatio: 1.35,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
          ),
          itemCount: hotelProvider.hotels.length,
          itemBuilder: (context, idx) {
            final hotel = hotelProvider.hotels[idx];
            return InkWell(
              onTap: () => hotelProvider.selectHotel(hotel),
              borderRadius: BorderRadius.circular(14),
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF070E1A).withValues(alpha: 0.92),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFF1E2E4A), width: 1.2),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.6),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 6,
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          ClipRRect(
                            borderRadius: const BorderRadius.vertical(top: Radius.circular(13)),
                            child: Image.network(
                              hotel.exteriorImageUrl ?? '',
                              fit: BoxFit.cover,
                              errorBuilder: (_, _, _) => Container(
                                color: const Color(0xFF0D172E),
                                child: const Icon(Icons.hotel, color: AppTheme.accentCyan, size: 36),
                              ),
                            ),
                          ),
                          Positioned(
                            top: 10,
                            right: 10,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.75),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: AppTheme.accentCyan.withValues(alpha: 0.5)),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.star, color: Color(0xFFFFB800), size: 13),
                                  const SizedBox(width: 4),
                                  Text(
                                    hotel.starRating.toStringAsFixed(1),
                                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      flex: 4,
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              hotel.hotelName.replaceAll(' (Demo)', ''),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  '₹ ${hotel.startingPrice.toStringAsFixed(0)} / night',
                                  style: const TextStyle(
                                    color: AppTheme.accentCyan,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 14,
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                  decoration: BoxDecoration(
                                    color: AppTheme.accentCyan.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(color: AppTheme.accentCyan, width: 1),
                                  ),
                                  child: const Text(
                                    'View Details',
                                    style: TextStyle(
                                      color: AppTheme.accentCyan,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 11,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  // Left Vertical Sidebar matching the exact visual reference
  Widget _buildLeftSidebar(BuildContext context, AuthProvider authProvider, HotelProvider hotelProvider) {
    return Container(
      width: 175,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 18),
      decoration: BoxDecoration(
        color: const Color(0xFF040812).withValues(alpha: 0.94),
        border: Border(
          right: BorderSide(
            color: const Color(0xFF1E2E4A).withValues(alpha: 0.45),
            width: 1.0,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Branding (Clickable: returns to full discovery map view)
          InkWell(
            onTap: () {
              hotelProvider.closeAllTabs();
              setState(() {
                _viewMode = DiscoveryViewMode.map;
              });
            },
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
              child: Row(
                children: [
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF00D2FF), Color(0xFF0072FF)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.accentCyan.withValues(alpha: 0.45),
                          blurRadius: 10,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Transform.rotate(
                      angle: -0.785398, // -45 degrees airplane matching brand
                      child: const Icon(Icons.flight, color: Colors.white, size: 18),
                    ),
                  ),
                  const SizedBox(width: 9),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          'SMART TRAVEL',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                            fontSize: 13.5,
                            letterSpacing: 0.8,
                            height: 1.1,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '3D Luxury Travel Planner',
                          style: TextStyle(
                            color: AppTheme.accentCyan.withValues(alpha: 0.95),
                            fontSize: 9.0,
                            fontWeight: FontWeight.w500,
                            letterSpacing: 0.2,
                            height: 1.15,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          // 0. Explore (Active when on discovery map)
          _SidebarNavButton(
            icon: Icons.location_on_outlined,
            label: 'Explore',
            isActive: !hotelProvider.hasOpenTabs && _viewMode == DiscoveryViewMode.map,
            onTap: () {
              hotelProvider.closeAllTabs();
              setState(() {
                _viewMode = DiscoveryViewMode.map;
              });
            },
          ),

          const SizedBox(height: 10),

          // 1. My Trips
          _SidebarNavButton(
            icon: Icons.map_outlined,
            label: 'My Trips',
            isActive: false,
            onTap: () => context.push('/trips'),
          ),

          const SizedBox(height: 10),

          // 2. Bookings
          _SidebarNavButton(
            icon: Icons.calendar_today_outlined,
            label: 'Bookings',
            isActive: false,
            onTap: () => context.push('/bookings'),
          ),

          const SizedBox(height: 10),

          // 3. Expenses
          _SidebarNavButton(
            icon: Icons.account_balance_wallet_outlined,
            label: 'Expenses',
            isActive: false,
            onTap: () => context.push('/trips'),
          ),

          const SizedBox(height: 10),

          // 4. Logout / Sign In (Label matches reference 'Logout')
          _SidebarNavButton(
            icon: Icons.logout_rounded,
            label: 'Logout',
            isActive: false,
            onTap: () async {
              if (authProvider.isAuthenticated) {
                await authProvider.logout();
              }
              if (context.mounted) {
                context.go('/login');
              }
            },
          ),
        ],
      ),
    );
  }

  // Mobile Top Bar fallback
  Widget _buildMobileTopBar(BuildContext context, HotelProvider hotelProvider) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF091224).withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF1E2E4A).withValues(alpha: 0.7)),
      ),
      child: Row(
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [Color(0xFF00D2FF), Color(0xFF0072FF)]),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Transform.rotate(
              angle: -0.785398,
              child: const Icon(Icons.flight, color: Colors.white, size: 16),
            ),
          ),
          const SizedBox(width: 8),
          const Text(
            'SMART TRAVEL',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
          ),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.map_outlined, color: AppTheme.accentCyan, size: 20),
            onPressed: () => context.push('/trips'),
          ),
          IconButton(
            icon: const Icon(Icons.bookmark_border, color: AppTheme.accentCyan, size: 20),
            onPressed: () => context.push('/bookings'),
          ),
          IconButton(
            icon: const Icon(Icons.logout_rounded, color: AppTheme.accentCyan, size: 20),
            onPressed: () => context.go('/login'),
          ),
        ],
      ),
    );
  }

  // Status indicator pill for hotel count (Globe mode)
  Widget _buildHotelStatusIndicator(BuildContext context, HotelProvider hotelProvider) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
      decoration: BoxDecoration(
        color: const Color(0xFF0F1A32).withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.accentCyan.withValues(alpha: 0.45), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.35),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: const BoxDecoration(
              color: AppTheme.accentCyan,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(color: AppTheme.accentCyan, blurRadius: 6, spreadRadius: 1),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '${hotelProvider.hotels.length} Verified Hotels on Map',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
              fontSize: 12.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _SidebarNavButton extends StatefulWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _SidebarNavButton({
    required this.icon,
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  State<_SidebarNavButton> createState() => _SidebarNavButtonState();
}

class _SidebarNavButtonState extends State<_SidebarNavButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    // Inactive button has dark slate card surface matching reference
    final activeBg = const Color(0xFF05172C).withValues(alpha: 0.95);
    final hoverBg = const Color(0xFF0D1E35).withValues(alpha: 0.85);
    final idleBg = const Color(0xFF070F1C).withValues(alpha: 0.85);

    final activeBorder = const Color(0xFF00D9FF);
    final hoverBorder = const Color(0xFF00D9FF).withValues(alpha: 0.4);
    final idleBorder = const Color(0xFF18283E);

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: SystemMouseCursors.click,
      child: InkWell(
        onTap: widget.onTap,
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10.5),
          decoration: BoxDecoration(
            color: widget.isActive
                ? activeBg
                : (_isHovered ? hoverBg : idleBg),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: widget.isActive
                  ? activeBorder
                  : (_isHovered ? hoverBorder : idleBorder),
              width: widget.isActive ? 1.4 : 1.0,
            ),
            boxShadow: widget.isActive
                ? [
                    BoxShadow(
                      color: const Color(0xFF00D9FF).withValues(alpha: 0.35),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : (_isHovered
                    ? [
                        BoxShadow(
                          color: const Color(0xFF00D9FF).withValues(alpha: 0.12),
                          blurRadius: 8,
                          offset: const Offset(0, 1),
                        ),
                      ]
                    : []),
          ),
          child: Row(
            children: [
              Icon(
                widget.icon,
                color: widget.isActive
                    ? AppTheme.accentCyan
                    : (_isHovered ? AppTheme.accentCyan : Colors.white),
                size: 18,
              ),
              const SizedBox(width: 12),
              Text(
                widget.label,
                style: TextStyle(
                  color: widget.isActive ? AppTheme.accentCyan : Colors.white,
                  fontSize: 13,
                  fontWeight: widget.isActive ? FontWeight.w700 : FontWeight.w500,
                  letterSpacing: 0.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
