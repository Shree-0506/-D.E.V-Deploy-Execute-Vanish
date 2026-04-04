import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models.dart';
import '../theme.dart';
import '../app_state.dart';

class PayoutHistoryScreen extends StatefulWidget {
  const PayoutHistoryScreen({super.key, required this.state});

  final AppState state;

  @override
  State<PayoutHistoryScreen> createState() => _PayoutHistoryScreenState();
}

class _PayoutHistoryScreenState extends State<PayoutHistoryScreen> {
  String _query = '';
  PayoutStatus? _status;

  List<PayoutRecord> get _filteredRows {
    final q = _query.trim().toLowerCase();
    final rows = widget.state.payoutHistory.where((row) {
      if (_status != null && row.status != _status) {
        return false;
      }
      if (q.isEmpty) return true;
      return row.eventType.toLowerCase().contains(q) ||
          row.eventId.toLowerCase().contains(q) ||
          row.triggerReason.toLowerCase().contains(q);
    }).toList();

    rows.sort((a, b) => b.eventDate.compareTo(a.eventDate));
    return rows;
  }

  @override
  Widget build(BuildContext context) {
    final rows = _filteredRows;

    return RefreshIndicator(
      color: CashuranceTheme.teal,
      onRefresh: widget.state.loadFromBackend,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
        children: [
          const SectionLabel('Audit Trail'),
          const SizedBox(height: 6),
          Text(
            'Payout History',
            style: GoogleFonts.spaceGrotesk(
                fontSize: 26,
                fontWeight: FontWeight.w700,
                color: CashuranceTheme.deep),
          ),
          const SizedBox(height: 4),
          Text(
            'Track paid, pending, and rejected events with filters.',
            style: GoogleFonts.inter(
              fontSize: 13,
              color: CashuranceTheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 14),
          _SummaryCard(state: widget.state),
          const SizedBox(height: 12),
          CashuranceCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  onChanged: (value) => setState(() => _query = value),
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.search_rounded),
                    labelText: 'Search event type, reason, or ID',
                  ),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _statusChip('All', null),
                    _statusChip('Paid', PayoutStatus.paid),
                    _statusChip('Pending', PayoutStatus.pending),
                    _statusChip('Rejected', PayoutStatus.rejected),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          if (rows.isEmpty)
            const _EmptyState()
          else
            ...rows.map(
              (row) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _PayoutRow(record: row),
              ),
            ),
        ],
      ),
    );
  }

  Widget _statusChip(String label, PayoutStatus? status) {
    return ChoiceChip(
      label: Text(label),
      selected: _status == status,
      onSelected: (_) => setState(() => _status = status),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.state});

  final AppState state;

  @override
  Widget build(BuildContext context) {
    final rows = state.payoutHistory;
    return CashuranceCard(
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: CashuranceTheme.ice.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.shield_outlined,
              color: CashuranceTheme.teal,
              size: 24,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Monthly Protected Amount',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: CashuranceTheme.onSurfaceVariant,
                  ),
                ),
                Text(
                  'INR ${state.monthlyProtectedAmount.toStringAsFixed(0)}',
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 26,
                    fontWeight: FontWeight.w700,
                    color: CashuranceTheme.teal,
                  ),
                ),
                Text(
                  '${rows.where((r) => r.status == PayoutStatus.paid).length} paid · ${rows.where((r) => r.status == PayoutStatus.pending).length} pending · ${rows.where((r) => r.status == PayoutStatus.rejected).length} rejected',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: CashuranceTheme.onSurfaceVariant,
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

class _PayoutRow extends StatelessWidget {
  const _PayoutRow({required this.record});

  final PayoutRecord record;

  Color get _statusColor {
    switch (record.status) {
      case PayoutStatus.paid:
        return CashuranceTheme.successGreen;
      case PayoutStatus.pending:
        return CashuranceTheme.warningOrange;
      case PayoutStatus.rejected:
        return CashuranceTheme.rejectRed;
    }
  }

  Color get _statusBg {
    switch (record.status) {
      case PayoutStatus.paid:
        return CashuranceTheme.successBg;
      case PayoutStatus.pending:
        return CashuranceTheme.warningBg;
      case PayoutStatus.rejected:
        return CashuranceTheme.rejectBg;
    }
  }

  @override
  Widget build(BuildContext context) {
    return CashuranceCard(
      padding: EdgeInsets.zero,
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        shape: const Border(),
        title: Text(
          record.eventType,
          style: GoogleFonts.spaceGrotesk(
            fontWeight: FontWeight.w700,
            fontSize: 14,
            color: CashuranceTheme.deep,
          ),
        ),
        subtitle: Text(
          '${record.eventDate.day}/${record.eventDate.month}/${record.eventDate.year} · ${record.eventId}',
          style: GoogleFonts.inter(
            fontSize: 12,
            color: CashuranceTheme.onSurfaceVariant,
          ),
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: _statusBg,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Text(
            record.statusLabel,
            style: GoogleFonts.spaceGrotesk(
              fontWeight: FontWeight.w700,
              fontSize: 11,
              color: _statusColor,
            ),
          ),
        ),
        children: [
          Divider(
              height: 1,
              color: CashuranceTheme.sage.withValues(alpha: 0.2)),
          const SizedBox(height: 12),
          _expandedRow('Trigger Reason', record.triggerReason),
          const SizedBox(height: 6),
          _expandedRow('Data Source', record.dataSource),
          const SizedBox(height: 6),
          _expandedRow('Amount', 'INR ${record.amount.toStringAsFixed(0)}'),
        ],
      ),
    );
  }

  Widget _expandedRow(String key, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 100,
          child: Text(
            key,
            style: GoogleFonts.inter(
              fontSize: 11,
              color: CashuranceTheme.onSurfaceVariant,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: CashuranceTheme.deep),
          ),
        ),
      ],
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return CashuranceCard(
      child: Column(
        children: [
          const SizedBox(height: 20),
          const Icon(Icons.inbox_outlined,
              size: 44, color: CashuranceTheme.sage),
          const SizedBox(height: 12),
          Text(
            'No payout records found',
            style: GoogleFonts.spaceGrotesk(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: CashuranceTheme.deep),
          ),
          const SizedBox(height: 6),
          Text(
            'Try clearing filters or check again after a new trigger event.',
            style: GoogleFonts.inter(
              fontSize: 13,
              color: CashuranceTheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}
