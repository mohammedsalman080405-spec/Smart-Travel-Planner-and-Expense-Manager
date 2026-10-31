import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../config/theme.dart';

class TravelHeroSection extends StatelessWidget {
  final bool showBranding;
  final bool renderBackground;

  const TravelHeroSection({
    super.key,
    this.showBranding = true,
    this.renderBackground = true,
  });

  @override
  Widget build(BuildContext context) {
    final content = SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 36),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 3a. Top-Left Branding
            if (showBranding)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF00D9FF), Color(0xFF0088FF)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.cyanAccent.withValues(alpha: 0.45),
                          blurRadius: 14,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Transform.rotate(
                        angle: -math.pi / 4,
                        child: const Icon(
                          Icons.flight,
                          color: Colors.white,
                          size: 26,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'SMART TRAVEL',
                        style: TextStyle(
                          color: AppTheme.textPrimaryWhite,
                          fontWeight: FontWeight.w900,
                          fontSize: 17,
                          letterSpacing: 1.2,
                          height: 1.1,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        '3D Luxury Travel Planner',
                        style: TextStyle(
                          color: AppTheme.cyanAccent.withValues(alpha: 0.95),
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.4,
                          height: 1.1,
                        ),
                      ),
                    ],
                  ),
                ],
              ),

            const Spacer(flex: 3),

            // 3b. Hero Headline: "Explore the World"
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Explore',
                  style: TextStyle(
                    color: AppTheme.textPrimaryWhite,
                    fontSize: 58,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -1.0,
                    height: 1.05,
                  ),
                ),
                Text(
                  'the World',
                  style: TextStyle(
                    color: AppTheme.cyanAccent,
                    fontSize: 58,
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
              ],
            ),

            const SizedBox(height: 18),

            // 3c. Sub-headline: Plan Smarter • Travel Better • Spend Wisely
            Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 8,
              runSpacing: 4,
              children: [
                const Text(
                  'Plan Smarter',
                  style: TextStyle(
                    color: AppTheme.textPrimaryWhite,
                    fontSize: 15.5,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.2,
                  ),
                ),
                Text(
                  '•',
                  style: TextStyle(
                    color: AppTheme.cyanAccent,
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const Text(
                  'Travel Better',
                  style: TextStyle(
                    color: AppTheme.textPrimaryWhite,
                    fontSize: 15.5,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.2,
                  ),
                ),
                Text(
                  '•',
                  style: TextStyle(
                    color: AppTheme.cyanAccent,
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Text(
                  'Spend Wisely',
                  style: TextStyle(
                    color: AppTheme.cyanAccent,
                    fontSize: 15.5,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.2,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // 3d. Description
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 460),
              child: Text(
                'Discover amazing destinations, explore top hotels, create your itinerary and manage your travel expenses all in one place.',
                style: TextStyle(
                  color: AppTheme.textSecondaryGrey.withValues(alpha: 0.95),
                  fontSize: 14.5,
                  height: 1.6,
                  fontWeight: FontWeight.w400,
                  letterSpacing: 0.15,
                ),
              ),
            ),

            const Spacer(flex: 4),
          ],
        ),
      ),
    );

    if (!renderBackground) {
      return content;
    }

    return Stack(
      fit: StackFit.expand,
      children: [
        // 1. Luxury Seaside Resort Background Image
        Image.asset(
          'assets/images/resort_bg_clean.jpg',
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return Image.network(
              'https://images.unsplash.com/photo-1582719478250-c89cae4dc85b?auto=format&fit=crop&w=1920&q=85',
              fit: BoxFit.cover,
            );
          },
        ),

        // 2. Black Gradient Overlays for Maximum Contrast & Readability
        Container(
          color: Colors.black.withValues(alpha: 0.28),
        ),

        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [
                Colors.black.withValues(alpha: 0.50),
                Colors.black.withValues(alpha: 0.30),
                Colors.black.withValues(alpha: 0.70),
                const Color(0xFF000000),
              ],
              stops: const [0.0, 0.45, 0.85, 1.0],
            ),
          ),
        ),

        content,
      ],
    );
  }
}
