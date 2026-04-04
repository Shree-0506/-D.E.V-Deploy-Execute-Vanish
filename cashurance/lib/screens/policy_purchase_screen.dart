import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../app_state.dart';
import '../theme.dart';

class PolicyPurchaseScreen extends StatefulWidget {
  const PolicyPurchaseScreen({
    super.key,
    required this.state,
    required this.onPurchased,
  });

  final AppState state;
  final VoidCallback onPurchased;

  @override
  State<PolicyPurchaseScreen> createState() => _PolicyPurchaseScreenState();
}

class _PolicyPurchaseScreenState extends State<PolicyPurchaseScreen> {
  bool _submitting = false;

  Future<void> _purchase() async {
    setState(() => _submitting = true);
    final ok = await widget.state.purchasePolicy();
    if (!mounted) return;

    setState(() => _submitting = false);
    if (!ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to purchase policy. Check backend connection.'),
        ),
      );
      return;
    }

    widget.onPurchased();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Policy purchased successfully.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final breakdown = widget.state.premiumBreakdown;
    final paymentSummary = widget.state.paymentSummary;

    String fmt(DateTime? value) {
      if (value == null) return 'N/A';
      return '${value.day.toString().padLeft(2, '0')}/${value.month.toString().padLeft(2, '0')}/${value.year}';
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
      children: [
        const SectionLabel('Weekly Protection'),
        const SizedBox(height: 6),
        Text(
          'Buy Policy',
          style: GoogleFonts.spaceGrotesk(
            fontSize: 26,
            fontWeight: FontWeight.w700,
            color: CashuranceTheme.deep,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Coverage is active for this week in your selected zone.',
          style: GoogleFonts.inter(
            fontSize: 13,
            color: CashuranceTheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 16),
        CashuranceCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: CashuranceTheme.ice.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.location_on_outlined,
                        color: CashuranceTheme.teal, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Zone: ${widget.state.profile.zoneName}',
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: CashuranceTheme.deep,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _row('Base Rate', breakdown.baseRate),
              _row('Zone Risk Loading', breakdown.zoneRisk),
              _row('Weather Volatility', breakdown.weatherVolatility),
              _row('Mobility Risk', breakdown.mobilityRisk),
              _row('Safety Discount', -breakdown.safetyDiscount),
              Divider(
                  height: 24,
                  color: CashuranceTheme.sage.withValues(alpha: 0.2)),
              _row('Total Weekly Premium', breakdown.total, isTotal: true),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: CashuranceTheme.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _infoRow('Last Pay Date', fmt(paymentSummary.lastPayDate)),
                    const SizedBox(height: 4),
                    _infoRow('Days Remaining',
                        '${paymentSummary.daysRemaining}'),
                    const SizedBox(height: 4),
                    _infoRow(
                        'Next Due Date', fmt(paymentSummary.payDueDate)),
                    const SizedBox(height: 4),
                    _infoRow('Pay Due',
                        'INR ${paymentSummary.payDue.toStringAsFixed(0)}',
                        highlight: true),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: CashuranceTheme.ice.withValues(alpha: 0.35),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.info_outline,
                      size: 16,
                      color: CashuranceTheme.teal,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Estimated payout range for qualified events: INR 500 - INR 750.',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          color: CashuranceTheme.deep,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              FilledButton.icon(
                onPressed:
                    widget.state.policyActive || _submitting ? null : _purchase,
                icon: const Icon(Icons.add_card_rounded, size: 18),
                label: Text(
                  widget.state.policyActive
                      ? 'Policy Already Active'
                      : (_submitting ? 'Processing...' : 'Confirm & Pay'),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _row(String label, double value, {bool isTotal = false}) {
    final sign = value < 0 ? '- INR ' : '+ INR ';
    final text = isTotal
        ? 'INR ${value.toStringAsFixed(0)}'
        : '$sign${value.abs().toStringAsFixed(0)}';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: GoogleFonts.inter(
                fontWeight: isTotal ? FontWeight.w700 : FontWeight.w500,
                color: CashuranceTheme.deep,
              ),
            ),
          ),
          Text(
            text,
            style: GoogleFonts.spaceGrotesk(
              fontWeight: isTotal ? FontWeight.w700 : FontWeight.w600,
              color:
                  isTotal ? CashuranceTheme.teal : CashuranceTheme.deep,
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoRow(String key, String value, {bool highlight = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          key,
          style: GoogleFonts.inter(
              fontSize: 11, color: CashuranceTheme.onSurfaceVariant),
        ),
        Text(
          value,
          style: highlight
              ? GoogleFonts.spaceGrotesk(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: CashuranceTheme.teal,
                )
              : GoogleFonts.inter(
                  fontSize: 11, color: CashuranceTheme.deep),
        ),
      ],
    );
  }
}
