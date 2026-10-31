import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:pointer_interceptor/pointer_interceptor.dart';
import 'package:provider/provider.dart';
import '../config/theme.dart';
import '../models/hotel.dart';
import '../models/hotel_space.dart';
import '../models/room.dart';
import '../providers/hotel_provider.dart';
import '../services/hotel_service.dart';
import 'model_viewer_widget.dart';

enum HotelTabStep {
  exterior,
  interior,
  spaceDetail,
  viewer3d,
}

class HotelTabState {
  HotelTabStep step = HotelTabStep.exterior;
  List<Room> rooms = [];
  List<HotelSpace> spaces = [];
  bool isLoadingInterior = false;
  String selectedCategory = 'All';
  Room? selectedRoom;
  HotelSpace? selectedSpace;

  HotelTabState();
}

class HotelWorkspaceTab extends StatefulWidget {
  const HotelWorkspaceTab({super.key});

  @override
  State<HotelWorkspaceTab> createState() => _HotelWorkspaceTabState();
}

class _HotelWorkspaceTabState extends State<HotelWorkspaceTab> {
  final Map<int, HotelTabState> _tabStates = {};

  HotelTabState _getState(int hotelId) {
    return _tabStates.putIfAbsent(hotelId, () => HotelTabState());
  }

  Future<void> _loadInteriorData(Hotel hotel) async {
    final state = _getState(hotel.hotelId);
    if (state.rooms.isNotEmpty || state.spaces.isNotEmpty || state.isLoadingInterior) {
      return;
    }

    setState(() {
      state.isLoadingInterior = true;
    });

    try {
      final roomsFuture = HotelService.getHotelRooms(hotel.hotelId);
      final spacesFuture = HotelService.getHotelSpaces(hotel.hotelId);

      final results = await Future.wait([roomsFuture, spacesFuture]);
      if (mounted) {
        setState(() {
          state.rooms = results[0] as List<Room>;
          state.spaces = results[1] as List<HotelSpace>;
          state.isLoadingInterior = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          state.isLoadingInterior = false;
        });
      }
    }
  }

  void _navigateToStep(Hotel hotel, HotelTabStep newStep) {
    final state = _getState(hotel.hotelId);
    setState(() {
      state.step = newStep;
    });
    if (newStep == HotelTabStep.interior && state.rooms.isEmpty) {
      _loadInteriorData(hotel);
    }
  }

  void _navigateBack(Hotel hotel) {
    final state = _getState(hotel.hotelId);
    setState(() {
      if (state.step == HotelTabStep.viewer3d) {
        state.step = HotelTabStep.spaceDetail;
      } else if (state.step == HotelTabStep.spaceDetail) {
        state.step = HotelTabStep.interior;
      } else if (state.step == HotelTabStep.interior) {
        state.step = HotelTabStep.exterior;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final hotelProvider = context.watch<HotelProvider>();
    final openTabs = hotelProvider.openTabs;
    final activeIndex = hotelProvider.activeTabIndex;

    if (openTabs.isEmpty || activeIndex < 0 || activeIndex >= openTabs.length) {
      return const SizedBox.shrink();
    }

    final currentHotel = openTabs[activeIndex];
    final state = _getState(currentHotel.hotelId);

    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 800;
        final tabWidth = isMobile ? constraints.maxWidth * 0.95 : (constraints.maxWidth * 0.75).clamp(860.0, 1160.0);
        final tabHeight = isMobile ? constraints.maxHeight * 0.94 : (constraints.maxHeight * 0.85).clamp(620.0, 880.0);

        return Center(
          child: PointerInterceptor(
            child: Container(
              width: tabWidth,
              height: tabHeight,
              decoration: BoxDecoration(
                color: const Color(0xFF0D172E),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: AppTheme.accentCyan.withValues(alpha: 0.4), width: 1.5),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.65),
                    blurRadius: 36,
                    offset: const Offset(0, 16),
                  ),
                  BoxShadow(
                    color: AppTheme.accentCyan.withValues(alpha: 0.12),
                    blurRadius: 28,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: Column(
                  children: [
                    // 1. Horizontal Browser-style Tab Strip
                    _buildTabStrip(hotelProvider, openTabs, activeIndex),

                    // 2. Navigation Header Bar & Breadcrumbs
                    _buildWorkspaceHeader(currentHotel, state),

                    // 3. Tab Workspace Content (Replaced inside the existing tab)
                    Expanded(
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 250),
                        child: _buildCurrentStepContent(context, hotelProvider, currentHotel, state),
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

  // 1. Browser-style Tab Strip
  Widget _buildTabStrip(HotelProvider hotelProvider, List<Hotel> openTabs, int activeIndex) {
    return Container(
      height: 44,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: const BoxDecoration(
        color: Color(0xFF091122),
        border: Border(bottom: BorderSide(color: Color(0xFF1E2D4A))),
      ),
      child: Row(
        children: [
          Expanded(
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: openTabs.length,
              separatorBuilder: (_, __) => const SizedBox(width: 6),
              itemBuilder: (context, idx) {
                final hotel = openTabs[idx];
                final isActive = idx == activeIndex;

                return InkWell(
                  onTap: () {
                    hotelProvider.switchToTab(idx);
                  },
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: isActive ? const Color(0xFF162544) : Colors.transparent,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isActive ? AppTheme.accentCyan.withValues(alpha: 0.6) : Colors.transparent,
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.hotel,
                          size: 15,
                          color: isActive ? AppTheme.accentCyan : AppTheme.textMuted,
                        ),
                        const SizedBox(width: 8),
                        ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 180),
                          child: Text(
                            hotel.hotelName.replaceAll(' (Demo)', ''),
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: isActive ? Colors.white : AppTheme.textMuted,
                              fontSize: 12,
                              fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
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
                              color: isActive ? Colors.white70 : AppTheme.textMuted,
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
          IconButton(
            icon: const Icon(Icons.close, color: Colors.white70, size: 20),
            tooltip: 'Close Workspace',
            onPressed: () {
              hotelProvider.closeAllTabs();
            },
          ),
        ],
      ),
    );
  }

  // 2. Navigation Header Bar & Breadcrumbs
  Widget _buildWorkspaceHeader(Hotel hotel, HotelTabState state) {
    String stepTitle = 'Hotel Exterior';
    if (state.step == HotelTabStep.interior) {
      stepTitle = 'Interior & Spaces';
    } else if (state.step == HotelTabStep.spaceDetail) {
      stepTitle = state.selectedRoom?.roomName ?? state.selectedSpace?.spaceName ?? 'Space Details';
    } else if (state.step == HotelTabStep.viewer3d) {
      stepTitle = 'Interactive 3D Viewer';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: const BoxDecoration(
        color: Color(0xFF0F1A30),
        border: Border(bottom: BorderSide(color: Color(0xFF1E2D4A))),
      ),
      child: Row(
        children: [
          // Back Button (active when inside interior, details, or 3D)
          if (state.step != HotelTabStep.exterior) ...[
            InkWell(
              onTap: () => _navigateBack(hotel),
              borderRadius: BorderRadius.circular(10),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFF192A4C),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppTheme.accentCyan.withValues(alpha: 0.3)),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.arrow_back, color: AppTheme.accentCyan, size: 16),
                    SizedBox(width: 6),
                    Text(
                      'Back',
                      style: TextStyle(color: AppTheme.accentCyan, fontSize: 13, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 14),
          ],

          // Breadcrumbs trail
          Expanded(
            child: Row(
              children: [
                InkWell(
                  onTap: () => _navigateToStep(hotel, HotelTabStep.exterior),
                  child: Text(
                    hotel.hotelName.replaceAll(' (Demo)', ''),
                    style: TextStyle(
                      color: state.step == HotelTabStep.exterior ? Colors.white : AppTheme.textMuted,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
                if (state.step != HotelTabStep.exterior) ...[
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 6),
                    child: Icon(Icons.chevron_right, size: 16, color: AppTheme.textMuted),
                  ),
                  InkWell(
                    onTap: () => _navigateToStep(hotel, HotelTabStep.interior),
                    child: Text(
                      'Interior & Spaces',
                      style: TextStyle(
                        color: state.step == HotelTabStep.interior ? Colors.white : AppTheme.textMuted,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
                if (state.step == HotelTabStep.spaceDetail || state.step == HotelTabStep.viewer3d) ...[
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 6),
                    child: Icon(Icons.chevron_right, size: 16, color: AppTheme.textMuted),
                  ),
                  Text(
                    stepTitle,
                    style: const TextStyle(
                      color: AppTheme.accentCyan,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ],
              ],
            ),
          ),

          // Price Tag Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
            decoration: BoxDecoration(
              color: AppTheme.accentCyan.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.accentCyan.withValues(alpha: 0.4)),
            ),
            child: Text(
              '\$${hotel.startingPrice.toStringAsFixed(0)} / night',
              style: const TextStyle(color: AppTheme.accentCyan, fontWeight: FontWeight.bold, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  // 3. Main Content Router based on current step
  Widget _buildCurrentStepContent(BuildContext context, HotelProvider provider, Hotel hotel, HotelTabState state) {
    switch (state.step) {
      case HotelTabStep.exterior:
        return _buildExteriorView(context, provider, hotel, state);
      case HotelTabStep.interior:
        return _buildInteriorView(context, hotel, state);
      case HotelTabStep.spaceDetail:
        return _buildSpaceDetailView(context, hotel, state);
      case HotelTabStep.viewer3d:
        return _build3dViewerView(context, hotel, state);
    }
  }

  // STEP 1: Hotel Exterior View
  Widget _buildExteriorView(BuildContext context, HotelProvider provider, Hotel hotel, HotelTabState state) {
    return SingleChildScrollView(
      key: const ValueKey('step_exterior'),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Large Clickable Exterior Photo Banner
          InkWell(
            onTap: () {
              _navigateToStep(hotel, HotelTabStep.interior);
            },
            borderRadius: BorderRadius.circular(18),
            child: Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(18),
                  child: SizedBox(
                    height: 230,
                    width: double.infinity,
                    child: Image.network(
                      hotel.exteriorImageUrl ?? 'https://images.unsplash.com/photo-1566073771259-6a8506099945?auto=format&fit=crop&w=1200&q=80',
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        color: const Color(0xFF1E2D4A),
                        child: const Icon(Icons.hotel, size: 64, color: AppTheme.textMuted),
                      ),
                    ),
                  ),
                ),
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(18),
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withValues(alpha: 0.75),
                        ],
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: 16,
                  left: 16,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppTheme.accentGold,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      'VERIFIED LUXURY PROPERTY',
                      style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 11),
                    ),
                  ),
                ),
                Positioned(
                  bottom: 16,
                  right: 16,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: AppTheme.accentCyan,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.accentCyan.withValues(alpha: 0.4),
                          blurRadius: 16,
                        ),
                      ],
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.touch_app, color: Colors.black87, size: 18),
                        SizedBox(width: 8),
                        Text(
                          'Click to Explore Interior & 3D Spaces',
                          style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Hotel Title & Rating Row
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      hotel.hotelName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppTheme.accentGold.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: AppTheme.accentGold),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.star, color: AppTheme.accentGold, size: 14),
                              const SizedBox(width: 4),
                              Text(
                                '${hotel.starRating.toStringAsFixed(1)} Star',
                                style: const TextStyle(color: AppTheme.accentGold, fontSize: 12, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          '★ ${hotel.reviewRating.toStringAsFixed(1)} (${hotel.reviewCount} reviews)',
                          style: const TextStyle(color: AppTheme.textMuted, fontSize: 13),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.location_on, color: AppTheme.accentCyan, size: 16),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            hotel.address,
                            style: const TextStyle(color: AppTheme.textLight, fontSize: 13),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Action Buttons
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  ElevatedButton.icon(
                    icon: const Icon(Icons.meeting_room, color: Colors.black87, size: 18),
                    label: const Text('EXPLORE HOTEL INTERIOR'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.accentCyan,
                      foregroundColor: Colors.black87,
                      textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      elevation: 4,
                    ),
                    onPressed: () {
                      _navigateToStep(hotel, HotelTabStep.interior);
                    },
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Estimated Trip Accommodation Expense Calculator
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: const Color(0xFF13203C),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFF223558)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.calculate, color: AppTheme.accentCyan, size: 18),
                    SizedBox(width: 8),
                    Text(
                      'ESTIMATED TRIP ACCOMMODATION EXPENSE',
                      style: TextStyle(color: AppTheme.accentCyan, fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Check-In: ${DateFormat('MMM dd, yyyy').format(provider.checkInDate)}  →  Check-Out: ${DateFormat('MMM dd, yyyy').format(provider.checkOutDate)}',
                        style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500),
                      ),
                    ),
                    Text(
                      '\$${hotel.startingPrice.toStringAsFixed(0)} × ${provider.estimatedNights} nights  =  \$${(hotel.startingPrice * provider.estimatedNights).toStringAsFixed(2)}',
                      style: const TextStyle(color: AppTheme.accentCyan, fontSize: 15, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Hotel Description
          const Text(
            'About this Property',
            style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            hotel.description,
            style: const TextStyle(color: AppTheme.textMuted, fontSize: 14, height: 1.5),
          ),
          const SizedBox(height: 20),

          // Verified Facilities & Amenities Pills
          const Text(
            'Hotel Amenities & Facilities',
            style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: (hotel.facilitiesList.isNotEmpty
                    ? hotel.facilitiesList
                    : hotel.facilities.map((f) => f.facilityName).toList())
                .map((f) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFF162544),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFF223558)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.check_circle_outline, color: AppTheme.accentCyan, size: 16),
                    const SizedBox(width: 6),
                    Text(f, style: const TextStyle(color: Colors.white, fontSize: 13)),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  // STEP 2: Hotel Interior View
  Widget _buildInteriorView(BuildContext context, Hotel hotel, HotelTabState state) {
    if (state.isLoadingInterior) {
      return const Center(
        key: ValueKey('interior_loading'),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: AppTheme.accentCyan),
            SizedBox(height: 16),
            Text(
              'Loading hotel interior spaces and 3D models...',
              style: TextStyle(color: AppTheme.textMuted, fontSize: 14),
            ),
          ],
        ),
      );
    }

    final categories = ['All', 'Rooms & Suites', 'Banquet & Halls', 'Dining & Lounges', 'Wellness & Spa'];

    List<dynamic> filteredItems = [];
    if (state.selectedCategory == 'All') {
      filteredItems = [...state.rooms, ...state.spaces];
    } else if (state.selectedCategory == 'Rooms & Suites') {
      filteredItems = state.rooms;
    } else if (state.selectedCategory == 'Banquet & Halls') {
      filteredItems = state.spaces.where((s) => s.category.toLowerCase().contains('banquet') || s.category.toLowerCase().contains('conference')).toList();
    } else if (state.selectedCategory == 'Dining & Lounges') {
      filteredItems = state.spaces.where((s) => s.category.toLowerCase().contains('restaurant') || s.category.toLowerCase().contains('lounge')).toList();
    } else if (state.selectedCategory == 'Wellness & Spa') {
      filteredItems = state.spaces.where((s) => s.category.toLowerCase().contains('pool') || s.category.toLowerCase().contains('spa')).toList();
    }

    return Column(
      key: const ValueKey('step_interior'),
      children: [
        // Category Selector Bar
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          decoration: const BoxDecoration(
            color: Color(0xFF0F1A30),
            border: Border(bottom: BorderSide(color: Color(0xFF1E2D4A))),
          ),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: categories.map((cat) {
                final isSelected = state.selectedCategory == cat;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(cat),
                    selected: isSelected,
                    selectedColor: AppTheme.accentCyan,
                    backgroundColor: const Color(0xFF162544),
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.black87 : Colors.white70,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                    onSelected: (val) {
                      setState(() {
                        state.selectedCategory = cat;
                      });
                    },
                  ),
                );
              }).toList(),
            ),
          ),
        ),

        // Grid of Spaces and Rooms
        Expanded(
          child: filteredItems.isEmpty
              ? const Center(
                  child: Text('No spaces found in this category.', style: TextStyle(color: AppTheme.textMuted)),
                )
              : GridView.builder(
                  padding: const EdgeInsets.all(20),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 1.45,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                  ),
                  itemCount: filteredItems.length,
                  itemBuilder: (context, idx) {
                    final item = filteredItems[idx];
                    final isRoom = item is Room;

                    final String name = isRoom ? item.roomName : (item as HotelSpace).spaceName;
                    final String type = isRoom ? item.roomType : (item as HotelSpace).category;
                    final String image = isRoom ? (item.imageUrl ?? '') : ((item as HotelSpace).imageUrl ?? '');
                    final double price = isRoom ? item.pricePerNight : (item as HotelSpace).price;
                    final String priceLabel = isRoom ? '\$${price.toStringAsFixed(0)} / night' : '\$${price.toStringAsFixed(0)} / hr';

                    return InkWell(
                      onTap: () {
                        setState(() {
                          if (isRoom) {
                            state.selectedRoom = item;
                            state.selectedSpace = null;
                          } else {
                            state.selectedSpace = item as HotelSpace;
                            state.selectedRoom = null;
                          }
                          state.step = HotelTabStep.spaceDetail;
                        });
                      },
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFF13203C),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFF223558)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              flex: 6,
                              child: ClipRRect(
                                borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
                                child: Stack(
                                  children: [
                                    Positioned.fill(
                                      child: Image.network(
                                        image,
                                        fit: BoxFit.cover,
                                        errorBuilder: (_, __, ___) => Container(
                                          color: const Color(0xFF1E2D4A),
                                          child: const Icon(Icons.bed, color: AppTheme.textMuted),
                                        ),
                                      ),
                                    ),
                                    Positioned(
                                      top: 10,
                                      left: 10,
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: Colors.black.withValues(alpha: 0.7),
                                          borderRadius: BorderRadius.circular(12),
                                          border: Border.all(color: AppTheme.accentCyan.withValues(alpha: 0.5)),
                                        ),
                                        child: Text(
                                          type,
                                          style: const TextStyle(color: AppTheme.accentCyan, fontSize: 11, fontWeight: FontWeight.bold),
                                        ),
                                      ),
                                    ),
                                    const Positioned(
                                      bottom: 10,
                                      right: 10,
                                      child: CircleAvatar(
                                        radius: 14,
                                        backgroundColor: AppTheme.accentCyan,
                                        child: Icon(Icons.view_in_ar, size: 16, color: Colors.black87),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            Expanded(
                              flex: 4,
                              child: Padding(
                                padding: const EdgeInsets.all(12),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Text(
                                            name,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            priceLabel,
                                            style: const TextStyle(color: AppTheme.accentCyan, fontSize: 12, fontWeight: FontWeight.w600),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const Icon(Icons.chevron_right, color: AppTheme.accentCyan, size: 20),
                                  ],
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
      ],
    );
  }

  // STEP 3: Individual Space Detail View
  Widget _buildSpaceDetailView(BuildContext context, Hotel hotel, HotelTabState state) {
    final isRoom = state.selectedRoom != null;
    final String title = isRoom ? state.selectedRoom!.roomName : state.selectedSpace!.spaceName;
    final String type = isRoom ? state.selectedRoom!.roomType : state.selectedSpace!.category;
    final String description = (isRoom ? state.selectedRoom!.description : state.selectedSpace!.description) ?? 'No description available.';
    final String imageUrl = isRoom ? (state.selectedRoom!.imageUrl ?? '') : (state.selectedSpace!.imageUrl ?? '');
    final String? modelUrl = isRoom ? state.selectedRoom!.modelUrl : state.selectedSpace!.modelUrl;
    final double price = isRoom ? state.selectedRoom!.pricePerNight : state.selectedSpace!.price;
    final String priceLabel = isRoom ? '\$${price.toStringAsFixed(0)} / night' : '\$${price.toStringAsFixed(0)} / hr';
    final List<String> amenities = isRoom ? state.selectedRoom!.amenities : state.selectedSpace!.amenities;

    return SingleChildScrollView(
      key: const ValueKey('step_space_detail'),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Banner Image
          ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: SizedBox(
              height: 220,
              width: double.infinity,
              child: Image.network(
                imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  color: const Color(0xFF1E2D4A),
                  child: const Icon(Icons.room_service, size: 48, color: AppTheme.textMuted),
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Space Title and 3D Action Row
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      type,
                      style: const TextStyle(color: AppTheme.accentCyan, fontSize: 13, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      priceLabel,
                      style: const TextStyle(color: AppTheme.accentGold, fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),

              // Button to enter 3D model inspection
              ElevatedButton.icon(
                icon: const Icon(Icons.view_in_ar, color: Colors.black87, size: 20),
                label: const Text('OPEN 3D VIEWER'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.accentCyan,
                  foregroundColor: Colors.black87,
                  textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 6,
                ),
                onPressed: () {
                  setState(() {
                    state.step = HotelTabStep.viewer3d;
                  });
                },
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Specifications Summary
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF13203C),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFF223558)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                if (isRoom) ...[
                  _buildSpecItem(Icons.king_bed, 'Bed Type', state.selectedRoom!.bedType),
                  _buildSpecItem(Icons.square_foot, 'Room Size', state.selectedRoom!.roomSize),
                  _buildSpecItem(Icons.people, 'Max Occupancy', '${state.selectedRoom!.maximumOccupancy} Guests'),
                ] else ...[
                  _buildSpecItem(Icons.meeting_room, 'Category', state.selectedSpace!.category),
                  _buildSpecItem(Icons.people, 'Capacity', '${state.selectedSpace!.capacity} Guests'),
                  _buildSpecItem(Icons.attach_money, 'Rate', '\$${state.selectedSpace!.price.toStringAsFixed(0)} / hr'),
                ],
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Description
          const Text(
            'Space Overview & Details',
            style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            description,
            style: const TextStyle(color: AppTheme.textMuted, fontSize: 14, height: 1.5),
          ),
          const SizedBox(height: 20),

          // Amenities Checklist
          const Text(
            'Included Amenities & Features',
            style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: amenities.map((a) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFF162544),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFF223558)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.check, color: AppTheme.accentCyan, size: 14),
                    const SizedBox(width: 6),
                    Text(a, style: const TextStyle(color: Colors.white, fontSize: 13)),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildSpecItem(IconData icon, String label, String value) {
    return Column(
      children: [
        Icon(icon, color: AppTheme.accentCyan, size: 20),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(color: AppTheme.textMuted, fontSize: 11)),
        const SizedBox(height: 2),
        Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
      ],
    );
  }

  // STEP 4: Interactive 3D Model Viewer
  Widget _build3dViewerView(BuildContext context, Hotel hotel, HotelTabState state) {
    final isRoom = state.selectedRoom != null;
    final String title = isRoom ? state.selectedRoom!.roomName : state.selectedSpace!.spaceName;
    final String? modelUrl = isRoom ? state.selectedRoom!.modelUrl : state.selectedSpace!.modelUrl;
    final String? fallbackImg = isRoom ? state.selectedRoom!.imageUrl : state.selectedSpace!.imageUrl;

    return SingleChildScrollView(
      key: const ValueKey('step_3d_viewer'),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.view_in_ar, color: AppTheme.accentCyan, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Interactive 3D Inspection: $title',
                  style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
              OutlinedButton.icon(
                icon: const Icon(Icons.arrow_back, color: AppTheme.accentCyan, size: 16),
                label: const Text('Back to Space Info'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.accentCyan,
                  side: const BorderSide(color: AppTheme.accentCyan),
                ),
                onPressed: () {
                  setState(() {
                    state.step = HotelTabStep.spaceDetail;
                  });
                },
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Interactive Model Viewer Container inside the tab
          Container(
            height: 390,
            decoration: BoxDecoration(
              color: const Color(0xFF070D1A),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppTheme.accentCyan.withValues(alpha: 0.35)),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: ModelViewerWidget(
                modelUrl: modelUrl,
                title: title,
                fallbackImageUrl: fallbackImg,
                height: 390,
              ),
            ),
          ),
          const SizedBox(height: 14),

          // Guidance text
          const Center(
            child: Text(
              '💡 Left-click and drag to rotate 360° • Scroll/Pinch to zoom • Right-click to pan',
              style: TextStyle(color: AppTheme.textMuted, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}
