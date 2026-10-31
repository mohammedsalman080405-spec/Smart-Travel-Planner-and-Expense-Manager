import 'package:flutter/material.dart';
import '../../config/theme.dart';
import '../../widgets/login_form.dart';
import '../../widgets/travel_hero_section.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black, // Pure black base surface
      body: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          final height = constraints.maxHeight;

          return Stack(
            fit: StackFit.expand,
            children: [
              // 1. Pristine Fullscreen 16:9 Luxury Seaside Resort Photograph
              Positioned.fill(
                child: Image.asset(
                  'assets/images/resort_bg_clean.jpg',
                  fit: BoxFit.cover,
                  alignment: Alignment.centerLeft,
                  errorBuilder: (context, error, stackTrace) => Container(color: Colors.black),
                ),
              ),

              // 2. Subtle Black Gradient Overlay:
              // Preserves full visual clarity of the luxury villa, pool, and evening ocean on the left,
              // while fading smoothly into deep starry black behind the login card on the right
              Positioned.fill(
                child: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                      colors: [
                        Colors.transparent,
                        Colors.transparent,
                        Color(0x59000000), // 35% black
                        Color(0xD9000000), // 85% black
                        Color(0xFA000000), // 98% black
                      ],
                      stops: [0.0, 0.45, 0.65, 0.85, 1.0],
                    ),
                  ),
                ),
              ),

              // 3. Subtle ambient cyan glow halo positioned directly behind the login card
              if (width >= 960)
                Positioned(
                  top: (height - 380) / 2 + 14,
                  left: width * 0.57 + ((width * 0.43) - 380) / 2,
                  child: Container(
                    width: 380,
                    height: 380,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          AppTheme.cyanAccent.withValues(alpha: 0.16),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),

              // 4. Foreground Sections (Desktop Split or Responsive Mobile/Tablet)
              Positioned.fill(
                child: width >= 960
                    ? _buildDesktopLayout(context, width, height)
                    : width >= 650
                        ? _buildTabletLayout(context, width, height)
                        : _buildMobileLayout(context, width, height),
              ),
            ],
          );
        },
      ),
    );
  }

  // Exact 57:43 Desktop Split Layout matching reference image (center_x = 803 at 1024 width)
  Widget _buildDesktopLayout(BuildContext context, double width, double height) {
    return Row(
      children: [
        // LEFT SECTION — BRANDING & LUXURY HERO (57% Width)
        Expanded(
          flex: 57,
          child: TravelHeroSection(
            showBranding: true,
            screenWidth: width,
            screenHeight: height,
          ),
        ),

        // RIGHT SECTION — CENTERED LOGIN CARD (43% Width)
        Expanded(
          flex: 43,
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.only(left: 16, right: 16, top: 26, bottom: 12),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 330),
                child: const LoginFormCard(),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // Tablet Proportional Layout (650 <= Width < 960)
  Widget _buildTabletLayout(BuildContext context, double width, double height) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: const [
            LoginFormCard(),
          ],
        ),
      ),
    );
  }

  // Mobile Vertical Stack Layout (Width < 650)
  Widget _buildMobileLayout(BuildContext context, double width, double height) {
    return SafeArea(
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 380),
            child: const LoginFormCard(),
          ),
        ),
      ),
    );
  }
}
