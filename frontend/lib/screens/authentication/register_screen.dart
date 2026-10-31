import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/login_input_field.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isButtonHovered = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<AuthProvider>().clearError();
      }
    });
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    if (_formKey.currentState?.validate() != true) return;

    final authProvider = context.read<AuthProvider>();
    final success = await authProvider.register(
      _nameCtrl.text.trim(),
      _emailCtrl.text.trim(),
      _passCtrl.text.trim(),
      phone: _phoneCtrl.text.trim(),
    );

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: const [
              Icon(Icons.check_circle_outline, color: AppTheme.cyanAccent, size: 20),
              SizedBox(width: 10),
              Text('Account created successfully! Welcome to Smart Travel.'),
            ],
          ),
          backgroundColor: const Color(0xFF0A101D),
          duration: const Duration(seconds: 2),
        ),
      );
      context.go('/');
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Background ambient cyan glow
          Positioned(
            top: -120,
            right: -120,
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
          Positioned(
            bottom: -100,
            left: -100,
            child: Container(
              width: 380,
              height: 380,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppTheme.cyanAccent.withValues(alpha: 0.08),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 36),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                  child: Container(
                    width: 460,
                    padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 36),
                    decoration: BoxDecoration(
                      color: const Color(0xFF080C14).withValues(alpha: 0.88),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: AppTheme.cyanAccent.withValues(alpha: 0.35),
                        width: 1.2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.cyanAccent.withValues(alpha: 0.16),
                          blurRadius: 40,
                          spreadRadius: 2,
                        ),
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.8),
                          blurRadius: 30,
                          offset: const Offset(0, 12),
                        ),
                      ],
                    ),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Top Airplane Icon
                          Container(
                            width: 52,
                            height: 52,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFF00D9FF), Color(0xFF0080FF)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: AppTheme.cyanAccent.withValues(alpha: 0.5),
                                  blurRadius: 18,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Center(
                              child: Transform.rotate(
                                angle: -math.pi / 4,
                                child: const Icon(Icons.flight, color: Colors.white, size: 28),
                              ),
                            ),
                          ),

                          const SizedBox(height: 16),

                          const Text(
                            'Create Account',
                            style: TextStyle(
                              color: AppTheme.textPrimaryWhite,
                              fontSize: 22,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1.0,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Join Smart Travel to plan and explore luxury stays',
                            style: TextStyle(
                              color: AppTheme.textSecondaryGrey.withValues(alpha: 0.9),
                              fontSize: 13,
                              fontWeight: FontWeight.w400,
                            ),
                          ),

                          const SizedBox(height: 24),

                          if (authProvider.errorMessage != null) ...[
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                              margin: const EdgeInsets.only(bottom: 18),
                              decoration: BoxDecoration(
                                color: const Color(0xFF2D1016),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: const Color(0xFFFF4D4D).withValues(alpha: 0.6)),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.error_outline, color: Color(0xFFFF5252), size: 18),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      authProvider.errorMessage!,
                                      style: const TextStyle(
                                        color: Color(0xFFFF9E9E),
                                        fontSize: 12.5,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],

                          // 1. Full Name
                          LoginInputField(
                            controller: _nameCtrl,
                            hintText: 'Full Name',
                            prefixIcon: Icons.person_outline_rounded,
                            validator: (val) {
                              if (val == null || val.trim().isEmpty) {
                                return 'Please enter your full name';
                              }
                              return null;
                            },
                          ),

                          const SizedBox(height: 14),

                          // 2. Email Address
                          LoginInputField(
                            controller: _emailCtrl,
                            hintText: 'Email address',
                            prefixIcon: Icons.mail_outline_rounded,
                            keyboardType: TextInputType.emailAddress,
                            validator: (val) {
                              if (val == null || val.trim().isEmpty) {
                                return 'Please enter your email';
                              }
                              if (!val.contains('@') || !val.contains('.')) {
                                return 'Please enter a valid email address';
                              }
                              return null;
                            },
                          ),

                          const SizedBox(height: 14),

                          // 3. Phone (Optional)
                          LoginInputField(
                            controller: _phoneCtrl,
                            hintText: 'Phone number (optional)',
                            prefixIcon: Icons.phone_outlined,
                            keyboardType: TextInputType.phone,
                          ),

                          const SizedBox(height: 14),

                          // 4. Password
                          LoginInputField(
                            controller: _passCtrl,
                            hintText: 'Password',
                            prefixIcon: Icons.lock_outline_rounded,
                            isPassword: true,
                            validator: (val) {
                              if (val == null || val.trim().isEmpty) {
                                return 'Please enter a password';
                              }
                              if (val.length < 6) {
                                return 'Password must be at least 6 characters';
                              }
                              return null;
                            },
                          ),

                          const SizedBox(height: 24),

                          // CTA Button
                          MouseRegion(
                            onEnter: (_) => setState(() => _isButtonHovered = true),
                            onExit: (_) => setState(() => _isButtonHovered = false),
                            cursor: SystemMouseCursors.click,
                            child: GestureDetector(
                              onTap: authProvider.isLoading ? null : _handleRegister,
                              child: Container(
                                width: double.infinity,
                                height: 50,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: _isButtonHovered
                                        ? const [Color(0xFF1AE0FF), Color(0xFF0090FF)]
                                        : const [Color(0xFF00D9FF), Color(0xFF0075FF)],
                                    begin: Alignment.centerLeft,
                                    end: Alignment.centerRight,
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppTheme.cyanAccent.withValues(
                                        alpha: _isButtonHovered ? 0.6 : 0.4,
                                      ),
                                      blurRadius: _isButtonHovered ? 20 : 16,
                                      offset: const Offset(0, 3),
                                    ),
                                  ],
                                ),
                                child: Center(
                                  child: authProvider.isLoading
                                      ? const SizedBox(
                                          width: 22,
                                          height: 22,
                                          child: CircularProgressIndicator(
                                            color: Colors.white,
                                            strokeWidth: 2.2,
                                          ),
                                        )
                                      : Row(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: const [
                                            Text(
                                              'Create Account',
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontSize: 15.5,
                                                fontWeight: FontWeight.w700,
                                                letterSpacing: 0.3,
                                              ),
                                            ),
                                            SizedBox(width: 8),
                                            Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 19),
                                          ],
                                        ),
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(height: 24),

                          // Already have an account? Sign In
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'Already have an account?',
                                style: TextStyle(
                                  color: AppTheme.textSecondaryGrey.withValues(alpha: 0.95),
                                  fontSize: 13.5,
                                ),
                              ),
                              const SizedBox(width: 6),
                              InkWell(
                                onTap: () => context.go('/login'),
                                child: const Text(
                                  'Sign In',
                                  style: TextStyle(
                                    color: AppTheme.cyanAccent,
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
