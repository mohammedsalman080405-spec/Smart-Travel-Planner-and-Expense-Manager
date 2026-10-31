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
import '../../widgets/interactive_globe.dart';

class GlobeHomeScreen extends StatefulWidget {
  final String? initialSearch;
  final int? initialHotelId;
  const GlobeHomeScreen({super.key, this.initialSearch, this.initialHotelId});

  @override
  State<GlobeHomeScreen> createState() => _GlobeHomeScreenState();
}

class _GlobeHomeScreenState extends State<GlobeHomeScreen> {
  @override
  void initState() {
    super.initState();
    if (widget.initialSearch != null && widget.initialSearch!.trim().isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _runSearch(widget.initialSearch!.trim());
      });
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
    // Responsive vertical positioning:
    // Large desktop (>= 1180): top: 48 (shifted ~48px upward from original 96)
    // Medium / Laptop (780 to 1179): top: 58 (shifted ~38px upward, ensuring zero header overlap)
    // Compact / Mobile (< 780): top: 68 (shifted ~28px upward, clear of mobile app bar)
    final double searchTop;
    if (screenWidth >= 1180) {
      searchTop = 48.0;
    } else if (screenWidth >= 780) {
      searchTop = 58.0;
    } else {
      searchTop = 68.0;
    }

    return Scaffold(
      backgroundColor: AppTheme.darkNavy,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // ==========================================
          // LAYER 1: BASE HOMEPAGE (Globe, Header, Status & Search)
          // ==========================================

          // 1a. Interactive 3D Earth Globe (Always 100% full screen background, never unmounted)
          Positioned.fill(
            child: InteractiveGlobe(
              hotels: hotelProvider.hotels,
              selectedHotel: selectedHotel,
              isBlurred: hotelProvider.hasOpenTabs,
              onHotelSelected: (hotel) {
                hotelProvider.selectHotel(hotel);
              },
            ),
          ),

          // 1b. Top Bar: Brand Logo & Navigation
          Positioned(
            top: 20,
            left: 20,
            right: 20,
            child: PointerInterceptor(
              child: LayoutBuilder(
                builder: (context, topBarConstraints) {
                  final isCompact = topBarConstraints.maxWidth < 780;

                  return Row(
                    children: [
                      // Brand Logo (Clickable: returns to full globe view, closes workspace, preserves destination)
                      InkWell(
                        onTap: () {
                          hotelProvider.closeAllTabs();
                          context.read<GlobeProvider>().resetView();
                        },
                        borderRadius: BorderRadius.circular(14),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [Color(0xFF00D2FF), Color(0xFF3B82F6)],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  borderRadius: BorderRadius.circular(11),
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppTheme.accentCyan.withOpacity(0.4),
                                      blurRadius: 12,
                                      offset: const Offset(0, 2),
                                    )
                                  ],
                                ),
                                child: const Icon(Icons.public, color: Colors.white, size: 24),
                              ),
                              const SizedBox(width: 12),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Text(
                                    'SMART TRAVEL',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w900,
                                      fontSize: 16.5,
                                      letterSpacing: 1.2,
                                      height: 1.1,
                                    ),
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    isCompact ? 'Luxury Travel & 3D Globe' : '3D Luxury Globe & Expense Manager',
                                    style: TextStyle(
                                      color: AppTheme.accentCyan.withOpacity(0.9),
                                      fontSize: 11,
                                      fontWeight: FontWeight.w500,
                                      letterSpacing: 0.5,
                                      height: 1.1,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),

                      const Spacer(),

                      // Navigation Controls
                      if (!isCompact) ...[
                        _NavButton(
                          icon: Icons.map_outlined,
                          label: 'My Trips',
                          onTap: () => context.push('/trips'),
                        ),
                        const SizedBox(width: 8),
                        _NavButton(
                          icon: Icons.bookmark_border,
                          label: 'Bookings',
                          onTap: () => context.push('/bookings'),
                        ),
                        const SizedBox(width: 8),
                        _NavButton(
                          icon: Icons.account_balance_wallet_outlined,
                          label: 'Expenses',
                          onTap: () => context.push('/trips'),
                        ),
                        const SizedBox(width: 12),
                      ] else ...[
                        IconButton(
                          icon: const Icon(Icons.map_outlined, color: AppTheme.accentCyan, size: 20),
                          tooltip: 'My Trips',
                          onPressed: () => context.push('/trips'),
                        ),
                        IconButton(
                          icon: const Icon(Icons.bookmark_border, color: AppTheme.accentCyan, size: 20),
                          tooltip: 'Bookings',
                          onPressed: () => context.push('/bookings'),
                        ),
                      ],

                      // Profile / Login Button
                      if (authProvider.isAuthenticated)
                        InkWell(
                          onTap: () => context.push('/profile'),
                          borderRadius: BorderRadius.circular(24),
                          child: Container(
                            padding: EdgeInsets.symmetric(horizontal: isCompact ? 8 : 14, vertical: 6),
                            decoration: BoxDecoration(
                              color: AppTheme.cardNavy,
                              borderRadius: BorderRadius.circular(24),
                              border: Border.all(color: AppTheme.borderNavy),
                            ),
                            child: Row(
                              children: [
                                CircleAvatar(
                                  radius: 13,
                                  backgroundImage: authProvider.currentUser?.profileImage != null
                                      ? NetworkImage(authProvider.currentUser!.profileImage!)
                                      : null,
                                  child: authProvider.currentUser?.profileImage == null
                                      ? const Icon(Icons.person, size: 14)
                                      : null,
                                ),
                                if (!isCompact) ...[
                                  const SizedBox(width: 8),
                                  Text(
                                    authProvider.currentUser?.fullName.split(' ').first ?? 'Profile',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        )
                      else
                        ElevatedButton.icon(
                          icon: const Icon(Icons.login, size: 16),
                          label: Text(isCompact ? 'Sign In' : 'Sign In'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.accentBlue,
                            padding: EdgeInsets.symmetric(horizontal: isCompact ? 12 : 16, vertical: 10),
                          ),
                          onPressed: () => context.push('/login'),
                        ),
                    ],
                  );
                },
              ),
            ),
          ),

          // 1c. Separate Status Indicator: Hotel count & search radius (No overlap with logo!)
          if (hotelProvider.hotels.isNotEmpty)
            Positioned(
              top: screenWidth >= 1180 ? 76 : (screenWidth >= 780 ? 116 : 126),
              left: 20,
              child: PointerInterceptor(
                child: _buildHotelStatusIndicator(context, hotelProvider),
              ),
            ),

          // 1d. Destination Search Bar (Prominent center-top)
          Positioned(
            top: searchTop,
            left: 0,
            right: 0,
            child: Center(
              child: PointerInterceptor(
                child: DestinationSearchBar(
                  onDestinationSelected: (query, lat, lng) {
                    // Globe updates automatically via Provider
                  },
                ),
              ),
            ),
          ),

          // 1e. Loading indicator overlay during hotel search
          if (hotelProvider.isLoading)
            Positioned(
              bottom: 36,
              right: 36,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                decoration: BoxDecoration(
                  color: AppTheme.cardNavy.withOpacity(0.95),
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(color: AppTheme.accentCyan, width: 1.2),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.4), blurRadius: 16),
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
                      'Discovering verified hotels on globe...',
                      style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ),
            ),

          // ==========================================
          // LAYER 2: BLUR & DARK TRANSLUCENT OVERLAY
          // ==========================================
          // Blurs the entire background homepage (3D Earth globe, stars, header, search bar, markers)
          // Uses BackdropFilter with sigma 10 and a subtle dark transparent overlay.
          // Smooth fade-in animation and allows tapping outside to close the workspace.
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
                            color: Colors.black.withValues(alpha: 0.52 * value),
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
          // Positioned on top of the blur layer!
          // Completely crisp and untouched by the background blur.
          if (hotelProvider.hasOpenTabs)
            Positioned.fill(
              child: PointerInterceptor(
                child: const HotelWorkspaceTab(),
              ),
            ),
        ],
      ),
    );
  }

  // Neatly aligned status indicator for hotel count & search radius (Separated from logo)
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
            '${hotelProvider.hotels.length} Verified Hotels on Globe',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
              fontSize: 12.5,
            ),
          ),
          const SizedBox(width: 10),
          Container(
            height: 14,
            width: 1,
            color: AppTheme.borderNavy,
          ),
          const SizedBox(width: 10),
          DropdownButtonHideUnderline(
            child: DropdownButton<double>(
              value: hotelProvider.searchRadiusKm,
              dropdownColor: const Color(0xFF0D172E),
              isDense: true,
              icon: const Icon(Icons.arrow_drop_down, color: AppTheme.accentCyan, size: 18),
              style: const TextStyle(color: AppTheme.accentCyan, fontWeight: FontWeight.bold, fontSize: 12),
              items: const [
                DropdownMenuItem(value: 5.0, child: Text('5 km radius')),
                DropdownMenuItem(value: 10.0, child: Text('10 km radius')),
                DropdownMenuItem(value: 20.0, child: Text('20 km radius')),
                DropdownMenuItem(value: 30.0, child: Text('30 km radius')),
                DropdownMenuItem(value: 50.0, child: Text('50 km radius')),
              ],
              onChanged: (val) {
                if (val != null) {
                  hotelProvider.setRadius(val);
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _NavButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _NavButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: AppTheme.cardNavy.withOpacity(0.7),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.borderNavy.withOpacity(0.7)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: AppTheme.accentCyan, size: 17),
            const SizedBox(width: 6),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
