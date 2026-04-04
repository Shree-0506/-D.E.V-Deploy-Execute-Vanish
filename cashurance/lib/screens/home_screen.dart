import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models.dart';
import '../theme.dart';
import '../app_state.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({
    super.key,
    required this.state,
    required this.onBuyPolicy,
    required this.onOpenAlerts,
    required this.onOpenHistory,
    required this.onOpenProfile,
  });

  final AppState state;
  final VoidCallback onBuyPolicy;
  final VoidCallback onOpenAlerts;
  final VoidCallback onOpenHistory;
  final VoidCallback onOpenProfile;

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      color: CashuranceTheme.teal,
      onRefresh: state.loadFromBackend,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
        children: [
          _WelcomeBand(state: state),
          const SizedBox(height: 12),
          _QuickActions(
            onBuyPolicy: onBuyPolicy,
            onOpenAlerts: onOpenAlerts,
            onOpenHistory: onOpenHistory,
            onOpenProfile: onOpenProfile,
          ),
          const SizedBox(height: 12),
          _CoveragePulseCard(state: state),
          const SizedBox(height: 12),
          _PolicyHeroCard(state: state, onBuyPolicy: onBuyPolicy),
          const SizedBox(height: 12),
          _PremiumIntelligenceCard(state: state),
          const SizedBox(height: 12),
          _PaymentSummaryCard(state: state),
          const SizedBox(height: 12),
          _RiskFeedCard(items: state.riskFeed),
          const SizedBox(height: 12),
          _EarningIntentCard(state: state),
        ],
      ),
    );
  }
}

class _WelcomeBand extends StatelessWidget {
  const _WelcomeBand({required this.state});

  final AppState state;

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  @override
  Widget build(BuildContext context) {
    final firstName = state.profile.name.split(' ').first;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: const LinearGradient(
          colors: [CashuranceTheme.deep, Color(0xFF1A4A51)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${_greeting()}, $firstName',
            style: GoogleFonts.spaceGrotesk(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Zone: ${state.profile.zoneName}',
            style: GoogleFonts.inter(
              color: CashuranceTheme.sage,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _pill(
                icon: Icons.shield_outlined,
                label: state.policyActive ? 'Policy Active' : 'Policy Inactive',
              ),
              _pill(
                icon: state.onlineToday
                    ? Icons.wifi_tethering_rounded
                    : Icons.wifi_tethering_off_rounded,
                label: state.onlineToday ? 'Online Today' : 'Marked Offline',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _pill({required IconData icon, required String label}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: CashuranceTheme.teal.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: CashuranceTheme.ice),
          const SizedBox(width: 6),
          Text(
            label,
            style: GoogleFonts.inter(
              color: CashuranceTheme.ice,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickActions extends StatelessWidget {
  const _QuickActions({
    required this.onBuyPolicy,
    required this.onOpenAlerts,
    required this.onOpenHistory,
    required this.onOpenProfile,
  });

  final VoidCallback onBuyPolicy;
  final VoidCallback onOpenAlerts;
  final VoidCallback onOpenHistory;
  final VoidCallback onOpenProfile;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _ActionTile(
            icon: Icons.add_card_rounded,
            title: 'Policy',
            subtitle: 'Buy',
            onTap: onBuyPolicy,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _ActionTile(
            icon: Icons.warning_amber_rounded,
            title: 'Alerts',
            subtitle: 'Track',
            onTap: onOpenAlerts,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _ActionTile(
            icon: Icons.timeline_rounded,
            title: 'Payouts',
            subtitle: 'Review',
            onTap: onOpenHistory,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _ActionTile(
            icon: Icons.person_rounded,
            title: 'Profile',
            subtitle: 'Edit',
            onTap: onOpenProfile,
          ),
        ),
      ],
    );
  }
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: CashuranceTheme.outlineVariant),
          color: CashuranceTheme.surfaceContainerLowest,
        ),
        child: Column(
          children: [
            Icon(icon, size: 18, color: CashuranceTheme.teal),
            const SizedBox(height: 4),
            Text(
              title,
              style: GoogleFonts.spaceGrotesk(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: CashuranceTheme.deep,
              ),
            ),
            Text(
              subtitle,
              style: GoogleFonts.inter(
                fontSize: 10,
                color: CashuranceTheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CoveragePulseCard extends StatelessWidget {
  const _CoveragePulseCard({required this.state});

  final AppState state;

  @override
  Widget build(BuildContext context) {
    final paid = state.payoutHistory.where((e) => e.status == PayoutStatus.paid).length;
    final pending =
        state.payoutHistory.where((e) => e.status == PayoutStatus.pending).length;
    final triggered = state.triggerAlerts
        .where((e) => e.zoneStatus == ZoneStatus.triggered)
        .length;

    return CashuranceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionLabel('Coverage Pulse'),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(child: _metric('Triggered', '$triggered', CashuranceTheme.warningOrange)),
              const SizedBox(width: 8),
              Expanded(child: _metric('Pending', '$pending', CashuranceTheme.warningOrange)),
              const SizedBox(width: 8),
              Expanded(child: _metric('Paid', '$paid', CashuranceTheme.successGreen)),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            'Pull down to refresh live risk and payout state.',
            style: GoogleFonts.inter(
              fontSize: 11,
              color: CashuranceTheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _metric(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: CashuranceTheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: GoogleFonts.spaceGrotesk(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 10,
              color: CashuranceTheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _PolicyHeroCard extends StatelessWidget {
  const _PolicyHeroCard({required this.state, required this.onBuyPolicy});

  final AppState state;
  final VoidCallback onBuyPolicy;

  @override
  Widget build(BuildContext context) {
    final policy = state.activePolicy;
    return CashuranceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Policy Status',
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: CashuranceTheme.deep,
                ),
              ),
              _StatusBadge(active: state.policyActive),
            ],
          ),
          const SizedBox(height: 16),
          if (state.policyActive && policy != null) ...[
            Row(
              children: [
                _DaysRingIndicator(days: policy.daysRemaining, total: 7),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        policy.coverageBadge,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: CashuranceTheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Zone: ${policy.zoneName}',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: CashuranceTheme.deep,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Premium paid: INR ${policy.premiumPaid.toStringAsFixed(0)}',
                        style: GoogleFonts.inter(fontSize: 13, color: CashuranceTheme.onSurfaceVariant),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ] else ...[
            Text(
              'No active policy this week.',
              style: GoogleFonts.inter(color: CashuranceTheme.onSurfaceVariant),
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: onBuyPolicy,
              icon: const Icon(Icons.add_card_outlined, size: 18),
              label: const Text("Buy This Week's Policy"),
            ),
          ],
        ],
      ),
    );
  }
}

class _DaysRingIndicator extends StatelessWidget {
  const _DaysRingIndicator({required this.days, required this.total});

  final int days;
  final int total;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 72,
      height: 72,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CircularProgressIndicator(
            value: days / total,
            strokeWidth: 6,
            backgroundColor: CashuranceTheme.surfaceContainerHighest,
            color: CashuranceTheme.teal,
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '$days',
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: CashuranceTheme.deep,
                ),
              ),
              Text(
                'days',
                style: GoogleFonts.inter(
                  fontSize: 9,
                  color: CashuranceTheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.active});

  final bool active;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: active ? CashuranceTheme.successBg : CashuranceTheme.rejectBg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        active ? 'Active' : 'Inactive',
        style: GoogleFonts.spaceGrotesk(
          fontWeight: FontWeight.w700,
          fontSize: 12,
          color: active ? CashuranceTheme.successGreen : CashuranceTheme.rejectRed,
        ),
      ),
    );
  }
}

class _RiskFeedCard extends StatelessWidget {
  const _RiskFeedCard({required this.items});

  final List<RiskFeedItem> items;

  Color _levelColor(String level) {
    switch (level) {
      case 'High':
        return CashuranceTheme.rejectRed;
      case 'Moderate':
        return CashuranceTheme.warningOrange;
      default:
        return CashuranceTheme.successGreen;
    }
  }

  Color _levelBg(String level) {
    switch (level) {
      case 'High':
        return CashuranceTheme.rejectBg;
      case 'Moderate':
        return CashuranceTheme.warningBg;
      default:
        return CashuranceTheme.successBg;
    }
  }

  @override
  Widget build(BuildContext context) {
    return CashuranceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Live Risk Feed',
            style: GoogleFonts.spaceGrotesk(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: CashuranceTheme.deep,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: items.map((item) {
              return Expanded(
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
                  decoration: BoxDecoration(
                    color: _levelBg(item.level),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      Text(
                        item.icon,
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        item.label,
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: CashuranceTheme.deep,
                        ),
                      ),
                      Text(
                        item.level,
                        style: GoogleFonts.inter(
                          fontSize: 9,
                          color: _levelColor(item.level),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

class _PremiumIntelligenceCard extends StatelessWidget {
  const _PremiumIntelligenceCard({required this.state});

  final AppState state;

  @override
  Widget build(BuildContext context) {
    final premium = state.premiumBreakdown;
    return CashuranceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionLabel('Premium Intelligence'),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(child: _kv('Base', 'INR ${premium.baseRate.toStringAsFixed(0)}')),
              const SizedBox(width: 8),
              Expanded(child: _kv('Zone', 'INR ${premium.zoneRisk.toStringAsFixed(0)}')),
              const SizedBox(width: 8),
              Expanded(child: _kv('Weather', 'INR ${premium.weatherVolatility.toStringAsFixed(0)}')),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(child: _kv('Mobility', 'INR ${premium.mobilityRisk.toStringAsFixed(0)}')),
              const SizedBox(width: 8),
              Expanded(child: _kv('Safety', '-INR ${premium.safetyDiscount.toStringAsFixed(0)}')),
              const SizedBox(width: 8),
              Expanded(child: _kv('Total', 'INR ${premium.total.toStringAsFixed(0)}')),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            premium.aiReason,
            style: GoogleFonts.inter(
              fontSize: 11,
              color: CashuranceTheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Model: ${premium.modelName} | Confidence: ${(premium.modelConfidence * 100).toStringAsFixed(0)}%',
            style: GoogleFonts.spaceGrotesk(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: CashuranceTheme.teal,
            ),
          ),
        ],
      ),
    );
  }

  Widget _kv(String key, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: CashuranceTheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            key,
            style: GoogleFonts.inter(
              fontSize: 10,
              color: CashuranceTheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: GoogleFonts.spaceGrotesk(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: CashuranceTheme.deep,
            ),
          ),
        ],
      ),
    );
  }
}

class _PaymentSummaryCard extends StatelessWidget {
  const _PaymentSummaryCard({required this.state});

  final AppState state;

  String _fmtDate(DateTime? value) {
    if (value == null) return 'N/A';
    return '${value.day.toString().padLeft(2, '0')}/${value.month.toString().padLeft(2, '0')}/${value.year}';
  }

  @override
  Widget build(BuildContext context) {
    final summary = state.paymentSummary;

    return CashuranceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionLabel('Payment Snapshot'),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(child: _kv('Last Pay Date', _fmtDate(summary.lastPayDate))),
              const SizedBox(width: 10),
              Expanded(child: _kv('Last Payout Date', _fmtDate(summary.lastPayoutDate))),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(child: _kv('Days Remaining', '${summary.daysRemaining} days')),
              const SizedBox(width: 10),
              Expanded(child: _kv('Pay Amount', 'INR ${summary.payAmount.toStringAsFixed(0)}')),
            ],
          ),
          const SizedBox(height: 8),
          _kv('Pay Due', 'INR ${summary.payDue.toStringAsFixed(0)}'),
        ],
      ),
    );
  }

  Widget _kv(String key, String value) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: CashuranceTheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            key,
            style: GoogleFonts.inter(
              fontSize: 10,
              color: CashuranceTheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: GoogleFonts.spaceGrotesk(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: CashuranceTheme.deep,
            ),
          ),
        ],
      ),
    );
  }
}

class _EarningIntentCard extends StatelessWidget {
  const _EarningIntentCard({required this.state});

  final AppState state;

  @override
  Widget build(BuildContext context) {
    return CashuranceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SwitchListTile.adaptive(
            value: state.onlineToday,
            contentPadding: EdgeInsets.zero,
            activeThumbColor: CashuranceTheme.teal,
            activeTrackColor: CashuranceTheme.ice,
            onChanged: state.setOnlineToday,
            title: Text(
              "I'm Online Today",
              style: GoogleFonts.spaceGrotesk(
                fontWeight: FontWeight.w700,
                fontSize: 15,
                color: CashuranceTheme.deep,
              ),
            ),
            subtitle: Text(
              'Stay online during disruption to validate payout eligibility.',
              style: GoogleFonts.inter(
                fontSize: 12,
                color: CashuranceTheme.onSurfaceVariant,
              ),
            ),
          ),
          if (!state.onlineToday)
            Container(
              margin: const EdgeInsets.only(top: 8),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: CashuranceTheme.warningBg,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.warning_amber_rounded,
                    color: CashuranceTheme.warningOrange,
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Offline riders are not eligible for payout even if disruption occurs.',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: CashuranceTheme.warningOrange,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
