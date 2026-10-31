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
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  DiscoveryViewMode _viewMode = DiscoveryViewMode.globe;
  int _searchResetKey = 0;
  bool _searchWasCleared = false;

  @override
  void initState() {
    super.initState();
    final initialSearch = widget.initialSearch?.trim();
    if (initialSearch != null && initialSearch.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => _runSearch(initialSearch),
      );
    }
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
        if (!mounted) return;
        setState(() => _viewMode = DiscoveryViewMode.globe);
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

  void _returnToGlobalGlobe(HotelProvider hotelProvider) {
    hotelProvider.closeAllTabs();
    hotelProvider.clearSearch();
    context.read<GlobeProvider>().resetView();
    setState(() {
      _viewMode = DiscoveryViewMode.globe;
      _searchResetKey++;
      _searchWasCleared = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final hotelProvider = context.watch<HotelProvider>();
    final authProvider = context.watch<AuthProvider>();
    final selectedHotel = hotelProvider.selectedHotel;
    final screenWidth = MediaQuery.sizeOf(context).width;
    final isDesktop = screenWidth >= 780;
    final sidebarWidth = screenWidth >= 1200 ? 320.0 : 252.0;
    final globeProvider = context.watch<GlobeProvider>();
    final Widget discoveryView = switch (_viewMode) {
      DiscoveryViewMode.map => Padding(
        key: const ValueKey('city-map'),
        padding: EdgeInsets.only(left: isDesktop ? sidebarWidth : 0),
        child: HyderabadDiscoveryMap(
          isBlurred: hotelProvider.hasOpenTabs,
          destination: hotelProvider.currentDestination,
          latitude: globeProvider.targetLatitude,
          longitude: globeProvider.targetLongitude,
          hotels: hotelProvider.hotels,
          onHotelSelected: hotelProvider.selectHotel,
          onReturnToGlobe: _returnToCityGlobe,
        ),
      ),
      DiscoveryViewMode.globe => InteractiveGlobe(
        key: const ValueKey('city-globe'),
        hotels: hotelProvider.hotels,
        selectedHotel: selectedHotel,
        isBlurred: hotelProvider.hasOpenTabs,
        onHotelSelected: hotelProvider.selectHotel,
        onOpenCityMap: _openCityMap,
        onReturnToGlobal: () => _returnToGlobalGlobe(hotelProvider),
      ),
      DiscoveryViewMode.list => Padding(
        key: const ValueKey('hotel-list'),
        padding: EdgeInsets.only(
          top: 80,
          bottom: 0,
          left: isDesktop ? 195 : 16,
          right: 16,
        ),
        child: _buildHotelCardsListView(context, hotelProvider),
      ),
    };

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: Colors.black, // Pure Black Background
      drawer: !isDesktop
          ? Drawer(
              width: (screenWidth * 0.84).clamp(280.0, 340.0),
              backgroundColor: const Color(0xFF050912),
              child: SafeArea(
                child: _buildLeftSidebar(
                  context,
                  authProvider,
                  hotelProvider,
                  (screenWidth * 0.84).clamp(280.0, 340.0),
                ),
              ),
            )
          : null,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // ==========================================
          // LAYER 1: BASE HOMEPAGE (Interactive Satellite Map / Globe, Sidebar & Controls)
          // ==========================================

          // Cross-fade the Earth and city map to avoid a blank or flashing frame.
          Positioned.fill(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 850),
              switchInCurve: Curves.easeOutCubic,
              switchOutCurve: Curves.easeInCubic,
              layoutBuilder: (currentChild, previousChildren) => Stack(
                fit: StackFit.expand,
                children: [...previousChildren, ?currentChild],
              ),
              transitionBuilder: (child, animation) =>
                  FadeTransition(opacity: animation, child: child),
              child: discoveryView,
            ),
          ),

          // 1b. Left Vertical Sidebar (Desktop / Tablet)
          if (isDesktop)
            Positioned(
              top: 0,
              bottom: 0,
              left: 0,
              width: sidebarWidth,
              child: PointerInterceptor(
                child: _buildLeftSidebar(context, authProvider, hotelProvider, sidebarWidth),
              ),
            ),

          // 1c. Mobile Top Bar (Compact screens only)
          if (!isDesktop)
            Positioned(
              top: 16,
              left: 16,
              right: 16,
              child: PointerInterceptor(
                child: _buildMobileTopBar(context),
              ),
            ),

          // 1d. Destination Search Bar (Centered at top between sidebar and toggle)
          Positioned(
            top: isDesktop ? 16 : 76,
            left: isDesktop ? sidebarWidth : 0,
            right: isDesktop ? 175 : 0,
            child: Center(
              child: PointerInterceptor(
                child: DestinationSearchBar(
                  key: ValueKey(_searchResetKey),
                  initialValue: _searchWasCleared ? null : widget.initialSearch,
                  onDestinationSelected: _showCityOnGlobe,
                  onCleared: () => _returnToGlobalGlobe(hotelProvider),
                ),
              ),
            ),
          ),

          // 1e. Top-Right Map / List Toggle
          if (isDesktop && _viewMode != DiscoveryViewMode.globe)
            Positioned(
              top: 16,
              right: 20,
              child: PointerInterceptor(child: _buildTopRightToggle()),
            ),

          // 1f. Hotel Status Indicator Pill (Shown in globe mode)
          if (_viewMode == DiscoveryViewMode.globe &&
              hotelProvider.hotels.isNotEmpty)
            Positioned(
              top: isDesktop ? 112 : 160,
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
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF091224).withValues(alpha: 0.95),
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(color: AppTheme.accentCyan, width: 1.2),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.5),
                      blurRadius: 16,
                    ),
                  ],
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.2,
                        color: AppTheme.accentCyan,
                      ),
                    ),
                    SizedBox(width: 12),
                    Text(
                      'Discovering verified hotels...',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
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
                          filter: ImageFilter.blur(
                            sigmaX: 10.0 * value,
                            sigmaY: 10.0 * value,
                          ),
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
              left: isDesktop ? sidebarWidth : 0,
              right: 0,
              child: PointerInterceptor(child: const HotelWorkspaceTab()),
            ),
        ],
      ),
    );
  }

  void _openCityMap() {
    if (!mounted || context.read<HotelProvider>().currentDestination.isEmpty) {
      return;
    }
    setState(() => _viewMode = DiscoveryViewMode.map);
  }

  void _showCityOnGlobe(String query, double latitude, double longitude) {
    if (!mounted) return;
    debugPrint(
      '[Explore] Showing $query on the 3D globe at $latitude, $longitude',
    );
    setState(() => _viewMode = DiscoveryViewMode.globe);
  }

  void _returnToCityGlobe(double latitude, double longitude) {
    if (!mounted) return;
    context.read<GlobeProvider>().setCoordinates(
      latitude,
      longitude,
      animate: false,
      cameraDistance: 17.0,
    );
    setState(() => _viewMode = DiscoveryViewMode.globe);
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
  Widget _buildHotelCardsListView(
    BuildContext context,
    HotelProvider hotelProvider,
  ) {
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
        final crossAxisCount = constraints.maxWidth > 1100
            ? 3
            : (constraints.maxWidth > 700 ? 2 : 1);

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
                  border: Border.all(
                    color: const Color(0xFF1E2E4A),
                    width: 1.2,
                  ),
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
                            borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(13),
                            ),
                            child: Image.network(
                              hotel.exteriorImageUrl ?? '',
                              fit: BoxFit.cover,
                              errorBuilder: (_, _, _) => Container(
                                color: const Color(0xFF0D172E),
                                child: const Icon(
                                  Icons.hotel,
                                  color: AppTheme.accentCyan,
                                  size: 36,
                                ),
                              ),
                            ),
                          ),
                          Positioned(
                            top: 10,
                            right: 10,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.75),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: AppTheme.accentCyan.withValues(
                                    alpha: 0.5,
                                  ),
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: hotel.starRating > 0
                                    ? [
                                        const Icon(
                                          Icons.star,
                                          color: Color(0xFFFFB800),
                                          size: 13,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          hotel.starRating.toStringAsFixed(1),
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 11,
                                          ),
                                        ),
                                      ]
                                    : [
                                        const Text(
                                          'Rating unavailable',
                                          style: TextStyle(
                                            color: Colors.white70,
                                            fontSize: 10,
                                          ),
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
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 5,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppTheme.accentCyan.withValues(
                                      alpha: 0.15,
                                    ),
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(
                                      color: AppTheme.accentCyan,
                                      width: 1,
                                    ),
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
  Widget _buildLeftSidebar(
    BuildContext context,
    AuthProvider authProvider,
    HotelProvider hotelProvider,
    double sidebarWidth,
  ) {
    final currentPath = GoRouterState.of(context).uri.path;
    final activeIndex = currentPath == '/trips'
        ? 1
        : currentPath == '/bookings'
        ? 2
        : currentPath.startsWith('/budget') || currentPath == '/expenses'
        ? 3
        : hotelProvider.hasOpenTabs
        ? -1
        : 0;
    return Container(
      width: sidebarWidth,
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 28),
      decoration: BoxDecoration(
        color: const Color(0xFF050912),
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
            onTap: () => _returnToGlobalGlobe(hotelProvider),
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
              child: Row(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF00D2FF), Color(0xFF0072FF)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(17),
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
                      child: const Icon(
                        Icons.flight,
                        color: Colors.white,
                        size: 30,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
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
                            fontSize: 20,
                            letterSpacing: 0.8,
                            height: 1.1,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '3D Luxury Travel Planner',
                          style: TextStyle(
                            color: AppTheme.accentCyan.withValues(alpha: 0.95),
                          fontSize: 13,
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

          const SizedBox(height: 38),

          // 0. Explore (Active when on discovery map)
          _SidebarNavButton(
            icon: Icons.location_on_outlined,
            label: 'Explore',
            isActive: activeIndex == 0,
            onTap: () => _returnToGlobalGlobe(hotelProvider),
          ),

          const SizedBox(height: 13),

          // 1. My Trips
          _SidebarNavButton(
            icon: Icons.map_outlined,
            label: 'My Trips',
            isActive: activeIndex == 1,
            onTap: () => context.push('/trips'),
          ),

          const SizedBox(height: 13),

          // 2. Bookings
          _SidebarNavButton(
            icon: Icons.calendar_today_outlined,
            label: 'Bookings',
            isActive: activeIndex == 2,
            onTap: () => context.push('/bookings'),
          ),

          const SizedBox(height: 13),

          // 3. Expenses
          _SidebarNavButton(
            icon: Icons.account_balance_wallet_outlined,
            label: 'Expenses',
            isActive: activeIndex == 3,
            onTap: () => context.push('/trips'),
          ),

          const SizedBox(height: 13),

          // 4. Logout / Sign In (Label matches reference 'Logout')
          _SidebarNavButton(
            icon: Icons.logout_rounded,
            label: 'Logout',
            isActive: activeIndex == 4,
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
  Widget _buildMobileTopBar(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF091224).withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF1E2E4A).withValues(alpha: 0.7),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF00D2FF), Color(0xFF0072FF)],
              ),
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
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
          ),
          const Spacer(),
          IconButton(
            tooltip: 'Open navigation menu',
            icon: const Icon(Icons.menu_rounded, color: AppTheme.accentCyan, size: 25),
            onPressed: () => _scaffoldKey.currentState?.openDrawer(),
          ),
        ],
      ),
    );
  }

  // Status indicator pill for hotel count (Globe mode)
  Widget _buildHotelStatusIndicator(
    BuildContext context,
    HotelProvider hotelProvider,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
      decoration: BoxDecoration(
        color: const Color(0xFF0F1A32).withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppTheme.accentCyan.withValues(alpha: 0.45),
          width: 1.2,
        ),
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
                BoxShadow(
                  color: AppTheme.accentCyan,
                  blurRadius: 6,
                  spreadRadius: 1,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '${hotelProvider.hotels.length} hotels · Zoom closer for satellite map',
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
    final hoverBg = const Color(0xFF0B1C2D);
    final idleBg = const Color(0xFF080F1D);

    final activeBorder = const Color(0xFF00D9FF);
    final hoverBorder = const Color(0xFF00D9FF).withValues(alpha: 0.4);
    final idleBorder = const Color(0xFF192A40);

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: SystemMouseCursors.click,
      child: InkWell(
        onTap: widget.onTap,
        borderRadius: BorderRadius.circular(20),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          width: double.infinity,
          height: 74,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: widget.isActive ? activeBg : (_isHovered ? hoverBg : idleBg),
            borderRadius: BorderRadius.circular(20),
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
                            color: const Color(0xFF00D9FF)
                                .withValues(alpha: 0.12),
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
                size: 25,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  widget.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: widget.isActive ? AppTheme.accentCyan : Colors.white,
                    fontSize: 20,
                    fontWeight: widget.isActive
                        ? FontWeight.w700
                        : FontWeight.w600,
                    letterSpacing: 0.2,
                  ),
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: widget.isActive || _isHovered
                    ? AppTheme.accentCyan
                    : Colors.white,
                size: 25,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
