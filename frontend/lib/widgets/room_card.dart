import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../config/theme.dart';
import '../models/room.dart';

class RoomCard extends StatelessWidget {
  final Room room;
  final VoidCallback onBook;

  const RoomCard({
    super.key,
    required this.room,
    required this.onBook,
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
          // Room Image with 3D availability pill
          Stack(
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                child: Container(
                  height: 190,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E2D4A),
                    image: room.imageUrl != null
                        ? DecorationImage(
                            image: NetworkImage(room.imageUrl!),
                            fit: BoxFit.cover,
                          )
                        : null,
                  ),
                  child: room.imageUrl == null
                      ? const Center(child: Icon(Icons.bed, size: 48, color: Colors.white24))
                      : null,
                ),
              ),
              if (room.has3dModel)
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
                    room.roomType,
                    style: const TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.w600),
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
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        room.roomName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    RichText(
                      text: TextSpan(
                        children: [
                          TextSpan(
                            text: '\$${room.pricePerNight.toStringAsFixed(0)}',
                            style: const TextStyle(
                              color: AppTheme.accentCyan,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const TextSpan(
                            text: ' / night',
                            style: TextStyle(color: AppTheme.textMuted, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 8),

                // Specs: Bed, Size, Occupancy
                Row(
                  children: [
                    const Icon(Icons.king_bed_outlined, color: AppTheme.textMuted, size: 16),
                    const SizedBox(width: 4),
                    Text(room.bedType, style: const TextStyle(color: AppTheme.textMuted, fontSize: 12)),
                    const SizedBox(width: 14),
                    const Icon(Icons.square_foot, color: AppTheme.textMuted, size: 16),
                    const SizedBox(width: 4),
                    Text(room.roomSize, style: const TextStyle(color: AppTheme.textMuted, fontSize: 12)),
                    const SizedBox(width: 14),
                    const Icon(Icons.person_outline, color: AppTheme.textMuted, size: 16),
                    const SizedBox(width: 4),
                    Text('Up to ${room.maximumOccupancy}', style: const TextStyle(color: AppTheme.textMuted, fontSize: 12)),
                  ],
                ),

                const SizedBox(height: 10),

                if (room.description != null)
                  Text(
                    room.description!,
                    style: const TextStyle(color: Colors.white70, fontSize: 12.5, height: 1.4),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),

                const SizedBox(height: 12),

                // Amenities
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: room.amenities.take(4).map((a) {
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF13203C),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        a,
                        style: const TextStyle(color: AppTheme.textMuted, fontSize: 11),
                      ),
                    );
                  }).toList(),
                ),

                const SizedBox(height: 16),

                // Action Buttons: Explore 3D & Book Room
                Row(
                  children: [
                    if (room.has3dModel) ...[
                      Expanded(
                        child: OutlinedButton.icon(
                          icon: const Icon(Icons.view_in_ar, size: 16),
                          label: const Text('Explore 3D'),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          onPressed: () {
                            context.push('/room/${room.roomId}');
                          },
                        ),
                      ),
                      const SizedBox(width: 10),
                    ],
                    Expanded(
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.calendar_today, size: 16),
                        label: const Text('Book Room'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        onPressed: onBook,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
