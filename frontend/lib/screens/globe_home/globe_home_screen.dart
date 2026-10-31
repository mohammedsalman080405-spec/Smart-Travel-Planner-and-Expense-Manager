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
    final isDesktop = screenWidth >= 780;

    return Scaffold(
      backgroundColor: Colors.black, // Pure Black Background
      body: Stack(
        fit: StackFit.expand,
        children: [
          // ==========================================
          // LAYER 1: BASE HOMEPAGE (Globe, Sidebar, Status & Search)
          // ==========================================

          // 1a. Interactive 3D Earth Globe (Always 100% full screen background, shifted right & down)
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

          // 1b. Left Vertical Sidebar (Desktop / Tablet)
          if (isDesktop)
            Positioned(
              top: 0,
              bottom: 0,
              left: 0,
              width: 240,
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

          // 1d. Destination Search Bar (Centered at top of main area)
          Positioned(
            top: isDesktop ? 24 : 76,
            left: isDesktop ? 240 : 0,
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

          // 1e. Hotel Status Indicator Pill (Positioned cleanly below search bar)
          if (hotelProvider.hotels.isNotEmpty)
            Positioned(
              top: isDesktop ? 88 : 140,
              left: isDesktop ? 264 : 20,
              child: PointerInterceptor(
                child: _buildHotelStatusIndicator(context, hotelProvider),
              ),
            ),

          // 1f. Loading indicator overlay during hotel search
          if (hotelProvider.isLoading)
            Positioned(
              bottom: 36,
              right: 36,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFF091224).withOpacity(0.95),
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(color: AppTheme.accentCyan, width: 1.2),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.5), blurRadius: 16),
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
                            color: Colors.black.withOpacity(0.55 * value),
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
              left: isDesktop ? 240 : 0,
              right: 0,
              child: PointerInterceptor(
                child: const HotelWorkspaceTab(),
              ),
            ),
        ],
      ),
    );
  }

  // Left Vertical Sidebar matching the exact visual reference
  Widget _buildLeftSidebar(BuildContext context, AuthProvider authProvider, HotelProvider hotelProvider) {
    return Container(
      width: 240,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      decoration: BoxDecoration(
        color: const Color(0xFF060B17).withOpacity(0.88),
        border: Border(
          right: BorderSide(
            color: const Color(0xFF1E2E4A).withOpacity(0.45),
            width: 1.0,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Branding (Clickable: returns to full globe view, closes workspace)
          InkWell(
            onTap: () {
              hotelProvider.closeAllTabs();
              context.read<GlobeProvider>().resetView();
            },
            borderRadius: BorderRadius.circular(14),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
              child: Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF00D2FF), Color(0xFF0072FF)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.accentCyan.withOpacity(0.45),
                          blurRadius: 12,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Icon(Icons.public, color: Colors.white, size: 26),
                  ),
                  const SizedBox(width: 12),
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
                            fontSize: 16,
                            letterSpacing: 1.0,
                            height: 1.1,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          '3D Luxury Globe &\nExpense Manager',
                          style: TextStyle(
                            color: AppTheme.accentCyan.withOpacity(0.95),
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            letterSpacing: 0.3,
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

          const SizedBox(height: 32),

          // 1. My Trips (active item in reference image)
          _SidebarNavButton(
            icon: Icons.map_outlined,
            label: 'My Trips',
            isActive: true,
            onTap: () => context.push('/trips'),
          ),

          const SizedBox(height: 12),

          // 2. Bookings
          _SidebarNavButton(
            icon: Icons.bookmark_border,
            label: 'Bookings',
            isActive: false,
            onTap: () => context.push('/bookings'),
          ),

          const SizedBox(height: 12),

          // 3. Expenses
          _SidebarNavButton(
            icon: Icons.account_balance_wallet_outlined,
            label: 'Expenses',
            isActive: false,
            onTap: () => context.push('/trips'),
          ),

          const SizedBox(height: 12),

          // 4. Logout / Sign In
          _SidebarNavButton(
            icon: authProvider.isAuthenticated ? Icons.logout_rounded : Icons.login_rounded,
            label: authProvider.isAuthenticated ? 'Logout' : 'Sign In',
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
        color: const Color(0xFF091224).withOpacity(0.85),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF1E2E4A).withOpacity(0.7)),
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [Color(0xFF00D2FF), Color(0xFF0072FF)]),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.public, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 10),
          const Text(
            'SMART TRAVEL',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
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
    final activeBg = const Color(0xFF0D2444).withValues(alpha: 0.95);
    final hoverBg = const Color(0xFF0B1930).withValues(alpha: 0.85);
    final idleBg = const Color(0xFF070E1E).withValues(alpha: 0.65);

    final activeBorder = const Color(0xFF00D2FF).withValues(alpha: 0.7);
    final hoverBorder = const Color(0xFF00D2FF).withValues(alpha: 0.4);
    final idleBorder = const Color(0xFF1E2E4A).withValues(alpha: 0.55);

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: SystemMouseCursors.click,
      child: InkWell(
        onTap: widget.onTap,
        borderRadius: BorderRadius.circular(14),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
          decoration: BoxDecoration(
            color: widget.isActive
                ? activeBg
                : (_isHovered ? hoverBg : idleBg),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: widget.isActive
                  ? activeBorder
                  : (_isHovered ? hoverBorder : idleBorder),
              width: widget.isActive ? 1.4 : 1.0,
            ),
            boxShadow: widget.isActive
                ? [
                    BoxShadow(
                      color: const Color(0xFF00D2FF).withValues(alpha: 0.22),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : (_isHovered
                    ? [
                        BoxShadow(
                          color: const Color(0xFF00D2FF).withValues(alpha: 0.12),
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
                    : (_isHovered ? AppTheme.accentCyan : Colors.white70),
                size: 20,
              ),
              const SizedBox(width: 14),
              Text(
                widget.label,
                style: TextStyle(
                  color: widget.isActive ? Colors.white : Colors.white.withValues(alpha: 0.9),
                  fontSize: 14,
                  fontWeight: widget.isActive ? FontWeight.w700 : FontWeight.w500,
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
