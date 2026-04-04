import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme.dart';

/// Ultra-minimalist fixed-bottom progress footer
class ProgressFooter extends StatelessWidget {
  /// 0-based step index (0 = account, 1 = personal, 2 = identity, 3 = platform)
  final int currentStep;

  const ProgressFooter({super.key, required this.currentStep});

  static const _stepsFull = [
    'Personal Details',
    'Identity Verification',
    'Platform Integration',
  ];

  @override
  Widget build(BuildContext context) {
    const totalSteps = 3;
    final displayStep = currentStep;
    final pct =
        currentStep == 0 ? 0 : ((displayStep / totalSteps) * 100).round();

    final isDark = currentStep == 0;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? CashuranceTheme.deep : Colors.white,
        border: Border(
          top: BorderSide(
            color: isDark
                ? CashuranceTheme.teal.withValues(alpha: 0.3)
                : CashuranceTheme.outlineVariant,
            width: 1,
          ),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Ultra-thin continuous progress bar
            if (currentStep > 0)
              Stack(
                children: [
                  Container(
                      height: 2,
                      width: double.infinity,
                      color: CashuranceTheme.surfaceContainerLow),
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 600),
                    curve: Curves.easeOutExpo,
                    height: 2,
                    width: MediaQuery.of(context).size.width * (pct / 100),
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [CashuranceTheme.teal, CashuranceTheme.ice],
                      ),
                    ),
                  ),
                ],
              ),

            // Step labels / nav
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: currentStep == 0
                  ? _buildLandingFooter(isDark)
                  : _buildStepFooter(displayStep, totalSteps),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLandingFooter(bool isDark) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                  color: isDark ? CashuranceTheme.ice : CashuranceTheme.teal,
                  shape: BoxShape.circle),
            ),
            const SizedBox(width: 8),
            Text(
              'Getting Started',
              style: GoogleFonts.spaceGrotesk(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color:
                    isDark ? CashuranceTheme.ice : CashuranceTheme.deep,
              ),
            ),
          ],
        ),
        Text(
          '0% Complete',
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.w400,
            color: isDark ? CashuranceTheme.sage : CashuranceTheme.sage,
          ),
        ),
      ],
    );
  }

  Widget _buildStepFooter(int displayStep, int totalSteps) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          _stepsFull[displayStep - 1],
          style: GoogleFonts.spaceGrotesk(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: CashuranceTheme.deep,
          ),
        ),
        Text(
          'Step $displayStep of $totalSteps',
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.w400,
            color: CashuranceTheme.sage,
          ),
        ),
      ],
    );
  }
}
