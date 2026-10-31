import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/hotel.dart';
import '../providers/hotel_provider.dart';
import '../services/hotel_service.dart';
import 'hyderabad_map_bridge.dart';

class HyderabadDiscoveryMap extends StatefulWidget {
  final Function(Hotel hotel)? onHotelSelected;
  final bool isBlurred;
  final String destination;
  final double latitude;
  final double longitude;
  final List<Hotel> hotels;
  final void Function(double latitude, double longitude)? onReturnToGlobe;

  const HyderabadDiscoveryMap({
    super.key,
    this.onHotelSelected,
    this.isBlurred = false,
    this.destination = '',
    this.latitude = 20,
    this.longitude = 20,
    this.hotels = const [],
    this.onReturnToGlobe,
  });

  @override
  State<HyderabadDiscoveryMap> createState() => _HyderabadDiscoveryMapState();
}

class _HyderabadDiscoveryMapState extends State<HyderabadDiscoveryMap> {
  void Function(Map<String, dynamic> msg)? _mapSender;
  bool _mapReady = false;

  void _onSenderReady(void Function(Map<String, dynamic> msg) sender) {
    _mapSender = sender;
    if (widget.isBlurred) {
      _mapSender?.call({'type': 'SET_BLUR', 'blurred': true});
    }
  }

  void _sendMapState() {
    if (!_mapReady) return;
    _mapSender?.call({
      'type': 'SET_DESTINATION',
      'name': widget.destination,
      'latitude': widget.latitude,
      'longitude': widget.longitude,
    });
    _mapSender?.call({
      'type': 'SET_HOTELS',
      'hotels': widget.hotels
          .map(
            (hotel) => {
              'hotel_id': hotel.hotelId,
              'hotel_name': hotel.hotelName,
              'latitude': hotel.latitude,
              'longitude': hotel.longitude,
              'star_rating': hotel.starRating,
              'review_rating': hotel.reviewRating,
              'review_count': hotel.reviewCount,
              'starting_price': hotel.startingPrice,
              'currency': hotel.currency,
              'exterior_image_url': hotel.exteriorImageUrl,
            },
          )
          .toList(),
    });
  }

  void _onMessageReceived(Map<String, dynamic> msg) {
    final type = msg['type'];
    if (type == 'MAP_READY') {
      _mapReady = true;
      _sendMapState();
      return;
    }
    if (type == 'RETURN_TO_GLOBE') {
      final lat = (msg['latitude'] as num?)?.toDouble() ?? widget.latitude;
      final lng = (msg['longitude'] as num?)?.toDouble() ?? widget.longitude;
      widget.onReturnToGlobe?.call(lat, lng);
      return;
    }
    if (type == 'HOTEL_CLICKED') {
      final hotelId = msg['hotelId'];
      final hotelName = msg['hotelName']?.toString();
      _onHotelClicked(
        hotelId is int ? hotelId : int.tryParse(hotelId.toString()),
        hotelName,
      );
    }
  }

  void _onHotelClicked(int? hotelId, String? hotelName) {
    final hotelProvider = context.read<HotelProvider>();
    Hotel? matched;
    for (final hotel in hotelProvider.hotels) {
      if ((hotelId != null && hotel.hotelId == hotelId) ||
          (hotelName != null &&
              hotel.hotelName.toLowerCase().contains(
                hotelName.toLowerCase(),
              ))) {
        matched = hotel;
        break;
      }
    }

    if (matched != null) {
      hotelProvider.selectHotel(matched);
      widget.onHotelSelected?.call(matched);
    } else if (hotelId != null) {
      HotelService.getHotelDetails(hotelId)
          .then((fetched) {
            if (mounted) {
              hotelProvider.selectHotel(fetched);
              widget.onHotelSelected?.call(fetched);
            }
          })
          .catchError((_) {});
    }
  }

  @override
  void didUpdateWidget(covariant HyderabadDiscoveryMap oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isBlurred != widget.isBlurred) {
      _mapSender?.call({'type': 'SET_BLUR', 'blurred': widget.isBlurred});
    }
    if (oldWidget.destination != widget.destination ||
        oldWidget.latitude != widget.latitude ||
        oldWidget.longitude != widget.longitude ||
        oldWidget.hotels != widget.hotels) {
      _sendMapState();
    }
  }

  @override
  Widget build(BuildContext context) => buildHyderabadMap(
    onMessageReceived: _onMessageReceived,
    onSenderReady: _onSenderReady,
  );
}
