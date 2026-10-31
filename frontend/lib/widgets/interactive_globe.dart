import 'package:flutter/material.dart';
import 'package:pointer_interceptor/pointer_interceptor.dart';
import 'package:provider/provider.dart';
import '../config/theme.dart';
import '../models/hotel.dart';
import '../providers/globe_provider.dart';
import '../providers/hotel_provider.dart';
import '../services/destination_service.dart';
import 'globe_bridge.dart';

class InteractiveGlobe extends StatefulWidget {
  final List<Hotel> hotels;
  final Hotel? selectedHotel;
  final Function(Hotel hotel)? onHotelSelected;

  const InteractiveGlobe({
    super.key,
    required this.hotels,
    this.selectedHotel,
    this.onHotelSelected,
  });

  @override
  State<InteractiveGlobe> createState() => _InteractiveGlobeState();
}

class _InteractiveGlobeState extends State<InteractiveGlobe> {
  bool _isGlobeReady = false;
  void Function(Map<String, dynamic> msg)? _globeSender;

  void _onSenderReady(void Function(Map<String, dynamic> msg) sender) {
    _globeSender = sender;
  }

  void _onMessageReceived(Map<String, dynamic> msg) {
    final type = msg['type'];

    if (type == 'GLOBE_READY') {
      if (mounted) {
        setState(() {
          _isGlobeReady = true;
        });
        _sendCurrentStateToGlobe();
      }
    } else if (type == 'HOTEL_CLICKED') {
      final hotelId = msg['hotelId'];
      if (hotelId != null) {
        _onHotelClickedFromGlobe(hotelId is int ? hotelId : int.tryParse(hotelId.toString()));
      }
    } else if (type == 'SEARCH_DESTINATION') {
      final q = msg['query'];
      if (q != null && q.toString().trim().isNotEmpty) {
        _searchDestination(q.toString().trim());
      }
    }
  }

  Future<void> _searchDestination(String query) async {
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
      }
    } catch (_) {}
  }

  void _onHotelClickedFromGlobe(int? hotelId) {
    if (hotelId == null) return;
    final hotelProvider = context.read<HotelProvider>();

    Hotel? matched;
    for (var h in hotelProvider.hotels) {
      if (h.hotelId == hotelId) {
        matched = h;
        break;
      }
    }

    if (matched != null) {
      hotelProvider.selectHotel(matched);
      if (widget.onHotelSelected != null) {
        widget.onHotelSelected!(matched);
      }
    }
  }

  void _sendMessageToGlobe(Map<String, dynamic> message) {
    _globeSender?.call(message);
  }

  void _sendCurrentStateToGlobe() {
    final globeProvider = context.read<GlobeProvider>();
    final hotelProvider = context.read<HotelProvider>();

    // 1. Send Focus Coordinates
    _sendMessageToGlobe({
      'type': 'FOCUS_COORDINATES',
      'latitude': globeProvider.targetLatitude,
      'longitude': globeProvider.targetLongitude,
      'zoom': globeProvider.zoomLevel > 1.2 ? 8.8 : 12.5,
      'animate': false,
    });

    // 2. Send Hotels list
    if (hotelProvider.hotels.isNotEmpty) {
      _sendHotelsToGlobe(hotelProvider.hotels);
    }

    // 3. Send Selected Hotel
    if (hotelProvider.selectedHotel != null) {
      _sendMessageToGlobe({
        'type': 'SELECT_HOTEL',
        'hotelId': hotelProvider.selectedHotel!.hotelId,
      });
    }
  }

  void _sendHotelsToGlobe(List<Hotel> hotels) {
    final hotelData = hotels.map((h) => {
      'hotel_id': h.hotelId,
      'hotel_name': h.hotelName,
      'latitude': h.latitude,
      'longitude': h.longitude,
      'starting_price': h.startingPrice,
      'star_rating': h.starRating,
      'review_rating': h.reviewRating,
      'address': h.address,
      'city': h.city,
      'country': h.country,
      'exterior_image_url': h.exteriorImageUrl,
      'is_demo': h.isDemo,
    }).toList();

    _sendMessageToGlobe({
      'type': 'SET_HOTELS',
      'hotels': hotelData,
    });
  }

  @override
  void didUpdateWidget(covariant InteractiveGlobe oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Update hotels on globe if changed
    if (widget.hotels != oldWidget.hotels) {
      if (widget.hotels.isEmpty) {
        _sendMessageToGlobe({'type': 'CLEAR_HOTELS'});
      } else {
        _sendHotelsToGlobe(widget.hotels);
      }
    }

    // Update selected hotel marker
    if (widget.selectedHotel?.hotelId != oldWidget.selectedHotel?.hotelId) {
      if (widget.selectedHotel != null) {
        _sendMessageToGlobe({
          'type': 'SELECT_HOTEL',
          'hotelId': widget.selectedHotel!.hotelId,
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final globeProvider = context.watch<GlobeProvider>();
    final hotelProvider = context.watch<HotelProvider>();

    // Sync coordinate changes to Three.js globe
    if (_isGlobeReady && globeProvider.isAnimatingToTarget) {
      _sendMessageToGlobe({
        'type': 'FOCUS_COORDINATES',
        'latitude': globeProvider.targetLatitude,
        'longitude': globeProvider.targetLongitude,
        'zoom': 8.8,
        'animate': true,
      });
      globeProvider.stopAnimation();
    }

    return Stack(
      fit: StackFit.expand,
      children: [
        // Real Three.js WebGL Realistic NASA Blue Marble Earth Globe
        Positioned.fill(
          child: buildEarthGlobe(
            onMessageReceived: _onMessageReceived,
            onSenderReady: _onSenderReady,
          ),
        ),

        // Floating Globe Control Buttons (Pause Rotation, Reset, Zoom In/Out)
        Positioned(
          left: 24,
          bottom: 24,
          child: PointerInterceptor(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
              decoration: BoxDecoration(
                color: AppTheme.cardNavy.withValues(alpha: 0.9),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: AppTheme.borderNavy),
                boxShadow: [
                  BoxShadow(color: Colors.black.withValues(alpha: 0.4), blurRadius: 14),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.add, color: Colors.white, size: 20),
                    tooltip: 'Zoom In',
                    onPressed: () {
                      _sendMessageToGlobe({
                        'type': 'FOCUS_COORDINATES',
                        'latitude': globeProvider.targetLatitude,
                        'longitude': globeProvider.targetLongitude,
                        'zoom': 7.6,
                        'animate': true,
                      });
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.remove, color: Colors.white, size: 20),
                    tooltip: 'Zoom Out',
                    onPressed: () {
                      _sendMessageToGlobe({
                        'type': 'FOCUS_COORDINATES',
                        'latitude': globeProvider.targetLatitude,
                        'longitude': globeProvider.targetLongitude,
                        'zoom': 14.0,
                        'animate': true,
                      });
                    },
                  ),
                  IconButton(
                    icon: Icon(
                      globeProvider.isAutoRotating ? Icons.pause : Icons.play_arrow,
                      color: globeProvider.isAutoRotating ? AppTheme.accentCyan : Colors.white70,
                      size: 20,
                    ),
                    tooltip: globeProvider.isAutoRotating ? 'Pause Rotation' : 'Auto Rotate',
                    onPressed: () {
                      final next = !globeProvider.isAutoRotating;
                      globeProvider.toggleAutoRotate(next);
                      _sendMessageToGlobe({
                        'type': 'TOGGLE_AUTO_ROTATE',
                        'enabled': next,
                      });
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.refresh, color: Colors.white70, size: 20),
                    tooltip: 'Reset Global View',
                    onPressed: () {
                      globeProvider.resetView();
                      hotelProvider.clearSearch();
                      _sendMessageToGlobe({'type': 'RESET_VIEW'});
                      _sendMessageToGlobe({'type': 'CLEAR_HOTELS'});
                    },
                  ),
                ],
              ),
            ),
          ),
        ),

        // Live Properties Badge if hotels are present on globe
        if (widget.hotels.isNotEmpty)
          Positioned(
            top: 24,
            left: 24,
            child: PointerInterceptor(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: AppTheme.cardNavy.withValues(alpha: 0.92),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppTheme.accentCyan.withValues(alpha: 0.6)),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.accentCyan.withValues(alpha: 0.2),
                      blurRadius: 16,
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.location_on, color: AppTheme.accentCyan, size: 18),
                    const SizedBox(width: 8),
                    Text(
                      '${widget.hotels.length} Hotel Points Placed on Earth',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(width: 14),
                    DropdownButtonHideUnderline(
                      child: DropdownButton<double>(
                        value: hotelProvider.searchRadiusKm,
                        dropdownColor: AppTheme.cardNavy,
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
              ),
            ),
          ),
      ],
    );
  }
}
