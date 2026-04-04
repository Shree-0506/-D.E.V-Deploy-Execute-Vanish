import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models.dart';
import '../theme.dart';
import '../app_state.dart';

class TriggerAlertsScreen extends StatefulWidget {
  const TriggerAlertsScreen({super.key, required this.state});

  final AppState state;

  @override
  State<TriggerAlertsScreen> createState() => _TriggerAlertsScreenState();
}

class _TriggerAlertsScreenState extends State<TriggerAlertsScreen> {
  String _query = '';
  String _severity = 'all';
  bool _triggeredOnly = false;

  List<TriggerAlert> get _filteredAlerts {
    final q = _query.trim().toLowerCase();
    return widget.state.triggerAlerts.where((alert) {
      if (_triggeredOnly && alert.zoneStatus != ZoneStatus.triggered) {
        return false;
      }
      if (_severity != 'all' && alert.severity.name != _severity) {
        return false;
      }
      if (q.isEmpty) return true;
      return alert.eventTypeLabel.toLowerCase().contains(q) ||
          alert.eventId.toLowerCase().contains(q) ||
          alert.dataSource.toLowerCase().contains(q);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final alerts = _filteredAlerts;
    return RefreshIndicator(
      color: CashuranceTheme.teal,
      onRefresh: widget.state.loadFromBackend,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
        children: [
          const SectionLabel('Live Trigger Monitoring'),
          const SizedBox(height: 6),
          Text(
            'Active Alerts',
            style: GoogleFonts.spaceGrotesk(
              fontSize: 26,
              fontWeight: FontWeight.w700,
              color: CashuranceTheme.deep,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Search and filter event signals in real time.',
            style: GoogleFonts.inter(
              fontSize: 13,
              color: CashuranceTheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 12),
          CashuranceCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  onChanged: (value) => setState(() => _query = value),
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.search_rounded),
                    labelText: 'Search by event, source, or ID',
                  ),
                ),
                const SizedBox(height: 10),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _chip('All', 'all'),
                      const SizedBox(width: 8),
                      _chip('Normal', 'normal'),
                      const SizedBox(width: 8),
                      _chip('Severe', 'severe'),
                      const SizedBox(width: 8),
                      _chip('Catastrophic', 'catastrophic'),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                SwitchListTile.adaptive(
                  value: _triggeredOnly,
                  contentPadding: EdgeInsets.zero,
                  activeThumbColor: CashuranceTheme.teal,
                  activeTrackColor: CashuranceTheme.ice,
                  title: Text(
                    'Triggered zone only',
                    style: GoogleFonts.inter(
                        fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                  onChanged: (value) =>
                      setState(() => _triggeredOnly = value),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          if (!widget.state.policyActive) const _EligibilityWarningBanner(),
          if (alerts.isEmpty)
            const _NoAlertResults()
          else
            ...alerts.map(
              (alert) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _AlertCard(alert: alert, state: widget.state),
              ),
            ),
        ],
      ),
    );
  }

  Widget _chip(String label, String value) {
    return ChoiceChip(
      label: Text(label),
      selected: _severity == value,
      onSelected: (_) => setState(() => _severity = value),
    );
  }
}

class _NoAlertResults extends StatelessWidget {
  const _NoAlertResults();

  @override
  Widget build(BuildContext context) {
    return CashuranceCard(
      child: Column(
        children: [
          const SizedBox(height: 10),
          const Icon(Icons.filter_alt_off_rounded,
              size: 36, color: CashuranceTheme.sage),
          const SizedBox(height: 8),
          Text(
            'No alerts match these filters',
            style: GoogleFonts.spaceGrotesk(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: CashuranceTheme.deep),
          ),
          const SizedBox(height: 4),
          Text(
            'Try removing filters or searching with a broader term.',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 12,
              color: CashuranceTheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _EligibilityWarningBanner extends StatelessWidget {
  const _EligibilityWarningBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: CashuranceTheme.warningBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: CashuranceTheme.warningOrange.withValues(alpha: 0.4),
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.warning_amber_rounded,
            color: CashuranceTheme.warningOrange,
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'No active policy - you are not eligible for payouts. Purchase a policy first.',
              style: GoogleFonts.inter(
                fontSize: 12,
                color: CashuranceTheme.warningOrange,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AlertCard extends StatelessWidget {
  const _AlertCard({required this.alert, required this.state});

  final TriggerAlert alert;
  final AppState state;

  Color get _severityColor {
    switch (alert.severity) {
      case EventSeverity.catastrophic:
        return CashuranceTheme.rejectRed;
      case EventSeverity.severe:
        return CashuranceTheme.warningOrange;
      case EventSeverity.normal:
        return CashuranceTheme.successGreen;
    }
  }

  Color get _severityBg {
    switch (alert.severity) {
      case EventSeverity.catastrophic:
        return CashuranceTheme.rejectBg;
      case EventSeverity.severe:
        return CashuranceTheme.warningBg;
      case EventSeverity.normal:
        return CashuranceTheme.successBg;
    }
  }

  String get _zoneStatusLabel {
    switch (alert.zoneStatus) {
      case ZoneStatus.triggered:
        return 'Triggered';
      case ZoneStatus.watchlist:
        return 'Watchlist';
      case ZoneStatus.stable:
        return 'Stable';
    }
  }

  Color get _zoneStatusColor {
    switch (alert.zoneStatus) {
      case ZoneStatus.triggered:
        return CashuranceTheme.rejectRed;
      case ZoneStatus.watchlist:
        return CashuranceTheme.warningOrange;
      case ZoneStatus.stable:
        return CashuranceTheme.successGreen;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isTriggered = alert.zoneStatus == ZoneStatus.triggered;

    return CashuranceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  alert.eventTypeLabel,
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: CashuranceTheme.deep,
                  ),
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: _severityBg,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  alert.severityLabel,
                  style: GoogleFonts.spaceGrotesk(
                    fontWeight: FontWeight.w700,
                    fontSize: 11,
                    color: _severityColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: _zoneStatusColor,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                'Zone Status: $_zoneStatusLabel',
                style: GoogleFonts.inter(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                    color: CashuranceTheme.deep),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Event ID: ${alert.eventId}',
            style: GoogleFonts.inter(
              fontSize: 11,
              color: CashuranceTheme.onSurfaceVariant,
            ),
          ),
          Text(
            'Source: ${alert.dataSource}',
            style: GoogleFonts.inter(
              fontSize: 11,
              color: CashuranceTheme.onSurfaceVariant,
            ),
          ),
          if (alert.metricSummary.isNotEmpty)
            Text(
              alert.metricSummary,
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: CashuranceTheme.teal,
              ),
            ),
          if (isTriggered) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: CashuranceTheme.ice.withValues(alpha: 0.35),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                'Estimated payout: INR ${alert.computedPayout.toStringAsFixed(0)}',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: CashuranceTheme.teal,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
