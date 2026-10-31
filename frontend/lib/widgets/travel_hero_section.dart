import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../config/theme.dart';

class TravelHeroSection extends StatelessWidget {
  final bool showBranding;
  final bool renderBackground;
  final double screenWidth;
  final double screenHeight;

  const TravelHeroSection({
    super.key,
    this.showBranding = true,
    this.renderBackground = false,
    this.screenWidth = 1024,
    this.screenHeight = 595,
  });

  @override
  Widget build(BuildContext context) {
    final desktop = screenWidth >= 960;
    final scale = desktop
        ? math.min(screenHeight / 900, screenWidth / 1600).clamp(0.58, 1.0)
        : (screenWidth >= 650 ? 0.55 : 0.42);
    final left = desktop ? 220 * scale : (screenWidth >= 650 ? 48.0 : 24.0);

    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (showBranding)
            Padding(
              padding: EdgeInsets.only(left: 48 * scale, top: 26 * scale),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 60 * scale,
                    height: 60 * scale,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF00D9FF), Color(0xFF0080FF)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16 * scale),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.cyanAccent.withValues(alpha: .4),
                          blurRadius: 18,
                        ),
                      ],
                    ),
                    child: Center(
                      child: Transform.rotate(
                        angle: -math.pi / 4,
                        child: Icon(
                          Icons.flight,
                          color: Colors.white,
                          size: 30 * scale,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 20 * scale),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'SMART TRAVEL',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          fontSize: 25 * scale,
                          letterSpacing: .1,
                          height: 1.05,
                        ),
                      ),
                      SizedBox(height: 5 * scale),
                      Text(
                        '3D Luxury Travel Planner',
                        style: TextStyle(
                          color: AppTheme.cyanAccent,
                          fontSize: 16 * scale,
                          fontWeight: FontWeight.w600,
                          height: 1.05,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          const Spacer(flex: 1),
          Padding(
            padding: EdgeInsets.only(left: left, right: 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Explore',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 96 * scale,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -3.5 * scale,
                    height: .98,
                  ),
                ),
                Text(
                  'the World',
                  style: TextStyle(
                    color: AppTheme.cyanAccent,
                    fontSize: 96 * scale,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -3.5 * scale,
                    height: .98,
                    shadows: [
                      Shadow(
                        color: AppTheme.cyanAccent.withValues(alpha: .32),
                        blurRadius: 22,
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 18 * scale),
                Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 14 * scale,
                  runSpacing: 4,
                  children: [
                    _tag('Plan Smarter', Colors.white, scale),
                    _tag('•', AppTheme.cyanAccent, scale),
                    _tag('Travel Better', Colors.white, scale),
                    _tag('•', AppTheme.cyanAccent, scale),
                    _tag('Spend Wisely', AppTheme.cyanAccent, scale),
                  ],
                ),
                SizedBox(height: 18 * scale),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 690),
                  child: Text(
                    'Discover amazing destinations, explore top hotels, create your itinerary and manage your travel expenses all in one place.',
                    style: TextStyle(
                      color: const Color(0xFFAAB5C5),
                      fontSize: 27 * scale,
                      height: 1.35,
                      fontWeight: FontWeight.w400,
                      letterSpacing: -.25,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Spacer(flex: 3),
        ],
      ),
    );
  }

  Widget _tag(String value, Color color, double scale) => Text(
    value,
    style: TextStyle(
      color: color,
      fontSize: 27 * scale,
      fontWeight: FontWeight.w700,
      letterSpacing: -.5,
    ),
  );
}
