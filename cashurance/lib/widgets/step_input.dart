import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme.dart';

/// A sleek, minimalist outline input field
class StepInput extends StatelessWidget {
  final String label;
  final String placeholder;
  final TextInputType? keyboardType;
  final TextEditingController? controller;
  final int maxLines;
  final String? prefixText;
  final int? maxLength;
  final bool obscureText;
  final Widget? suffixIcon;

  const StepInput({
    super.key,
    required this.label,
    required this.placeholder,
    this.keyboardType,
    this.controller,
    this.maxLines = 1,
    this.prefixText,
    this.maxLength,
    this.obscureText = false,
    this.suffixIcon,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: GoogleFonts.spaceGrotesk(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            letterSpacing: 1,
            color: CashuranceTheme.sage,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          maxLines: maxLines,
          maxLength: maxLength,
          obscureText: obscureText,
          style: GoogleFonts.inter(
            fontSize: 15,
            color: CashuranceTheme.deep,
          ),
          decoration: InputDecoration(
            hintText: placeholder,
            prefixText: prefixText,
            prefixStyle: GoogleFonts.inter(
              fontSize: 15,
              color: CashuranceTheme.deep,
              fontWeight: FontWeight.w400,
            ),
            suffixIcon: suffixIcon,
            counterText: '',
            filled: true,
            fillColor: Colors.transparent,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(
                  color: CashuranceTheme.sage.withValues(alpha: 0.4),
                  width: 1),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(
                  color: CashuranceTheme.sage.withValues(alpha: 0.4),
                  width: 1),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide:
                  const BorderSide(color: CashuranceTheme.teal, width: 1.5),
            ),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            hintStyle: GoogleFonts.inter(
              color: CashuranceTheme.sage.withValues(alpha: 0.6),
              fontSize: 15,
            ),
          ),
        ),
      ],
    );
  }
}
