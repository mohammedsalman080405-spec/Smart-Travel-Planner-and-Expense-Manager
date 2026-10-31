import 'package:flutter/material.dart';

import '../../config/theme.dart';
import '../../widgets/login_form.dart';
import '../../widgets/travel_hero_section.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black, // Pure black background (#000000)
      body: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          final height = constraints.maxHeight;

          if (width >= 960) {
            return _buildDesktopLayout(context, width, height);
          } else if (width >= 650) {
            return _buildTabletLayout(context, width, height);
          } else {
            return _buildMobileLayout(context, width, height);
          }
        },
      ),
    );
  }

  // Reference composition: the resort image owns the wider left column.
  Widget _buildDesktopLayout(
    BuildContext context,
    double width,
    double height,
  ) {
    return Row(
      children: [
        // ==========================================
        // LEFT SECTION — TRAVEL HERO (55% Width)
        // ==========================================
        Expanded(
          flex: 58,
          child: Stack(
            fit: StackFit.expand,
            children: [
              // 1. Luxury Hotel & Infinity Pool Background Image (Covers entire left section from top to bottom)
              Positioned.fill(
                child: Image.asset(
                  'assets/images/resort_bg_clean.jpg',
                  fit: BoxFit.cover,
                  alignment: Alignment.centerLeft,
                  errorBuilder: (context, error, stackTrace) =>
                      Container(color: Colors.black),
                ),
              ),

              // 2. Subtle Black Gradient Overlay for Text Readability and seamless edge blend
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                      colors: [
                        Colors.black.withValues(alpha: 0.08),
                        Colors.black.withValues(alpha: 0.04),
                        Colors.black.withValues(alpha: 0.28),
                        Colors.black.withValues(alpha: 0.84),
                        Colors.black,
                      ],
                      stops: const [0.0, 0.43, 0.72, 0.94, 1.0],
                    ),
                  ),
                ),
              ),

              // 3. Foreground Content: SMART TRAVEL Logo, "Explore the World", Tagline & Description
              TravelHeroSection(
                showBranding: true,
                screenWidth: width,
                screenHeight: height,
              ),
            ],
          ),
        ),

        // ==========================================
        // RIGHT SECTION — CENTERED LOGIN CARD (45% Width)
        // ==========================================
        Expanded(
          flex: 42,
          child: Container(
            color: Colors.black, // Pure black background (#000000)
            child: Center(
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Subtle ambient cyan glow halo directly behind the login card
                  Container(
                    width: 560,
                    height: 780,
                    decoration: BoxDecoration(
                      shape: BoxShape.rectangle,
                      borderRadius: BorderRadius.circular(24),
                      gradient: RadialGradient(
                        radius: 0.8,
                        colors: [
                          AppTheme.cyanAccent.withValues(alpha: 0.18),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),

                  // Login Form Card centered vertically & horizontally
                  SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 20,
                    ),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 530),
                      child: const LoginFormCard(),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  // Tablet Proportional Layout (650 <= Width < 960)
  Widget _buildTabletLayout(BuildContext context, double width, double height) {
    return Stack(
      fit: StackFit.expand,
      children: [
        Positioned.fill(
          child: Image.asset(
            'assets/images/resort_bg_clean.jpg',
            fit: BoxFit.cover,
            alignment: Alignment.centerLeft,
            errorBuilder: (context, error, stackTrace) =>
                Container(color: Colors.black),
          ),
        ),
        Positioned.fill(
          child: Container(color: Colors.black.withValues(alpha: 0.78)),
        ),
        SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 540),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      height: 320,
                      child: TravelHeroSection(
                        screenWidth: width,
                        screenHeight: 320,
                      ),
                    ),
                    const LoginFormCard(),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // Mobile keeps the hero and form in one scrollable, accessible stack.
  Widget _buildMobileLayout(BuildContext context, double width, double height) {
    return Stack(
      fit: StackFit.expand,
      children: [
        Positioned.fill(
          child: Image.asset(
            'assets/images/resort_bg_clean.jpg',
            fit: BoxFit.cover,
            alignment: Alignment.centerLeft,
            errorBuilder: (context, error, stackTrace) =>
                Container(color: Colors.black),
          ),
        ),
        Positioned.fill(
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withValues(alpha: 0.78),
                  Colors.black.withValues(alpha: 0.90),
                  Colors.black,
                ],
              ),
            ),
          ),
        ),
        SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 430),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      height: 330,
                      child: TravelHeroSection(
                        screenWidth: width,
                        screenHeight: 330,
                      ),
                    ),
                    const LoginFormCard(),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
