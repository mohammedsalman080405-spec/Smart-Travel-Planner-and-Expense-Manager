import 'package:flutter/material.dart';
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
    _controller.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onTextChanged() {
    final query = _controller.text.trim();
    if (query.length >= 2) {
      _fetchSuggestions(query);
    } else {
      setState(() {
        _suggestions = [];
        _showSuggestions = false;
      });
    }
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
    if (query.trim().isEmpty) return;
    setState(() {
      _isSearching = true;
      _showSuggestions = false;
    });

    try {
      final geo = await DestinationService.geocode(query.trim());
      final double lat = (geo['latitude'] as num).toDouble();
      final double lng = (geo['longitude'] as num).toDouble();
      final String name = geo['name'] ?? query.trim();

      if (mounted) {
        // 1. Rotate & zoom globe towards target
        context.read<GlobeProvider>().setCoordinates(lat, lng, animate: true);

        // 2. Search hotels around coordinates
        context.read<HotelProvider>().searchHotels(
          latitude: lat,
          longitude: lng,
          destination: name,
        );

        if (widget.onDestinationSelected != null) {
          widget.onDestinationSelected!(name, lat, lng);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not find "$query". Try Hyderabad, Bali, Paris or Tokyo.'),
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
    return Column(
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
                child: TextField(
                  controller: _controller,
                  focusNode: _focusNode,
                  style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w500),
                  decoration: const InputDecoration(
                    hintText: 'Search destination (e.g. Hyderabad, Bali, Paris, Tokyo...)',
                    hintStyle: TextStyle(color: AppTheme.textMuted, fontSize: 15),
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    fillColor: Colors.transparent,
                    contentPadding: EdgeInsets.symmetric(vertical: 18),
                  ),
                  onSubmitted: (val) => _handleSearch(val),
                ),
              ),
              if (_controller.text.isNotEmpty)
                IconButton(
                  icon: const Icon(Icons.close, color: AppTheme.textMuted, size: 20),
                  onPressed: () {
                    _controller.clear();
                    context.read<HotelProvider>().clearSearch();
                    context.read<GlobeProvider>().resetView();
                  },
                ),
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(24),
                    onTap: _isSearching ? null : () => _handleSearch(_controller.text),
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
            ],
          ),
        ),

        // Autocomplete suggestions popup
        if (_showSuggestions && _suggestions.isNotEmpty)
          Container(
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

        // Quick destination tags
        const SizedBox(height: 14),
        Wrap(
          spacing: 8,
          runSpacing: 6,
          alignment: WrapAlignment.center,
          children: _popularDestinations.map((dest) {
            return InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () {
                _controller.text = dest;
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
      ],
    );
  }
}
