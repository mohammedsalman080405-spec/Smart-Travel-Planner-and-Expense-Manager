import 'package:flutter/material.dart';
import 'package:pointer_interceptor/pointer_interceptor.dart';
import 'package:provider/provider.dart';

import '../config/theme.dart';
import '../providers/globe_provider.dart';
import '../providers/hotel_provider.dart';
import '../services/destination_service.dart';

class DestinationSearchBar extends StatefulWidget {
  final String? initialValue;
  final Function(String query, double lat, double lng)? onDestinationSelected;
  final VoidCallback? onCleared;

  const DestinationSearchBar({
    super.key,
    this.initialValue,
    this.onDestinationSelected,
    this.onCleared,
  });

  @override
  State<DestinationSearchBar> createState() => _DestinationSearchBarState();
}

class _DestinationSearchBarState extends State<DestinationSearchBar> {
  late final TextEditingController _controller;
  final FocusNode _focusNode = FocusNode();
  bool _isSearching = false;
  int _searchGeneration = 0;
  List<Map<String, dynamic>> _suggestions = [];
  bool _showSuggestions = false;
  int _suggestionRequest = 0;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue ?? '');
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
    final request = ++_suggestionRequest;
    try {
      final results = await DestinationService.search(query);
      if (mounted && request == _suggestionRequest) {
        setState(() {
          _suggestions = results
              .map(
                (d) => {
                  'name': d.name,
                  'city': d.city,
                  'country': d.country,
                  'lat': d.latitude,
                  'lng': d.longitude,
                },
              )
              .toList();
          _showSuggestions = _suggestions.isNotEmpty;
        });
      }
    } catch (_) {}
  }

  Future<void> _handleSearch(String query) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty || _isSearching) return;
    final generation = ++_searchGeneration;

    debugPrint('[Search] Search API requested: query="$trimmed"');
    setState(() {
      _isSearching = true;
      _showSuggestions = false;
    });

    try {
      final geo = await DestinationService.geocode(trimmed);
      final double lat = (geo['latitude'] as num?)?.toDouble() ?? 0.0;
      final double lng = (geo['longitude'] as num?)?.toDouble() ?? 0.0;
      final String name = geo['name']?.toString() ?? trimmed;
      if (!lat.isFinite ||
          !lng.isFinite ||
          lat < -90 ||
          lat > 90 ||
          lng < -180 ||
          lng > 180 ||
          (lat == 0 && lng == 0)) {
        throw const FormatException(
          'The destination did not return valid coordinates.',
        );
      }
      if (!mounted || generation != _searchGeneration) return;
      debugPrint(
        '[Search] API response received: lat=$lat, lng=$lng, name="$name"',
      );

      if (mounted) {
        // 1. Rotate & zoom globe towards target coordinates
        context.read<GlobeProvider>().setCoordinates(lat, lng, animate: true);
        widget.onDestinationSelected?.call(name, lat, lng);

        // 2. Search hotels around coordinates
        debugPrint(
          '[Search] Fetching nearby hotels around $name ($lat, $lng)...',
        );
        await context.read<HotelProvider>().searchHotels(
          latitude: lat,
          longitude: lng,
          destination: name,
        );
        if (!mounted || generation != _searchGeneration) return;
        await Future<void>.delayed(const Duration(milliseconds: 1500));
        if (!mounted || generation != _searchGeneration) return;
        final hotelCount = context.read<HotelProvider>().hotels.length;
        debugPrint('[Search] Hotel marker data received: count=$hotelCount');
      }
    } catch (e) {
      debugPrint('[Search] Error during search: $e');
      if (mounted && generation == _searchGeneration) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Could not find "$trimmed". Try Hyderabad, Bali, Paris, Dubai, or Tokyo.',
            ),
            backgroundColor: AppTheme.accentRose,
          ),
        );
      }
    } finally {
      if (mounted && generation == _searchGeneration) {
        setState(() {
          _isSearching = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final viewportWidth = MediaQuery.sizeOf(context).width;
    final barWidth = viewportWidth < 520 ? viewportWidth - 32 : 480.0;
    return PointerInterceptor(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Search Input Bar (Sleek floating capsule)
          Container(
            width: barWidth,
            constraints: const BoxConstraints(maxWidth: 520),
            decoration: BoxDecoration(
              color: const Color(0xFF070E1A).withValues(alpha: 0.90),
              borderRadius: BorderRadius.circular(28),
              border: Border.all(
                color: AppTheme.cyanAccent.withValues(alpha: 0.45),
                width: 1.2,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.7),
                  blurRadius: 20,
                  offset: const Offset(0, 6),
                ),
                BoxShadow(
                  color: AppTheme.cyanAccent.withValues(alpha: 0.18),
                  blurRadius: 14,
                  spreadRadius: 1,
                ),
              ],
            ),
            child: Row(
              children: [
                const SizedBox(width: 14),
                const Icon(Icons.search, color: AppTheme.cyanAccent, size: 20),
                const SizedBox(width: 10),
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
                        cursorColor: AppTheme.cyanAccent,
                        cursorWidth: 2.0,
                        cursorRadius: const Radius.circular(2),
                        showCursor: true,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14.5,
                          fontWeight: FontWeight.w500,
                        ),
                        decoration: const InputDecoration(
                          hintText: 'Search destination (e.g. Hyderabad, Delhi, Paris)',
                          hintStyle: TextStyle(
                            color: AppTheme.textMuted,
                            fontSize: 14,
                          ),
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          fillColor: Colors.transparent,
                          contentPadding: EdgeInsets.symmetric(vertical: 10),
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
                      icon: const Icon(
                        Icons.close,
                        color: AppTheme.textMuted,
                        size: 18,
                      ),
                      tooltip: 'Clear search',
                      onPressed: () {
                        debugPrint('[Search] Clear button pressed');
                        _controller.clear();
                        _searchGeneration++;
                        setState(() {
                          _isSearching = false;
                          _showSuggestions = false;
                          _suggestions = [];
                        });
                        context.read<HotelProvider>().clearSearch();
                        context.read<GlobeProvider>().resetView();
                        widget.onCleared?.call();
                      },
                    ),
                  ),
                Padding(
                  padding: const EdgeInsets.only(right: 5),
                  child: PointerInterceptor(
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(20),
                        onTap: _isSearching
                            ? null
                            : () {
                                debugPrint(
                                  '[Search] Search button pressed with: "${_controller.text}"',
                                );
                                _handleSearch(_controller.text);
                              },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF00D9FF), Color(0xFF0075FF)],
                            ),
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: AppTheme.cyanAccent.withValues(
                                  alpha: 0.35,
                                ),
                                blurRadius: 10,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: _isSearching
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2.0,
                                  ),
                                )
                              : const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.search,
                                      color: Colors.white,
                                      size: 16,
                                    ),
                                    SizedBox(width: 6),
                                    Text(
                                      'Search',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w700,
                                        fontSize: 13.5,
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
                width: barWidth,
                constraints: const BoxConstraints(
                  maxWidth: 520,
                  maxHeight: 220,
                ),
                margin: const EdgeInsets.only(top: 8),
                decoration: BoxDecoration(
                  color: AppTheme.cardNavy.withValues(alpha: 0.96),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppTheme.borderNavy),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.5),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: _suggestions.length,
                  separatorBuilder: (_, _) =>
                      const Divider(color: AppTheme.borderNavy, height: 1),
                  itemBuilder: (context, index) {
                    final s = _suggestions[index];
                    return ListTile(
                      dense: true,
                      leading: const Icon(
                        Icons.location_on,
                        color: AppTheme.accentCyan,
                        size: 20,
                      ),
                      title: Text(
                        '${s['city']}, ${s['country']}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
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
        ],
      ),
    );
  }
}
