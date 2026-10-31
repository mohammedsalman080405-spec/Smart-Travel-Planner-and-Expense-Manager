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
  final double height;

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
    this.height = 42.0,
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
    return FormField<String>(
      initialValue: widget.controller.text,
      validator: widget.validator,
      builder: (FormFieldState<String> state) {
        final hasError = state.hasError;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              height: widget.height,
              decoration: BoxDecoration(
                color: const Color(0xFF0A0F19).withValues(alpha: 0.90),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: hasError
                      ? const Color(0xFFFF4D4D)
                      : _isFocused
                          ? AppTheme.cyanAccent
                          : const Color(0xFF222D3E),
                  width: _isFocused ? 1.4 : 1.0,
                ),
                boxShadow: _isFocused
                    ? [
                        BoxShadow(
                          color: AppTheme.cyanAccent.withValues(alpha: 0.22),
                          blurRadius: 10,
                          offset: const Offset(0, 1),
                        ),
                      ]
                    : [],
              ),
              child: Row(
                children: [
                  // Centered Prefix Icon
                  SizedBox(
                    width: 40,
                    height: widget.height,
                    child: Icon(
                      widget.prefixIcon,
                      color: _isFocused
                          ? AppTheme.cyanAccent
                          : const Color(0xFF7A8B9E),
                      size: 18,
                    ),
                  ),

                  // Editable Text Area
                  Expanded(
                    child: TextField(
                      controller: widget.controller,
                      focusNode: _internalFocusNode,
                      obscureText: widget.isPassword ? _obscureText : false,
                      keyboardType: widget.keyboardType,
                      onSubmitted: widget.onFieldSubmitted,
                      textAlignVertical: TextAlignVertical.center,
                      onChanged: (val) {
                        if (state.hasError) {
                          state.didChange(val);
                        }
                      },
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13.5,
                        fontWeight: FontWeight.w500,
                      ),
                      cursorColor: AppTheme.cyanAccent,
                      decoration: InputDecoration(
                        hintText: widget.hintText,
                        hintStyle: TextStyle(
                          color: const Color(0xFF758597).withValues(alpha: 0.9),
                          fontSize: 13.0,
                          fontWeight: FontWeight.w400,
                        ),
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(vertical: 10),
                      ),
                    ),
                  ),

                  // Password Visibility Toggle Icon (if applicable)
                  if (widget.isPassword)
                    SizedBox(
                      width: 40,
                      height: widget.height,
                      child: IconButton(
                        icon: Icon(
                          _obscureText
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                          color: _isFocused
                              ? AppTheme.cyanAccent
                              : const Color(0xFF7A8B9E),
                          size: 18,
                        ),
                        splashRadius: 16,
                        onPressed: () {
                          setState(() {
                            _obscureText = !_obscureText;
                          });
                        },
                      ),
                    ),
                ],
              ),
            ),

            if (hasError)
              Padding(
                padding: const EdgeInsets.only(left: 4, top: 4),
                child: Text(
                  state.errorText ?? '',
                  style: const TextStyle(
                    color: Color(0xFFFF5252),
                    fontSize: 11.5,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
