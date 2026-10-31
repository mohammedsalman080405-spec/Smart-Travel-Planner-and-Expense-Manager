import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../config/theme.dart';
import '../../models/room.dart';
import '../../services/hotel_service.dart';
import '../../widgets/error_widget.dart';
import '../../widgets/loading_widget.dart';
import '../../widgets/model_viewer_widget.dart';

class Room3dScreen extends StatefulWidget {
  final int roomId;

  const Room3dScreen({super.key, required this.roomId});

  @override
  State<Room3dScreen> createState() => _Room3dScreenState();
}

class _Room3dScreenState extends State<Room3dScreen> {
  late Future<Room> _roomFuture;

  @override
  void initState() {
    super.initState();
    _roomFuture = HotelService.getRoomDetails(widget.roomId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.darkNavy,
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A1224),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => context.pop(),
        ),
        title: const Text(
          'INTERACTIVE 3D ROOM INSPECTION',
          style: TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
          ),
        ),
      ),
      body: FutureBuilder<Room>(
        future: _roomFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const LoadingWidget(message: 'Initializing 3D environment & shaders...');
          }
          if (snapshot.hasError) {
            return CustomErrorWidget(
              message: 'Failed to load room 3D model: ${snapshot.error}',
              onRetry: () {
                setState(() {
                  _roomFuture = HotelService.getRoomDetails(widget.roomId);
                });
              },
            );
          }

          final room = snapshot.data!;

          return SingleChildScrollView(
            child: Center(
              child: Container(
                constraints: const BoxConstraints(maxWidth: 1100),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 1. Interactive 3D Model Viewer
                    ModelViewerWidget(
                      modelUrl: room.modelUrl,
                      title: room.roomName,
                      fallbackImageUrl: room.imageUrl,
                      height: 520,
                    ),

                    const SizedBox(height: 28),

                    // 2. Room Overview & Specifications
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: AppTheme.accentCyan.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  room.roomType.toUpperCase(),
                                  style: const TextStyle(
                                    color: AppTheme.accentCyan,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                room.roomName,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 12),
                              // Specs
                              Row(
                                children: [
                                  const Icon(Icons.king_bed_outlined, color: AppTheme.accentCyan, size: 18),
                                  const SizedBox(width: 6),
                                  Text(room.bedType, style: const TextStyle(color: Colors.white70, fontSize: 14)),
                                  const SizedBox(width: 20),
                                  const Icon(Icons.square_foot, color: AppTheme.accentCyan, size: 18),
                                  const SizedBox(width: 6),
                                  Text(room.roomSize, style: const TextStyle(color: Colors.white70, fontSize: 14)),
                                  const SizedBox(width: 20),
                                  const Icon(Icons.person_outline, color: AppTheme.accentCyan, size: 18),
                                  const SizedBox(width: 6),
                                  Text('Up to ${room.maximumOccupancy} guests', style: const TextStyle(color: Colors.white70, fontSize: 14)),
                                ],
                              ),
                            ],
                          ),
                        ),

                        // Booking Card
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: AppTheme.cardNavy,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: AppTheme.borderNavy),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              RichText(
                                text: TextSpan(
                                  children: [
                                    TextSpan(
                                      text: '\$${room.pricePerNight.toStringAsFixed(0)}',
                                      style: const TextStyle(
                                        color: AppTheme.accentCyan,
                                        fontSize: 28,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const TextSpan(
                                      text: ' / night',
                                      style: TextStyle(color: AppTheme.textMuted, fontSize: 13),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 14),
                              ElevatedButton.icon(
                                icon: const Icon(Icons.calendar_today, size: 16),
                                label: const Text('Book This Room'),
                                style: ElevatedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                                ),
                                onPressed: () {
                                  context.push('/book?hotel_id=${room.hotelId}&room_id=${room.roomId}');
                                },
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    // Description
                    if (room.description != null)
                      Text(
                        room.description!,
                        style: const TextStyle(color: Colors.white70, fontSize: 15, height: 1.6),
                      ),

                    const SizedBox(height: 24),

                    // Amenities
                    const Text(
                      'ROOM AMENITIES & INCLUSIONS',
                      style: TextStyle(
                        color: AppTheme.accentCyan,
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: room.amenities.map((a) {
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: AppTheme.cardNavy,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: AppTheme.borderNavy),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.check_circle_outline, color: AppTheme.accentEmerald, size: 16),
                              const SizedBox(width: 8),
                              Text(a, style: const TextStyle(color: Colors.white, fontSize: 13)),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
