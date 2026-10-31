import 'package:flutter/material.dart';
import '../config/theme.dart';
import '../models/hotel_image.dart';

class ExteriorGallery extends StatefulWidget {
  final List<HotelImage> images;
  final String? defaultHeroUrl;

  const ExteriorGallery({
    super.key,
    required this.images,
    this.defaultHeroUrl,
  });

  @override
  State<ExteriorGallery> createState() => _ExteriorGalleryState();
}

class _ExteriorGalleryState extends State<ExteriorGallery> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final activeUrl = widget.images.isNotEmpty
        ? widget.images[_selectedIndex].imageUrl
        : widget.defaultHeroUrl;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Large Hero Photo
        ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Container(
            height: 420,
            width: double.infinity,
            decoration: BoxDecoration(
              color: AppTheme.cardNavy,
              image: activeUrl != null
                  ? DecorationImage(
                      image: NetworkImage(activeUrl),
                      fit: BoxFit.cover,
                    )
                  : null,
            ),
            child: activeUrl == null
                ? const Center(child: Icon(Icons.hotel, size: 80, color: Colors.white24))
                : Container(
                    padding: const EdgeInsets.all(16),
                    alignment: Alignment.bottomLeft,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                        colors: [
                          Colors.black.withOpacity(0.75),
                          Colors.transparent,
                        ],
                      ),
                    ),
                    child: widget.images.isNotEmpty && widget.images[_selectedIndex].caption != null
                        ? Text(
                            widget.images[_selectedIndex].caption!,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          )
                        : null,
                  ),
          ),
        ),

        // Thumbnails
        if (widget.images.length > 1) ...[
          const SizedBox(height: 12),
          SizedBox(
            height: 76,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: widget.images.length,
              separatorBuilder: (_, __) => const SizedBox(width: 10),
              itemBuilder: (context, index) {
                final isSelected = _selectedIndex == index;
                final img = widget.images[index];
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedIndex = index;
                    });
                  },
                  child: Container(
                    width: 110,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected ? AppTheme.accentCyan : AppTheme.borderNavy,
                        width: isSelected ? 2.5 : 1.0,
                      ),
                      image: DecorationImage(
                        image: NetworkImage(img.imageUrl),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ],
    );
  }
}
