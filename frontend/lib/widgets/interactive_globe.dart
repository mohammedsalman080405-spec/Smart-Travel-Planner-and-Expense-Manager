import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/theme.dart';
import '../models/hotel.dart';
import '../providers/globe_provider.dart';
import '../providers/hotel_provider.dart';

class InteractiveGlobe extends StatefulWidget {
  final List<Hotel> hotels;
  final Hotel? selectedHotel;
  final Function(Hotel hotel)? onHotelSelected;

  const InteractiveGlobe({
    super.key,
    required this.hotels,
    this.selectedHotel,
    this.onHotelSelected,
  });

  @override
  State<InteractiveGlobe> createState() => _InteractiveGlobeState();
}

class _InteractiveGlobeState extends State<InteractiveGlobe> with SingleTickerProviderStateMixin {
  late AnimationController _animController;

  // Globe rotation angles in radians
  double _rotationY = 1.37; // Longitude angle
  double _rotationX = 0.30; // Latitude tilt angle

  Offset? _lastPanPos;
  DateTime _lastInteraction = DateTime.now();

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 30),
    )..addListener(_tick);
    _animController.repeat();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  void _tick() {
    final globeProvider = context.read<GlobeProvider>();

    // Smooth animation towards target coordinates if animating
    if (globeProvider.isAnimatingToTarget) {
      // Convert target lat/lng to rotation angles
      final targetRotY = -globeProvider.targetLongitude * (math.pi / 180.0) + (math.pi / 2);
      final targetRotX = globeProvider.targetLatitude * (math.pi / 180.0);

      final diffY = (targetRotY - _rotationY);
      final diffX = (targetRotX - _rotationX);

      if (diffY.abs() > 0.01 || diffX.abs() > 0.01) {
        setState(() {
          _rotationY += diffY * 0.08;
          _rotationX += diffX * 0.08;
        });
      } else {
        globeProvider.stopAnimation();
      }
      return;
    }

    // Auto-rotate when idle (after 3 seconds of no user interaction)
    if (globeProvider.isAutoRotating && DateTime.now().difference(_lastInteraction).inSeconds > 2) {
      setState(() {
        _rotationY += 0.003;
      });
    }
  }

  void _onPanStart(DragStartDetails details) {
    _lastPanPos = details.localPosition;
    _lastInteraction = DateTime.now();
    context.read<GlobeProvider>().toggleAutoRotate(false);
  }

  void _onPanUpdate(DragUpdateDetails details) {
    if (_lastPanPos == null) return;
    final delta = details.localPosition - _lastPanPos!;
    _lastPanPos = details.localPosition;
    _lastInteraction = DateTime.now();

    setState(() {
      _rotationY += delta.dx * 0.008;
      _rotationX = (_rotationX - delta.dy * 0.008).clamp(-1.2, 1.2);
    });
  }

  void _onPanEnd(DragEndDetails details) {
    _lastPanPos = null;
    _lastInteraction = DateTime.now();
  }

  @override
  Widget build(BuildContext context) {
    final globeProvider = context.watch<GlobeProvider>();
    final hotelProvider = context.watch<HotelProvider>();

    return LayoutBuilder(
      builder: (context, constraints) {
        final size = math.min(constraints.maxWidth, constraints.maxHeight);
        final radius = (size / 2.3) * globeProvider.zoomLevel;

        return Stack(
          alignment: Alignment.center,
          children: [
            // Deep space starfield background
            CustomPaint(
              size: Size(constraints.maxWidth, constraints.maxHeight),
              painter: StarfieldPainter(),
            ),

            // Atmosphere radial glow
            Container(
              width: radius * 2.3,
              height: radius * 2.3,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFF00D2FF).withOpacity(0.18),
                    const Color(0xFF1E3A8A).withOpacity(0.08),
                    Colors.transparent,
                  ],
                  stops: const [0.65, 0.85, 1.0],
                ),
              ),
            ),

            // Interactive Globe Sphere + Landmasses + Wireframe + Hotel Markers
            GestureDetector(
              onPanStart: _onPanStart,
              onPanUpdate: _onPanUpdate,
              onPanEnd: _onPanEnd,
              child: SizedBox(
                width: constraints.maxWidth,
                height: constraints.maxHeight,
                child: CustomPaint(
                  painter: GlobeSpherePainter(
                    radius: radius,
                    rotationX: _rotationX,
                    rotationY: _rotationY,
                    hotels: widget.hotels,
                    selectedHotel: widget.selectedHotel,
                  ),
                ),
              ),
            ),

            // Interactive overlay pins for clickable hotel interaction
            ...widget.hotels.map((hotel) {
              final screenPos = _calculateHotelScreenPos(
                hotel.latitude,
                hotel.longitude,
                constraints.biggest.center(Offset.zero),
                radius,
              );

              if (screenPos == null) return const SizedBox.shrink();

              final isSelected = widget.selectedHotel?.hotelId == hotel.hotelId;

              return Positioned(
                left: screenPos.dx - (isSelected ? 24 : 18),
                top: screenPos.dy - (isSelected ? 48 : 36),
                child: MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: GestureDetector(
                    onTap: () {
                      context.read<HotelProvider>().selectHotel(hotel);
                      if (widget.onHotelSelected != null) {
                        widget.onHotelSelected!(hotel);
                      }
                    },
                    child: Tooltip(
                      message: '${hotel.hotelName}\n\$${hotel.startingPrice.toStringAsFixed(0)}/night • ★ ${hotel.starRating}',
                      textStyle: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
                      decoration: BoxDecoration(
                        color: AppTheme.cardNavy.withOpacity(0.95),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppTheme.accentCyan, width: 1.2),
                      ),
                      child: AnimatedScale(
                        duration: const Duration(milliseconds: 250),
                        scale: isSelected ? 1.35 : 1.0,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Pin head badge
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: isSelected
                                      ? [const Color(0xFFFBBF24), const Color(0xFFF59E0B)]
                                      : [const Color(0xFF00D2FF), const Color(0xFF2563EB)],
                                ),
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                    color: (isSelected ? const Color(0xFFFBBF24) : const Color(0xFF00D2FF)).withOpacity(0.6),
                                    blurRadius: isSelected ? 16 : 8,
                                    spreadRadius: isSelected ? 3 : 1,
                                  )
                                ],
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.hotel,
                                    size: isSelected ? 14 : 12,
                                    color: isSelected ? Colors.black87 : Colors.white,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    '\$${hotel.startingPrice.toStringAsFixed(0)}',
                                    style: TextStyle(
                                      color: isSelected ? Colors.black87 : Colors.white,
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            // Pin needle
                            Container(
                              width: 2,
                              height: 8,
                              color: isSelected ? const Color(0xFFFBBF24) : const Color(0xFF00D2FF),
                            ),
                            // Glowing target point
                            Container(
                              width: 6,
                              height: 6,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: isSelected ? const Color(0xFFFBBF24) : const Color(0xFF00D2FF),
                                boxShadow: [
                                  BoxShadow(
                                    color: (isSelected ? const Color(0xFFFBBF24) : const Color(0xFF00D2FF)).withOpacity(0.8),
                                    blurRadius: 6,
                                  )
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }),

            // Floating Globe Controls (Zoom in, Zoom out, Auto-rotate, Reset)
            Positioned(
              left: 24,
              bottom: 24,
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppTheme.cardNavy.withOpacity(0.85),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppTheme.borderNavy),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 12),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.add, color: Colors.white, size: 20),
                      tooltip: 'Zoom In',
                      onPressed: () => globeProvider.setZoom(globeProvider.zoomLevel + 0.2),
                    ),
                    IconButton(
                      icon: const Icon(Icons.remove, color: Colors.white, size: 20),
                      tooltip: 'Zoom Out',
                      onPressed: () => globeProvider.setZoom(globeProvider.zoomLevel - 0.2),
                    ),
                    IconButton(
                      icon: Icon(
                        globeProvider.isAutoRotating ? Icons.pause : Icons.play_arrow,
                        color: globeProvider.isAutoRotating ? AppTheme.accentCyan : Colors.white70,
                        size: 20,
                      ),
                      tooltip: globeProvider.isAutoRotating ? 'Pause Rotation' : 'Auto Rotate',
                      onPressed: () => globeProvider.toggleAutoRotate(!globeProvider.isAutoRotating),
                    ),
                    IconButton(
                      icon: const Icon(Icons.refresh, color: Colors.white70, size: 20),
                      tooltip: 'Reset View',
                      onPressed: () {
                        setState(() {
                          _rotationX = 0.30;
                          _rotationY = 1.37;
                        });
                        globeProvider.resetView();
                      },
                    ),
                  ],
                ),
              ),
            ),

            // Search Radius selector badge if hotels are found
            if (widget.hotels.isNotEmpty)
              Positioned(
                top: 24,
                left: 24,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: AppTheme.cardNavy.withOpacity(0.9),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppTheme.borderNavy),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 10),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.radar, color: AppTheme.accentCyan, size: 18),
                      const SizedBox(width: 8),
                      Text(
                        '${widget.hotels.length} Luxury Properties Found',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13),
                      ),
                      const SizedBox(width: 14),
                      DropdownButtonHideUnderline(
                        child: DropdownButton<double>(
                          value: hotelProvider.searchRadiusKm,
                          dropdownColor: AppTheme.cardNavy,
                          style: const TextStyle(color: AppTheme.accentCyan, fontWeight: FontWeight.bold, fontSize: 12),
                          items: const [
                            DropdownMenuItem(value: 5.0, child: Text('5 km radius')),
                            DropdownMenuItem(value: 10.0, child: Text('10 km radius')),
                            DropdownMenuItem(value: 20.0, child: Text('20 km radius')),
                            DropdownMenuItem(value: 30.0, child: Text('30 km radius')),
                            DropdownMenuItem(value: 50.0, child: Text('50 km radius')),
                          ],
                          onChanged: (val) {
                            if (val != null) {
                              hotelProvider.setRadius(val);
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  Offset? _calculateHotelScreenPos(double lat, double lng, Offset center, double radius) {
    final phi = (90 - lat) * (math.pi / 180.0);
    final theta = (lng + 180) * (math.pi / 180.0) + _rotationY;

    // 3D Spherical coordinates
    final x = -(radius * math.sin(phi) * math.cos(theta));
    final z = radius * math.sin(phi) * math.sin(theta);
    final y = -radius * math.cos(phi);

    // Rotate along X-axis (tilt)
    final cosX = math.cos(_rotationX);
    final sinX = math.sin(_rotationX);

    final yRot = y * cosX - z * sinX;
    final zRot = y * sinX + z * cosX;

    // Only render markers visible on the front hemisphere (zRot > 0)
    if (zRot <= 0.1) return null;

    return Offset(center.dx + x, center.dy + yRot);
  }
}

// Custom Painter for 3D Earth Globe with Continents, Lat/Long grid, and Atmosphere
class GlobeSpherePainter extends CustomPainter {
  final double radius;
  final double rotationX;
  final double rotationY;
  final List<Hotel> hotels;
  final Hotel? selectedHotel;

  GlobeSpherePainter({
    required this.radius,
    required this.rotationX,
    required this.rotationY,
    required this.hotels,
    this.selectedHotel,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);

    // 1. Draw Deep Blue Ocean Sphere
    final oceanPaint = Paint()
      ..shader = RadialGradient(
        colors: const [
          Color(0xFF142B58),
          Color(0xFF0F1E3D),
          Color(0xFF070E20),
        ],
        stops: const [0.2, 0.8, 1.0],
      ).createShader(Rect.fromCircle(center: center, radius: radius));

    canvas.drawCircle(center, radius, oceanPaint);

    // 2. Draw Latitude and Longitude Geodesic Grid (Wireframe look as requested)
    final gridPaint = Paint()
      ..color = const Color(0xFF00D2FF).withOpacity(0.16)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    // Draw Parallels (Latitudes)
    for (int lat = -70; lat <= 70; lat += 20) {
      final path = Path();
      bool first = true;
      final phi = (90 - lat) * (math.pi / 180.0);
      final rLat = radius * math.sin(phi);
      final yBase = -radius * math.cos(phi);

      for (int lon = 0; lon <= 360; lon += 5) {
        final theta = lon * (math.pi / 180.0) + rotationY;
        final x = -(rLat * math.cos(theta));
        final z = rLat * math.sin(theta);

        final yRot = yBase * math.cos(rotationX) - z * math.sin(rotationX);
        final zRot = yBase * math.sin(rotationX) + z * math.cos(rotationX);

        if (zRot > 0) {
          final pt = Offset(center.dx + x, center.dy + yRot);
          if (first) {
            path.moveTo(pt.dx, pt.dy);
            first = false;
          } else {
            path.lineTo(pt.dx, pt.dy);
          }
        } else {
          first = true;
        }
      }
      canvas.drawPath(path, gridPaint);
    }

    // Draw Meridians (Longitudes)
    for (int lon = 0; lon < 360; lon += 30) {
      final path = Path();
      bool first = true;
      final theta = lon * (math.pi / 180.0) + rotationY;

      for (int lat = -80; lat <= 80; lat += 4) {
        final phi = (90 - lat) * (math.pi / 180.0);
        final x = -(radius * math.sin(phi) * math.cos(theta));
        final z = radius * math.sin(phi) * math.sin(theta);
        final y = -radius * math.cos(phi);

        final yRot = y * math.cos(rotationX) - z * math.sin(rotationX);
        final zRot = y * math.sin(rotationX) + z * math.cos(rotationX);

        if (zRot > 0) {
          final pt = Offset(center.dx + x, center.dy + yRot);
          if (first) {
            path.moveTo(pt.dx, pt.dy);
            first = false;
          } else {
            path.lineTo(pt.dx, pt.dy);
          }
        } else {
          first = true;
        }
      }
      canvas.drawPath(path, gridPaint);
    }

    // 3. Draw Stylized Landmass Polygons & Major Geographies
    final landPaint = Paint()
      ..color = const Color(0xFF1E4078).withOpacity(0.55)
      ..style = PaintingStyle.fill;

    final landBorderPaint = Paint()
      ..color = const Color(0xFF38BDF8).withOpacity(0.4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    _drawContinents(canvas, center, landPaint, landBorderPaint);

    // 4. Outer Sphere Rim Highlight
    final rimPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          Colors.transparent,
          const Color(0xFF00D2FF).withOpacity(0.35),
        ],
        stops: const [0.92, 1.0],
      ).createShader(Rect.fromCircle(center: center, radius: radius));

    canvas.drawCircle(center, radius, rimPaint);
  }

  void _drawContinents(Canvas canvas, Offset center, Paint fill, Paint stroke) {
    // Key landmark polygon clusters (India/Asia, Europe, Americas, Australia, Africa)
    final continents = [
      // India & South Asia
      [
        [28.0, 70.0], [32.0, 75.0], [28.0, 85.0], [22.0, 89.0], [16.0, 82.0],
        [8.0, 77.0], [15.0, 73.0], [24.0, 68.0]
      ],
      // East Asia & Japan
      [
        [40.0, 116.0], [45.0, 130.0], [35.0, 140.0], [31.0, 121.0], [22.0, 114.0], [30.0, 105.0]
      ],
      // Southeast Asia & Indonesia
      [
        [15.0, 100.0], [10.0, 105.0], [1.0, 104.0], [-6.0, 107.0], [-8.0, 115.0],
        [-8.0, 120.0], [5.0, 115.0]
      ],
      // Europe
      [
        [60.0, 10.0], [55.0, 25.0], [45.0, 30.0], [36.0, 25.0], [36.0, -5.0],
        [48.0, -4.0], [52.0, 5.0]
      ],
      // Middle East & UAE
      [
        [32.0, 35.0], [30.0, 48.0], [25.0, 55.0], [22.0, 59.0], [15.0, 50.0],
        [20.0, 40.0], [28.0, 34.0]
      ],
      // North America
      [
        [60.0, -140.0], [65.0, -100.0], [50.0, -60.0], [30.0, -80.0], [25.0, -90.0],
        [20.0, -105.0], [35.0, -120.0], [50.0, -130.0]
      ],
      // Australia
      [
        [-15.0, 130.0], [-20.0, 145.0], [-35.0, 150.0], [-38.0, 140.0],
        [-32.0, 115.0], [-20.0, 115.0]
      ],
      // Africa
      [
        [35.0, -5.0], [30.0, 32.0], [10.0, 45.0], [-5.0, 40.0], [-34.0, 20.0],
        [-20.0, 12.0], [5.0, 0.0], [15.0, -17.0]
      ]
    ];

    for (final poly in continents) {
      final path = Path();
      bool first = true;
      bool hasVisiblePoint = false;

      for (final pt in poly) {
        final lat = pt[0];
        final lon = pt[1];

        final phi = (90 - lat) * (math.pi / 180.0);
        final theta = (lon + 180) * (math.pi / 180.0) + rotationY;

        final x = -(radius * math.sin(phi) * math.cos(theta));
        final z = radius * math.sin(phi) * math.sin(theta);
        final y = -radius * math.cos(phi);

        final yRot = y * math.cos(rotationX) - z * math.sin(rotationX);
        final zRot = y * math.sin(rotationX) + z * math.cos(rotationX);

        if (zRot > -0.2) {
          hasVisiblePoint = true;
          final scrPt = Offset(center.dx + x, center.dy + yRot);
          if (first) {
            path.moveTo(scrPt.dx, scrPt.dy);
            first = false;
          } else {
            path.lineTo(scrPt.dx, scrPt.dy);
          }
        }
      }

      if (hasVisiblePoint) {
        path.close();
        canvas.drawPath(path, fill);
        canvas.drawPath(path, stroke);
      }
    }
  }

  @override
  bool shouldRepaint(covariant GlobeSpherePainter oldDelegate) {
    return oldDelegate.rotationX != rotationX ||
        oldDelegate.rotationY != rotationY ||
        oldDelegate.radius != radius ||
        oldDelegate.hotels != hotels ||
        oldDelegate.selectedHotel != selectedHotel;
  }
}

// Starfield background generator
class StarfieldPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final rand = math.Random(42);
    final starPaint = Paint()..color = Colors.white;

    for (int i = 0; i < 180; i++) {
      final x = rand.nextDouble() * size.width;
      final y = rand.nextDouble() * size.height;
      final opacity = rand.nextDouble() * 0.7 + 0.2;
      final radius = rand.nextDouble() * 1.5 + 0.4;

      starPaint.color = Colors.white.withOpacity(opacity);
      canvas.drawCircle(Offset(x, y), radius, starPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
