import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../config/theme.dart';

class TravelHeroSection extends StatelessWidget {
  final bool showBranding;
  final bool renderBackground;
  final double screenWidth;

  const TravelHeroSection({
    super.key,
    this.showBranding = true,
    this.renderBackground = false,
    this.screenWidth = 1024,
  });

  @override
  Widget build(BuildContext context) {
    // Dynamic left indentation:
    // Pushes headline and copy into the open evening sky above the pool,
    // clear of the left villa architecture, exactly matching the reference image
    final isWideDesktop = screenWidth >= 1200;
    final headlineLeftPadding = isWideDesktop ? 120.0 : (screenWidth >= 960 ? 96.0 : 36.0);

    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Top-Left Branding
          if (showBranding)
            Padding(
              padding: const EdgeInsets.only(left: 36, top: 28),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF00D9FF), Color(0xFF0080FF)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.cyanAccent.withValues(alpha: 0.45),
                          blurRadius: 14,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Transform.rotate(
                        angle: -math.pi / 4,
                        child: const Icon(
                          Icons.flight,
                          color: Colors.white,
                          size: 22,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'SMART TRAVEL',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          fontSize: 16,
                          letterSpacing: 1.1,
                          height: 1.1,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        '3D Luxury Travel Planner',
                        style: TextStyle(
                          color: AppTheme.cyanAccent,
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.3,
                          height: 1.1,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

          const Spacer(flex: 3),

          // 2. Middle-Left Hero Headline & Copy
          Padding(
            padding: EdgeInsets.only(left: headlineLeftPadding, right: 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Explore',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 52,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -1.0,
                    height: 1.05,
                  ),
                ),
                Text(
                  'the World',
                  style: TextStyle(
                    color: AppTheme.cyanAccent,
                    fontSize: 52,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -1.0,
                    height: 1.05,
                    shadows: [
                      Shadow(
                        color: AppTheme.cyanAccent.withValues(alpha: 0.45),
                        blurRadius: 20,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Sub-headline: Plan Smarter • Travel Better • Spend Wisely
                Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 8,
                  runSpacing: 4,
                  children: [
                    const Text(
                      'Plan Smarter',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14.5,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.2,
                      ),
                    ),
                    Text(
                      '•',
                      style: TextStyle(
                        color: AppTheme.cyanAccent,
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const Text(
                      'Travel Better',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14.5,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.2,
                      ),
                    ),
                    Text(
                      '•',
                      style: TextStyle(
                        color: AppTheme.cyanAccent,
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    Text(
                      'Spend Wisely',
                      style: TextStyle(
                        color: AppTheme.cyanAccent,
                        fontSize: 14.5,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // Description
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: Text(
                    'Discover amazing destinations, explore top hotels, create your itinerary and manage your travel expenses all in one place.',
                    style: TextStyle(
                      color: const Color(0xFFB0BDCF),
                      fontSize: 13.5,
                      height: 1.55,
                      fontWeight: FontWeight.w400,
                      letterSpacing: 0.15,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const Spacer(flex: 4),
        ],
      ),
    );
  }
}
