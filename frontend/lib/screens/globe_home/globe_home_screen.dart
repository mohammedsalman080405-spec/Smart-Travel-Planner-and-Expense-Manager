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
          // 1. Interactive 3D Earth Globe (Always 100% full screen background, never unmounted)
          Positioned.fill(
            child: InteractiveGlobe(
              hotels: hotelProvider.hotels,
              selectedHotel: selectedHotel,
              onHotelSelected: (hotel) {
                hotelProvider.selectHotel(hotel);
              },
            ),
          ),

          // 2. Top Bar: Brand Logo & Navigation
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
                      // Brand Logo
                      InkWell(
                        onTap: () {
                          hotelProvider.clearSearch();
                          context.read<GlobeProvider>().resetView();
                        },
                        borderRadius: BorderRadius.circular(12),
                        child: Row(
                          children: [
                            Container(
                              width: 38,
                              height: 38,
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [Color(0xFF00D2FF), Color(0xFF3B82F6)],
                                ),
                                borderRadius: BorderRadius.circular(10),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppTheme.accentCyan.withOpacity(0.4),
                                    blurRadius: 12,
                                  )
                                ],
                              ),
                              child: const Icon(Icons.public, color: Colors.white, size: 22),
                            ),
                            const SizedBox(width: 10),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Text(
                                  'SMART TRAVEL',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w900,
                                    fontSize: 16,
                                    letterSpacing: 1.1,
                                  ),
                                ),
                                if (!isCompact)
                                  Text(
                                    '3D Luxury Globe & Expense Manager',
                                    style: TextStyle(
                                      color: AppTheme.accentCyan.withOpacity(0.9),
                                      fontSize: 10.5,
                                      fontWeight: FontWeight.w500,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                              ],
                            ),
                          ],
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

          // 3. Destination Search Bar (Shifted upward, prominent center-top when hotel tab is closed)
          if (!hotelProvider.hasOpenTabs)
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

          // 4. Loading indicator overlay during hotel search
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

          // 5. In-Page Hotel Tab / Floating Workspace (Opens over the existing globe)
          if (hotelProvider.hasOpenTabs)
            const Positioned.fill(
              child: HotelWorkspaceTab(),
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
