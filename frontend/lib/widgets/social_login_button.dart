import 'package:flutter/material.dart';

import '../config/theme.dart';

enum SocialLoginType { google, apple }

class SocialLoginButton extends StatefulWidget {
  final SocialLoginType type;
  final VoidCallback onPressed;
  final double height;

  const SocialLoginButton({
    super.key,
    required this.type,
    required this.onPressed,
    this.height = 74.0,
  });

  @override
  State<SocialLoginButton> createState() => _SocialLoginButtonState();
}

class _SocialLoginButtonState extends State<SocialLoginButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final isGoogle = widget.type == SocialLoginType.google;
    final label = isGoogle ? 'Google' : 'Apple';

    return Expanded(
      child: MouseRegion(
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: widget.onPressed,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            height: widget.height,
            decoration: BoxDecoration(
              color: _isHovered
                  ? const Color(0xFF181F2C)
                  : const Color(0xFF0F1420).withValues(alpha: 0.85),
              borderRadius: BorderRadius.circular(17),
              border: Border.all(
                color: _isHovered
                    ? AppTheme.cyanAccent.withValues(alpha: 0.6)
                    : const Color(0xFF263242).withValues(alpha: 0.8),
                width: 1.0,
              ),
              boxShadow: _isHovered
                  ? [
                      BoxShadow(
                        color: AppTheme.cyanAccent.withValues(alpha: 0.15),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ]
                  : [],
            ),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (isGoogle)
                    _buildGoogleIcon()
                  else
                    const Icon(Icons.apple, color: Colors.white, size: 31),
                  const SizedBox(width: 14),
                  Text(
                    label,
                    style: const TextStyle(
                      color: AppTheme.textPrimaryWhite,
                      fontSize: 21,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.3,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGoogleIcon() {
    return SizedBox(
      width: 31,
      height: 31,
      child: CustomPaint(painter: _GoogleLogoPainter()),
    );
  }
}

class _GoogleLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final center = Offset(w / 2, h / 2);
    final radius = w / 2;

    final paintBlue = Paint()
      ..color = const Color(0xFF4285F4)
      ..style = PaintingStyle.fill;
    final paintGreen = Paint()
      ..color = const Color(0xFF34A853)
      ..style = PaintingStyle.fill;
    final paintYellow = Paint()
      ..color = const Color(0xFFFBBC05)
      ..style = PaintingStyle.fill;
    final paintRed = Paint()
      ..color = const Color(0xFFEA4335)
      ..style = PaintingStyle.fill;

    // Draw the 4-color Google G mark cleanly
    final rect = Rect.fromCircle(center: center, radius: radius);

    // Blue section (Right bar and top-right)
    canvas.drawArc(rect, -0.6, 1.2, true, paintBlue);
    // Green section (Bottom)
    canvas.drawArc(rect, 0.6, 1.5, true, paintGreen);
    // Yellow section (Left)
    canvas.drawArc(rect, 2.1, 1.5, true, paintYellow);
    // Red section (Top)
    canvas.drawArc(rect, 3.6, 1.3, true, paintRed);

    // Inner cutout to make it a ring
    final innerPaint = Paint()
      ..color = const Color(0xFF0F1420)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, radius * 0.58, innerPaint);

    // Center horizontal bar for 'G'
    final barRect = Rect.fromLTRB(
      center.dx - 1,
      center.dy - radius * 0.22,
      center.dx + radius * 0.95,
      center.dy + radius * 0.22,
    );
    canvas.drawRect(barRect, paintBlue);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
