import 'package:flutter/material.dart';
import '../../config/theme.dart';
import '../../widgets/login_form.dart';
import '../../widgets/travel_hero_section.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isDesktop = screenSize.width >= 980;

    return Scaffold(
      backgroundColor: Colors.black, // Pure black base
      body: Stack(
        fit: StackFit.expand,
        children: [
          // 1. Pristine Fullscreen 16:9 Resort Background
          Positioned.fill(
            child: Image.asset(
              'assets/images/resort_bg_clean.jpg',
              fit: BoxFit.cover,
              alignment: Alignment.centerLeft,
              errorBuilder: (context, error, stackTrace) => Container(color: Colors.black),
            ),
          ),

          // 2. Black gradient overlay: fades seamlessly into pure black on the right
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: [
                    Colors.black.withValues(alpha: 0.35),
                    Colors.black.withValues(alpha: 0.20),
                    Colors.black.withValues(alpha: 0.70),
                    Colors.black.withValues(alpha: 0.94),
                  ],
                  stops: const [0.0, 0.42, 0.68, 0.90],
                ),
              ),
            ),
          ),

          // 3. Subtle ambient cyan glow highlights behind card
          Positioned(
            top: -60,
            right: 120,
            child: Container(
              width: 450,
              height: 450,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppTheme.cyanAccent.withValues(alpha: 0.12),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          // 4. Foreground Two-Column / Mobile Responsive Content
          Positioned.fill(
            child: isDesktop
                ? _buildDesktopLayout(context)
                : _buildMobileTabletLayout(context),
          ),
        ],
      ),
    );
  }

  // Exact 16:9 two-column split layout matching visual reference
  Widget _buildDesktopLayout(BuildContext context) {
    return Row(
      children: [
        // LEFT SECTION — BRANDING AND TRAVEL VISUAL HERO (56% width)
        const Expanded(
          flex: 14,
          child: TravelHeroSection(showBranding: true, renderBackground: false),
        ),

        // RIGHT SECTION — PURE BLACK SURFACE WITH GLASS LOGIN CARD (44% width)
        const Expanded(
          flex: 11,
          child: Center(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(horizontal: 28, vertical: 32),
              child: LoginFormCard(),
            ),
          ),
        ),
      ],
    );
  }

  // Tablet & Mobile responsive fallback
  Widget _buildMobileTabletLayout(BuildContext context) {
    return SafeArea(
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: const [
              LoginFormCard(),
            ],
          ),
        ),
      ),
    );
  }
}
