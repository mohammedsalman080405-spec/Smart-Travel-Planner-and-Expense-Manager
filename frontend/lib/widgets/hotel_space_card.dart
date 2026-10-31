import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../config/theme.dart';
import '../models/hotel_space.dart';

class HotelSpaceCard extends StatelessWidget {
  final HotelSpace space;

  const HotelSpaceCard({
    super.key,
    required this.space,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.cardNavy,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderNavy),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 16,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Space Image
          Stack(
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                child: Container(
                  height: 190,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E2D4A),
                    image: space.imageUrl != null
                        ? DecorationImage(
                            image: NetworkImage(space.imageUrl!),
                            fit: BoxFit.cover,
                          )
                        : null,
                  ),
                  child: space.imageUrl == null
                      ? const Center(child: Icon(Icons.meeting_room, size: 48, color: Colors.white24))
                      : null,
                ),
              ),
              if (space.has3dModel)
                Positioned(
                  top: 12,
                  left: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0D1B36).withOpacity(0.9),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppTheme.accentCyan, width: 1.2),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.view_in_ar, color: AppTheme.accentCyan, size: 14),
                        SizedBox(width: 5),
                        Text(
                          '3D Model Available',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              Positioned(
                top: 12,
                right: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.75),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    space.category.replaceAll('_', ' ').toUpperCase(),
                    style: const TextStyle(color: Colors.white70, fontSize: 10.5, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),

          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  space.spaceName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 8),

                // Specs: Capacity, Size, Hours
                Row(
                  children: [
                    const Icon(Icons.groups_outlined, color: AppTheme.textMuted, size: 16),
                    const SizedBox(width: 4),
                    Text('Capacity ${space.capacity}', style: const TextStyle(color: AppTheme.textMuted, fontSize: 12)),
                    const SizedBox(width: 14),
                    const Icon(Icons.square_foot, color: AppTheme.textMuted, size: 16),
                    const SizedBox(width: 4),
                    Text(space.size, style: const TextStyle(color: AppTheme.textMuted, fontSize: 12)),
                    const SizedBox(width: 14),
                    const Icon(Icons.access_time, color: AppTheme.textMuted, size: 16),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        space.openingHours,
                        style: const TextStyle(color: AppTheme.textMuted, fontSize: 12),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 10),

                if (space.description != null)
                  Text(
                    space.description!,
                    style: const TextStyle(color: Colors.white70, fontSize: 12.5, height: 1.4),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),

                const SizedBox(height: 16),

                // Action Button: Explore 3D Space
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.view_in_ar, size: 16),
                    label: Text(space.has3dModel ? 'Inspect Space in 3D' : 'View Space Details'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    onPressed: () {
                      context.push('/space/${space.spaceId}');
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
