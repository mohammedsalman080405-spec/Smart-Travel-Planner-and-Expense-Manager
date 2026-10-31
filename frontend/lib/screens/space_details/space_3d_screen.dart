import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../config/theme.dart';
import '../../models/hotel_space.dart';
import '../../services/hotel_service.dart';
import '../../widgets/error_widget.dart';
import '../../widgets/loading_widget.dart';
import '../../widgets/model_viewer_widget.dart';

class Space3dScreen extends StatefulWidget {
  final int spaceId;

  const Space3dScreen({super.key, required this.spaceId});

  @override
  State<Space3dScreen> createState() => _Space3dScreenState();
}

class _Space3dScreenState extends State<Space3dScreen> {
  late Future<HotelSpace> _spaceFuture;

  @override
  void initState() {
    super.initState();
    _spaceFuture = HotelService.getSpaceDetails(widget.spaceId);
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
          'INTERACTIVE 3D PROPERTY SPACE',
          style: TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
          ),
        ),
      ),
      body: FutureBuilder<HotelSpace>(
        future: _spaceFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const LoadingWidget(message: 'Loading 3D space architecture...');
          }
          if (snapshot.hasError) {
            return CustomErrorWidget(
              message: 'Failed to load space: ${snapshot.error}',
              onRetry: () {
                setState(() {
                  _spaceFuture = HotelService.getSpaceDetails(widget.spaceId);
                });
              },
            );
          }

          final space = snapshot.data!;

          return SingleChildScrollView(
            child: Center(
              child: Container(
                constraints: const BoxConstraints(maxWidth: 1100),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 1. Interactive 3D Model
                    ModelViewerWidget(
                      modelUrl: space.modelUrl,
                      title: space.spaceName,
                      fallbackImageUrl: space.imageUrl,
                      height: 520,
                    ),

                    const SizedBox(height: 28),

                    // 2. Space Overview
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
                                  space.category.replaceAll('_', ' ').toUpperCase(),
                                  style: const TextStyle(
                                    color: AppTheme.accentCyan,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                space.spaceName,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  const Icon(Icons.groups_outlined, color: AppTheme.accentCyan, size: 18),
                                  const SizedBox(width: 6),
                                  Text('Capacity: ${space.capacity} Guests', style: const TextStyle(color: Colors.white70, fontSize: 14)),
                                  const SizedBox(width: 20),
                                  const Icon(Icons.square_foot, color: AppTheme.accentCyan, size: 18),
                                  const SizedBox(width: 6),
                                  Text(space.size, style: const TextStyle(color: Colors.white70, fontSize: 14)),
                                  const SizedBox(width: 20),
                                  const Icon(Icons.access_time, color: AppTheme.accentCyan, size: 18),
                                  const SizedBox(width: 6),
                                  Text(space.openingHours, style: const TextStyle(color: Colors.white70, fontSize: 14)),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    if (space.description != null)
                      Text(
                        space.description!,
                        style: const TextStyle(color: Colors.white70, fontSize: 15, height: 1.6),
                      ),

                    const SizedBox(height: 24),

                    // Amenities
                    const Text(
                      'FEATURES & EQUIPMENT',
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
                      children: space.amenities.map((a) {
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
