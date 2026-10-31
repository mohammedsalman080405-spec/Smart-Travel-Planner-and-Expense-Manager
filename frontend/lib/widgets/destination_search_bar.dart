import 'package:flutter/material.dart';
import 'package:pointer_interceptor/pointer_interceptor.dart';
import 'package:provider/provider.dart';
import '../config/theme.dart';
import '../providers/globe_provider.dart';
import '../providers/hotel_provider.dart';
import '../services/destination_service.dart';

class DestinationSearchBar extends StatefulWidget {
  final Function(String query, double lat, double lng)? onDestinationSelected;

  const DestinationSearchBar({super.key, this.onDestinationSelected});

  @override
  State<DestinationSearchBar> createState() => _DestinationSearchBarState();
}

class _DestinationSearchBarState extends State<DestinationSearchBar> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  bool _isSearching = false;
  List<Map<String, dynamic>> _suggestions = [];
  bool _showSuggestions = false;

  final List<String> _popularDestinations = [
    'Hyderabad', 'Dubai', 'Bali', 'Paris', 'Tokyo', 'Singapore', 'Mumbai', 'London', 'New York'
  ];

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(() {
      debugPrint('[Search] Search field focused: ${_focusNode.hasFocus}');
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _fetchSuggestions(String query) async {
    try {
      final results = await DestinationService.search(query);
      if (mounted) {
        setState(() {
          _suggestions = results.map((d) => {
            'name': d.name,
            'city': d.city,
            'country': d.country,
            'lat': d.latitude,
            'lng': d.longitude,
          }).toList();
          _showSuggestions = _suggestions.isNotEmpty;
        });
      }
    } catch (_) {}
  }

  Future<void> _handleSearch(String query) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) return;

    debugPrint('[Search] Search API requested: query="$trimmed"');
    setState(() {
      _isSearching = true;
      _showSuggestions = false;
    });

    try {
      final geo = await DestinationService.geocode(trimmed);
      final double lat = (geo['latitude'] as num).toDouble();
      final double lng = (geo['longitude'] as num).toDouble();
      final String name = geo['name'] ?? trimmed;
      debugPrint('[Search] API response received: lat=$lat, lng=$lng, name="$name"');

      if (mounted) {
        // 1. Rotate & zoom globe towards target coordinates
        context.read<GlobeProvider>().setCoordinates(lat, lng, animate: true);

        // 2. Search hotels around coordinates
        debugPrint('[Search] Fetching nearby hotels around $name ($lat, $lng)...');
        await context.read<HotelProvider>().searchHotels(
          latitude: lat,
          longitude: lng,
          destination: name,
        );
        final hotelCount = context.read<HotelProvider>().hotels.length;
        debugPrint('[Search] Hotel marker data received: count=$hotelCount');

        if (widget.onDestinationSelected != null) {
          widget.onDestinationSelected!(name, lat, lng);
        }
      }
    } catch (e) {
      debugPrint('[Search] Error during search: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not find "$trimmed". Try Hyderabad, Bali, Paris, Dubai, or Tokyo.'),
            backgroundColor: AppTheme.accentRose,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSearching = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return PointerInterceptor(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Search Input Bar (Sleek floating capsule)
          Container(
            width: 580,
            constraints: const BoxConstraints(maxWidth: 620),
            decoration: BoxDecoration(
              color: const Color(0xFF131F38).withOpacity(0.92),
              borderRadius: BorderRadius.circular(32),
              border: Border.all(color: AppTheme.borderNavy.withOpacity(0.8), width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.4),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
                BoxShadow(
                  color: AppTheme.accentCyan.withOpacity(0.08),
                  blurRadius: 18,
                  spreadRadius: 2,
                )
              ],
            ),
            child: Row(
              children: [
                const SizedBox(width: 20),
                const Icon(Icons.travel_explore, color: AppTheme.accentCyan, size: 24),
                const SizedBox(width: 14),
                Expanded(
                  child: PointerInterceptor(
                    child: Material(
                      color: Colors.transparent,
                      child: TextField(
                        controller: _controller,
                        focusNode: _focusNode,
                        enabled: true,
                        readOnly: false,
                        autofocus: false,
                        cursorColor: AppTheme.accentCyan,
                        cursorWidth: 2.0,
                        cursorRadius: const Radius.circular(2),
                        showCursor: true,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                        decoration: const InputDecoration(
                          hintText: 'Search destination (e.g. Hyderabad, Bali, Paris, Tokyo...)',
                          hintStyle: TextStyle(color: AppTheme.textMuted, fontSize: 15),
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          fillColor: Colors.transparent,
                          contentPadding: EdgeInsets.symmetric(vertical: 18),
                        ),
                        onTap: () {
                          debugPrint('[Search] Search field tapped');
                        },
                        onChanged: (val) {
                          debugPrint('[Search] Text entered: "$val"');
                          setState(() {}); // Update clear button visibility
                          if (val.trim().length >= 2) {
                            _fetchSuggestions(val.trim());
                          } else if (_showSuggestions) {
                            setState(() {
                              _suggestions = [];
                              _showSuggestions = false;
                            });
                          }
                        },
                        onSubmitted: (val) {
                          debugPrint('[Search] Enter key pressed with: "$val"');
                          _handleSearch(val);
                        },
                      ),
                    ),
                  ),
                ),
                if (_controller.text.isNotEmpty)
                  PointerInterceptor(
                    child: IconButton(
                      icon: const Icon(Icons.close, color: AppTheme.textMuted, size: 20),
                      tooltip: 'Clear search',
                      onPressed: () {
                        debugPrint('[Search] Clear button pressed');
                        _controller.clear();
                        setState(() {
                          _showSuggestions = false;
                          _suggestions = [];
                        });
                        context.read<HotelProvider>().clearSearch();
                        context.read<GlobeProvider>().resetView();
                      },
                    ),
                  ),
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: PointerInterceptor(
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(24),
                        onTap: _isSearching ? null : () {
                          debugPrint('[Search] Explore button pressed with: "${_controller.text}"');
                          _handleSearch(_controller.text);
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF00D2FF), Color(0xFF3B82F6)],
                            ),
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: [
                              BoxShadow(
                                color: AppTheme.accentCyan.withOpacity(0.3),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              )
                            ],
                          ),
                          child: _isSearching
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.2),
                                )
                              : const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.search, color: Colors.white, size: 20),
                                    SizedBox(width: 6),
                                    Text(
                                      'Explore',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Autocomplete suggestions popup
          if (_showSuggestions && _suggestions.isNotEmpty)
            PointerInterceptor(
              child: Container(
                width: 580,
                constraints: const BoxConstraints(maxWidth: 620, maxHeight: 220),
                margin: const EdgeInsets.only(top: 8),
                decoration: BoxDecoration(
                  color: AppTheme.cardNavy.withOpacity(0.96),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppTheme.borderNavy),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.5),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    )
                  ],
                ),
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: _suggestions.length,
                  separatorBuilder: (_, __) => const Divider(color: AppTheme.borderNavy, height: 1),
                  itemBuilder: (context, index) {
                    final s = _suggestions[index];
                    return ListTile(
                      dense: true,
                      leading: const Icon(Icons.location_on, color: AppTheme.accentCyan, size: 20),
                      title: Text(
                        '${s['city']}, ${s['country']}',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                      ),
                      onTap: () {
                        _controller.text = s['city'];
                        _handleSearch(s['city']);
                      },
                    );
                  },
                ),
              ),
            ),

          // Quick destination tags
          const SizedBox(height: 14),
          PointerInterceptor(
            child: Wrap(
              spacing: 8,
              runSpacing: 6,
              alignment: WrapAlignment.center,
              children: _popularDestinations.map((dest) {
                return InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () {
                    debugPrint('[Search] Destination pill clicked: "$dest"');
                    _controller.text = dest;
                    setState(() {});
                    _handleSearch(dest);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF111E38).withOpacity(0.7),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppTheme.borderNavy.withOpacity(0.6)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.near_me, color: AppTheme.accentCyan, size: 13),
                        const SizedBox(width: 5),
                        Text(
                          dest,
                          style: const TextStyle(color: AppTheme.textMuted, fontSize: 13, fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}
