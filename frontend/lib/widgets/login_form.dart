import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../config/theme.dart';
import '../providers/auth_provider.dart';
import 'login_input_field.dart';
import 'social_login_button.dart';

class LoginFormCard extends StatefulWidget {
  const LoginFormCard({super.key});

  @override
  State<LoginFormCard> createState() => _LoginFormCardState();
}

class _LoginFormCardState extends State<LoginFormCard> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController(text: 'traveler@smarttravel.com');
  final _passCtrl = TextEditingController(text: 'Travel123!');
  bool _rememberMe = true;
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
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    if (_formKey.currentState?.validate() != true) return;

    final authProvider = context.read<AuthProvider>();
    final success = await authProvider.login(
      _emailCtrl.text.trim(),
      _passCtrl.text.trim(),
    );

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: const [
              Icon(Icons.check_circle_outline, color: AppTheme.cyanAccent, size: 20),
              SizedBox(width: 10),
              Text('Welcome back to Smart Travel Planner!'),
            ],
          ),
          backgroundColor: const Color(0xFF0A101D),
          duration: const Duration(seconds: 2),
        ),
      );
      context.go('/');
    }
  }

  void _showSocialNotConfigured(String provider) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$provider sign-in is not configured in this environment.'),
        backgroundColor: const Color(0xFF141923),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();

    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          width: 440,
          padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 38),
          decoration: BoxDecoration(
            color: const Color(0xFF080C14).withValues(alpha: 0.88),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: AppTheme.cyanAccent.withValues(alpha: 0.35),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: AppTheme.cyanAccent.withValues(alpha: 0.18),
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
                // 1. Top Airplane Icon
                Container(
                  width: 54,
                  height: 54,
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
                      child: const Icon(
                        Icons.flight,
                        color: Colors.white,
                        size: 30,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // 2. Title & Subtitle
                const Text(
                  'SMART TRAVEL',
                  style: TextStyle(
                    color: AppTheme.textPrimaryWhite,
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.1,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Sign in to continue your journey',
                  style: TextStyle(
                    color: AppTheme.textSecondaryGrey.withValues(alpha: 0.9),
                    fontSize: 13.5,
                    fontWeight: FontWeight.w400,
                    letterSpacing: 0.2,
                  ),
                ),

                const SizedBox(height: 28),

                // Error Message Pill (if any)
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

                // 3. Email Input Field
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

                const SizedBox(height: 16),

                // 4. Password Input Field
                LoginInputField(
                  controller: _passCtrl,
                  hintText: 'Password',
                  prefixIcon: Icons.lock_outline_rounded,
                  isPassword: true,
                  onFieldSubmitted: (_) => _handleSubmit(),
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) {
                      return 'Please enter your password';
                    }
                    if (val.length < 4) {
                      return 'Password must be at least 4 characters';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 12),

                // 5. Remember Me & Forgot Password Row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Remember Me Checkbox
                    InkWell(
                      onTap: () => setState(() => _rememberMe = !_rememberMe),
                      borderRadius: BorderRadius.circular(6),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            SizedBox(
                              width: 18,
                              height: 18,
                              child: Checkbox(
                                value: _rememberMe,
                                onChanged: (val) => setState(() => _rememberMe = val ?? false),
                                activeColor: AppTheme.cyanAccent,
                                checkColor: Colors.black,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                                side: BorderSide(
                                  color: AppTheme.cyanAccent.withValues(alpha: 0.7),
                                  width: 1.5,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Text(
                              'Remember me',
                              style: TextStyle(
                                color: AppTheme.cyanAccent,
                                fontSize: 13.0,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Forgot Password Link
                    InkWell(
                      onTap: () => context.push('/forgot-password'),
                      borderRadius: BorderRadius.circular(6),
                      child: const Padding(
                        padding: EdgeInsets.symmetric(vertical: 4, horizontal: 2),
                        child: Text(
                          'Forgot password?',
                          style: TextStyle(
                            color: AppTheme.cyanAccent,
                            fontSize: 13.0,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 22),

                // 6. Sign In CTA Button
                MouseRegion(
                  onEnter: (_) => setState(() => _isButtonHovered = true),
                  onExit: (_) => setState(() => _isButtonHovered = false),
                  cursor: SystemMouseCursors.click,
                  child: GestureDetector(
                    onTap: authProvider.isLoading ? null : _handleSubmit,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
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
                            blurRadius: _isButtonHovered ? 22 : 16,
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
                                    'Sign In',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 15.5,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 0.4,
                                    ),
                                  ),
                                  SizedBox(width: 8),
                                  Icon(
                                    Icons.arrow_forward_rounded,
                                    color: Colors.white,
                                    size: 19,
                                  ),
                                ],
                              ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 26),

                // 7. Divider: OR CONTINUE WITH
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        height: 1,
                        color: const Color(0xFF263242).withValues(alpha: 0.8),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      child: Text(
                        'OR CONTINUE WITH',
                        style: TextStyle(
                          color: const Color(0xFF7A8B9E).withValues(alpha: 0.9),
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Container(
                        height: 1,
                        color: const Color(0xFF263242).withValues(alpha: 0.8),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 22),

                // 8. Social Login Buttons Row: Google & Apple
                Row(
                  children: [
                    SocialLoginButton(
                      type: SocialLoginType.google,
                      onPressed: () => _showSocialNotConfigured('Google'),
                    ),
                    const SizedBox(width: 14),
                    SocialLoginButton(
                      type: SocialLoginType.apple,
                      onPressed: () => _showSocialNotConfigured('Apple'),
                    ),
                  ],
                ),

                const SizedBox(height: 28),

                // 9. Create Account Link
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "Don't have an account?",
                      style: TextStyle(
                        color: AppTheme.textSecondaryGrey.withValues(alpha: 0.95),
                        fontSize: 13.5,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                    const SizedBox(width: 6),
                    InkWell(
                      onTap: () => context.push('/register'),
                      borderRadius: BorderRadius.circular(4),
                      child: const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                        child: Text(
                          'Create Account',
                          style: TextStyle(
                            color: AppTheme.cyanAccent,
                            fontSize: 13.5,
                            fontWeight: FontWeight.w700,
                          ),
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
    );
  }
}
