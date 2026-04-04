import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme.dart';
import '../widgets/progress_footer.dart';

class CreateAccountScreen extends StatefulWidget {
  const CreateAccountScreen({super.key});

  @override
  State<CreateAccountScreen> createState() => _CreateAccountScreenState();
}

class _CreateAccountScreenState extends State<CreateAccountScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _fadeCtrl;
  late final Animation<double> _logoFade;
  late final Animation<double> _cardsFade;
  late final Animation<Offset> _cardsSlide;

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );
    _logoFade = CurvedAnimation(
      parent: _fadeCtrl,
      curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
    );
    _cardsFade = CurvedAnimation(
      parent: _fadeCtrl,
      curve: const Interval(0.35, 1.0, curve: Curves.easeOut),
    );
    _cardsSlide = Tween<Offset>(
      begin: const Offset(0, 0.15),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _fadeCtrl,
      curve: const Interval(0.35, 1.0, curve: Curves.easeOutCubic),
    ));
    _fadeCtrl.forward();
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CashuranceTheme.deep,
      bottomNavigationBar: const ProgressFooter(currentStep: 0),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 40),
        children: [
          const SizedBox(height: 60),

          // ── Logo Section ──────────────────────────────────────────────
          FadeTransition(
            opacity: _logoFade,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.04),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: CashuranceTheme.ice.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 82,
                        height: 82,
                        decoration: BoxDecoration(
                          color: CashuranceTheme.teal,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        alignment: Alignment.center,
                        child: Image.asset(
                          'assets/logo.png',
                          width: 52,
                          height: 52,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'CASHURANCE',
                            style: GoogleFonts.spaceGrotesk(
                              fontWeight: FontWeight.w700,
                              fontSize: 30,
                              letterSpacing: 2.8,
                              color: Colors.white,
                              height: 0.95,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'INCOME PROTECTION',
                            style: GoogleFonts.spaceGrotesk(
                              fontWeight: FontWeight.w600,
                              fontSize: 11,
                              letterSpacing: 2.0,
                              color:
                                  CashuranceTheme.ice.withValues(alpha: 0.82),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 56),

          // ── Onboarding pill ───────────────────────────────────────────
          SlideTransition(
            position: _cardsSlide,
            child: FadeTransition(
              opacity: _cardsFade,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(
                        border: Border.all(
                            color: CashuranceTheme.teal.withValues(alpha: 0.5)),
                        borderRadius: BorderRadius.circular(99),
                      ),
                      child: Text(
                        'ONBOARDING',
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.5,
                          color: CashuranceTheme.ice,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),
                  Center(
                    child: Text(
                      'Income\nSecurity.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 48,
                        fontWeight: FontWeight.w700,
                        height: 1.05,
                        letterSpacing: -2,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Center(
                    child: Text(
                      'Protect your earnings from sudden\ndisruptions with simple, fast onboarding.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        height: 1.5,
                        color: CashuranceTheme.sage,
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),

                  // ── Stat Cards (frosted glass) ─────────────────────────
                  _FrostCard(
                    title: 'Average Payout Time',
                    value: '4 min',
                    subtitle: 'Fast UPI settlement after trigger verification',
                  ),
                  const SizedBox(height: 10),
                  _FrostCard(
                    title: 'Active Coverage',
                    value: '24k+',
                    subtitle: 'Delivery partners currently protected',
                  ),
                  const SizedBox(height: 10),
                  _FrostCard(
                    title: 'Claim Resolution',
                    value: '99.9%',
                    subtitle: 'Automated event-based processing',
                  ),

                  const SizedBox(height: 36),

                  // ── Action Buttons ─────────────────────────────────────
                  GestureDetector(
                    onTap: () => Navigator.pushNamed(context, '/login'),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [
                            CashuranceTheme.teal,
                            Color(0xFF3D6A70),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color:
                                CashuranceTheme.teal.withValues(alpha: 0.35),
                            blurRadius: 18,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Sign In',
                            style: GoogleFonts.spaceGrotesk(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(width: 8),
            
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  GestureDetector(
                    onTap: () => Navigator.pushNamed(context, '/login'),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      decoration: BoxDecoration(
                        color: Colors.transparent,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: CashuranceTheme.sage.withValues(alpha: 0.4),
                        ),
                      ),
                      child: Center(
                        child: Text(
                          'Get Started ->',
                          style: GoogleFonts.inter(
                            color: CashuranceTheme.sage,
                            fontWeight: FontWeight.w500,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),

                  // ── Footer ─────────────────────────────────────────────
                  Center(
                    child: Text(
                      'For delivery partners only.\nCashUrance © 2026',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: CashuranceTheme.sage.withValues(alpha: 0.5),
                        height: 1.6,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FrostCard extends StatelessWidget {
  const _FrostCard({
    required this.title,
    required this.value,
    required this.subtitle,
  });

  final String title;
  final String value;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: CashuranceTheme.teal.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: CashuranceTheme.sage.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title.toUpperCase(),
            style: GoogleFonts.spaceGrotesk(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.6,
              color: CashuranceTheme.sage,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: GoogleFonts.spaceGrotesk(
              fontSize: 34,
              fontWeight: FontWeight.w700,
              letterSpacing: -1,
              color: CashuranceTheme.ice,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            style: GoogleFonts.inter(
              fontSize: 13,
              color: CashuranceTheme.sage,
            ),
          ),
        ],
      ),
    );
  }
}
