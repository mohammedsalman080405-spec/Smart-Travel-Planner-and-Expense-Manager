import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/hotel.dart';
import '../providers/hotel_provider.dart';
import '../services/hotel_service.dart';
import 'hyderabad_map_bridge.dart';

class HyderabadDiscoveryMap extends StatefulWidget {
  final Function(Hotel hotel)? onHotelSelected;
  final bool isBlurred;

  const HyderabadDiscoveryMap({
    super.key,
    this.onHotelSelected,
    this.isBlurred = false,
  });

  @override
  State<HyderabadDiscoveryMap> createState() => _HyderabadDiscoveryMapState();
}

class _HyderabadDiscoveryMapState extends State<HyderabadDiscoveryMap> {
  void Function(Map<String, dynamic> msg)? _mapSender;

  void _onSenderReady(void Function(Map<String, dynamic> msg) sender) {
    _mapSender = sender;
    if (widget.isBlurred) {
      _mapSender?.call({'type': 'SET_BLUR', 'blurred': true});
    }
  }

  @override
  void didUpdateWidget(covariant HyderabadDiscoveryMap oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isBlurred != widget.isBlurred) {
      _mapSender?.call({'type': 'SET_BLUR', 'blurred': widget.isBlurred});
    }
  }

  void _onMessageReceived(Map<String, dynamic> msg) {
    final type = msg['type'];

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

    // 1. Try to find in already loaded hotels
    Hotel? matched;
    for (var h in hotelProvider.hotels) {
      if (hotelId != null && h.hotelId == hotelId) {
        matched = h;
        break;
      }
      if (hotelName != null && h.hotelName.toLowerCase().contains(hotelName.toLowerCase())) {
        matched = h;
        break;
      }
    }

    if (matched != null) {
      hotelProvider.selectHotel(matched);
      widget.onHotelSelected?.call(matched);
    } else if (hotelId != null) {
      // 2. Fetch from backend and select
      HotelService.getHotelDetails(hotelId).then((fetched) {
        if (mounted) {
          hotelProvider.selectHotel(fetched);
          widget.onHotelSelected?.call(fetched);
        }
      }).catchError((_) {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return buildHyderabadMap(
      onMessageReceived: _onMessageReceived,
      onSenderReady: _onSenderReady,
    );
  }
}
