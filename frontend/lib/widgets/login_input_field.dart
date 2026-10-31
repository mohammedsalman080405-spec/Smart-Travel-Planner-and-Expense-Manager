import 'package:flutter/material.dart';
import '../config/theme.dart';

class LoginInputField extends StatefulWidget {
  final TextEditingController controller;
  final String hintText;
  final IconData prefixIcon;
  final bool isPassword;
  final TextInputType keyboardType;
  final String? Function(String?)? validator;
  final void Function(String)? onFieldSubmitted;
  final FocusNode? focusNode;

  const LoginInputField({
    super.key,
    required this.controller,
    required this.hintText,
    required this.prefixIcon,
    this.isPassword = false,
    this.keyboardType = TextInputType.text,
    this.validator,
    this.onFieldSubmitted,
    this.focusNode,
  });

  @override
  State<LoginInputField> createState() => _LoginInputFieldState();
}

class _LoginInputFieldState extends State<LoginInputField> {
  bool _obscureText = true;
  bool _isFocused = false;
  late final FocusNode _internalFocusNode;

  @override
  void initState() {
    super.initState();
    _internalFocusNode = widget.focusNode ?? FocusNode();
    _internalFocusNode.addListener(_handleFocusChange);
  }

  void _handleFocusChange() {
    setState(() {
      _isFocused = _internalFocusNode.hasFocus;
    });
  }

  @override
  void dispose() {
    if (widget.focusNode == null) {
      _internalFocusNode.dispose();
    } else {
      _internalFocusNode.removeListener(_handleFocusChange);
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        color: const Color(0xFF0E131F).withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _isFocused
              ? AppTheme.cyanAccent
              : const Color(0xFF263242).withValues(alpha: 0.8),
          width: _isFocused ? 1.4 : 1.0,
        ),
        boxShadow: _isFocused
            ? [
                BoxShadow(
                  color: AppTheme.cyanAccent.withValues(alpha: 0.2),
                  blurRadius: 10,
                  offset: const Offset(0, 1),
                ),
              ]
            : [],
      ),
      child: TextFormField(
        controller: widget.controller,
        focusNode: _internalFocusNode,
        obscureText: widget.isPassword ? _obscureText : false,
        keyboardType: widget.keyboardType,
        validator: widget.validator,
        onFieldSubmitted: widget.onFieldSubmitted,
        style: const TextStyle(
          color: AppTheme.textPrimaryWhite,
          fontSize: 14.5,
          fontWeight: FontWeight.w500,
        ),
        cursorColor: AppTheme.cyanAccent,
        decoration: InputDecoration(
          hintText: widget.hintText,
          hintStyle: TextStyle(
            color: const Color(0xFF7A8B9E).withValues(alpha: 0.9),
            fontSize: 14.0,
            fontWeight: FontWeight.w400,
          ),
          prefixIcon: Icon(
            widget.prefixIcon,
            color: _isFocused
                ? AppTheme.cyanAccent
                : const Color(0xFF7A8B9E),
            size: 19,
          ),
          suffixIcon: widget.isPassword
              ? IconButton(
                  icon: Icon(
                    _obscureText
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                    color: _isFocused
                        ? AppTheme.cyanAccent
                        : const Color(0xFF7A8B9E),
                    size: 19,
                  ),
                  onPressed: () {
                    setState(() {
                      _obscureText = !_obscureText;
                    });
                  },
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
          errorStyle: const TextStyle(
            color: Color(0xFFFF5252),
            fontSize: 12,
            height: 1.0,
          ),
        ),
      ),
    );
  }
}
