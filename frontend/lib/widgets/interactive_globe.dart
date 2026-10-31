import 'package:flutter/material.dart';
import 'package:pointer_interceptor/pointer_interceptor.dart';
import 'package:provider/provider.dart';

import '../config/theme.dart';
import '../models/hotel.dart';
import '../providers/globe_provider.dart';
import '../providers/hotel_provider.dart';
import '../services/destination_service.dart';
import '../services/hotel_service.dart';
import 'globe_bridge.dart';

class InteractiveGlobe extends StatefulWidget {
  final List<Hotel> hotels;
  final Hotel? selectedHotel;
  final Function(Hotel hotel)? onHotelSelected;
  final bool isBlurred;
  final VoidCallback? onOpenCityMap;
  final VoidCallback? onReturnToGlobal;

  const InteractiveGlobe({
    super.key,
    required this.hotels,
    this.selectedHotel,
    this.onHotelSelected,
    this.isBlurred = false,
    this.onOpenCityMap,
    this.onReturnToGlobal,
  });

  @override
  State<InteractiveGlobe> createState() => _InteractiveGlobeState();
}

class _InteractiveGlobeState extends State<InteractiveGlobe> {
  bool _isGlobeReady = false;
  bool? _lastAutoRotate;
  double? _lastLatitude;
  double? _lastLongitude;
  double? _lastCameraDistance;
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
        _onHotelClickedFromGlobe(
          hotelId is int ? hotelId : int.tryParse(hotelId.toString()),
        );
      }
    } else if (type == 'SEARCH_DESTINATION') {
      final q = msg['query'];
      if (q != null && q.toString().trim().isNotEmpty) {
        _searchDestination(q.toString().trim());
      }
    } else if (type == 'OPEN_CITY_MAP') {
      widget.onOpenCityMap?.call();
    } else if (type == 'RETURN_TO_GLOBAL') {
      widget.onReturnToGlobal?.call();
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
    } else {
      HotelService.getHotelDetails(hotelId)
          .then((fetched) {
            if (mounted) {
              hotelProvider.selectHotel(fetched);
              if (widget.onHotelSelected != null) {
                widget.onHotelSelected!(fetched);
              }
            }
          })
          .catchError((_) {});
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
      'zoom': globeProvider.targetCameraDistance,
      'animate': false,
    });
    _sendMessageToGlobe({
      'type': 'TOGGLE_AUTO_ROTATE',
      'enabled': globeProvider.isAutoRotating,
    });
    _lastAutoRotate = globeProvider.isAutoRotating;
    _lastLatitude = globeProvider.targetLatitude;
    _lastLongitude = globeProvider.targetLongitude;
    _lastCameraDistance = globeProvider.targetCameraDistance;

    // 2. Send Hotels list
    if (hotelProvider.currentDestination.isNotEmpty) {
      _sendHotelsToGlobe(hotelProvider.hotels);
    } else {
      _sendMessageToGlobe({'type': 'CLEAR_HOTELS'});
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
    final hotelData = hotels
        .map(
          (h) => {
            'hotel_id': h.hotelId,
            'hotel_name': h.hotelName,
            'latitude': h.latitude,
            'longitude': h.longitude,
            'starting_price': h.startingPrice,
            'star_rating': h.starRating,
            'review_rating': h.reviewRating,
            'review_count': h.reviewCount,
            'address': h.address,
            'city': h.city,
            'country': h.country,
            'exterior_image_url': h.exteriorImageUrl,
            'is_demo': h.isDemo,
            'currency': h.currency,
          },
        )
        .toList();

    final globeProvider = context.read<GlobeProvider>();
    _sendMessageToGlobe({
      'type': 'SET_HOTELS',
      'destination_latitude': globeProvider.targetLatitude,
      'destination_longitude': globeProvider.targetLongitude,
      'hotels': hotelData,
    });
  }

  @override
  void didUpdateWidget(covariant InteractiveGlobe oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Update blur state on Three.js globe iframe
    if (widget.isBlurred != oldWidget.isBlurred) {
      _sendMessageToGlobe({'type': 'SET_BLUR', 'blurred': widget.isBlurred});
    }

    // Update hotels on globe if changed
    if (widget.hotels != oldWidget.hotels) {
      final hotelProvider = context.read<HotelProvider>();
      if (widget.hotels.isEmpty && hotelProvider.currentDestination.isEmpty) {
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
    final focusChanged =
        _lastLatitude != globeProvider.targetLatitude ||
        _lastLongitude != globeProvider.targetLongitude ||
        _lastCameraDistance != globeProvider.targetCameraDistance;
    if (_isGlobeReady && (globeProvider.isAnimatingToTarget || focusChanged)) {
      _sendMessageToGlobe({
        'type': 'FOCUS_COORDINATES',
        'latitude': globeProvider.targetLatitude,
        'longitude': globeProvider.targetLongitude,
        'zoom': globeProvider.targetCameraDistance,
        'animate': globeProvider.isAnimatingToTarget,
      });
      _lastLatitude = globeProvider.targetLatitude;
      _lastLongitude = globeProvider.targetLongitude;
      _lastCameraDistance = globeProvider.targetCameraDistance;
      if (globeProvider.isAnimatingToTarget) globeProvider.stopAnimation();
    }
    if (_isGlobeReady && _lastAutoRotate != globeProvider.isAutoRotating) {
      _sendMessageToGlobe({
        'type': 'TOGGLE_AUTO_ROTATE',
        'enabled': globeProvider.isAutoRotating,
      });
      _lastAutoRotate = globeProvider.isAutoRotating;
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
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.4),
                    blurRadius: 14,
                  ),
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
                        'type': 'ZOOM_STEP',
                        'direction': 'in',
                      });
                    },
                  ),
                  IconButton(
                    icon: const Icon(
                      Icons.remove,
                      color: Colors.white,
                      size: 20,
                    ),
                    tooltip: 'Zoom Out',
                    onPressed: () {
                      _sendMessageToGlobe({
                        'type': 'ZOOM_STEP',
                        'direction': 'out',
                      });
                    },
                  ),
                  IconButton(
                    icon: Icon(
                      globeProvider.isAutoRotating
                          ? Icons.pause
                          : Icons.play_arrow,
                      color: globeProvider.isAutoRotating
                          ? AppTheme.accentCyan
                          : Colors.white70,
                      size: 20,
                    ),
                    tooltip: globeProvider.isAutoRotating
                        ? 'Pause Rotation'
                        : 'Auto Rotate',
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
                    icon: const Icon(
                      Icons.refresh,
                      color: Colors.white70,
                      size: 20,
                    ),
                    tooltip: 'Reset Global View',
                    onPressed: () {
                      if (widget.onReturnToGlobal != null) {
                        widget.onReturnToGlobal!();
                      } else {
                        globeProvider.resetView();
                        hotelProvider.clearSearch();
                        _sendMessageToGlobe({'type': 'RESET_VIEW'});
                        _sendMessageToGlobe({'type': 'CLEAR_HOTELS'});
                      }
                    },
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
