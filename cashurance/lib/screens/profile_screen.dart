import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../theme.dart';
import '../app_state.dart';
import '../models.dart';
import '../services/reverse_geocoding_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({
    super.key,
    required this.state,
    required this.onLogout,
  });

  final AppState state;
  final VoidCallback onLogout;

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _editing = false;
  bool _saving = false;
  late final TextEditingController _nameController;
  late final TextEditingController _platformController;
  late final TextEditingController _upiController;

  @override
  void initState() {
    super.initState();
    final profile = widget.state.profile;
    _nameController = TextEditingController(text: profile.name);
    _platformController = TextEditingController(text: profile.platform);
    _upiController = TextEditingController(text: profile.upiId);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _platformController.dispose();
    _upiController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    final fullName = _nameController.text.trim();
    final platform = _platformController.text.trim();
    final upiId = _upiController.text.trim();

    if (fullName.isEmpty || platform.isEmpty || upiId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Name, platform, and UPI ID are required.')),
      );
      return;
    }

    setState(() => _saving = true);
    final ok = await widget.state.updateProfile(
      fullName: fullName,
      platform: platform,
      upiId: upiId,
    );
    setState(() {
      _saving = false;
      if (ok) {
        _editing = false;
      }
    });

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
          content:
              Text(ok ? 'Profile updated.' : 'Failed to update profile.')),
    );
  }

  Future<void> _updatePrefs(NotificationPreferences next) async {
    final ok = await widget.state.updateNotificationPreferences(next);
    if (!mounted) return;
    if (!ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Failed to save notification settings.')),
      );
    }
  }

  Future<void> _changeLocation() async {
    final profile = widget.state.profile;
    final zoneController = TextEditingController(text: profile.zoneName);
    final latController =
        TextEditingController(text: profile.latitude.toStringAsFixed(6));
    final lonController =
        TextEditingController(text: profile.longitude.toStringAsFixed(6));
    final mapController = MapController();
    LatLng selectedPoint = LatLng(profile.latitude, profile.longitude);

    final confirmed = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              margin: const EdgeInsets.only(top: 80),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Padding(
                padding: EdgeInsets.only(
                  left: 20,
                  right: 20,
                  top: 20,
                  bottom: 20 + MediaQuery.of(context).viewInsets.bottom,
                ),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Container(
                          width: 48,
                          height: 4,
                          decoration: BoxDecoration(
                            color: CashuranceTheme.outlineVariant,
                            borderRadius: BorderRadius.circular(99),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'Reset Location',
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: CashuranceTheme.deep,
                        ),
                      ),
                      const SizedBox(height: 14),
                      SizedBox(
                        height: 260,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(14),
                          child: FlutterMap(
                            mapController: mapController,
                            options: MapOptions(
                              initialCenter: selectedPoint,
                              initialZoom: 12,
                              onTap: (_, point) {
                                () async {
                                  setModalState(() {
                                    selectedPoint = point;
                                    latController.text =
                                        point.latitude.toStringAsFixed(6);
                                    lonController.text =
                                        point.longitude.toStringAsFixed(6);
                                  });
                                  final label = await ReverseGeocodingService
                                      .reverseLookup(
                                    latitude: point.latitude,
                                    longitude: point.longitude,
                                  );
                                  if (!context.mounted) return;
                                  if (label != null &&
                                      label.trim().isNotEmpty) {
                                    setModalState(() {
                                      zoneController.text = label;
                                    });
                                  }
                                }();
                              },
                            ),
                            children: [
                              TileLayer(
                                urlTemplate:
                                    'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                                userAgentPackageName: 'com.cashurance.app',
                              ),
                              MarkerLayer(
                                markers: [
                                  Marker(
                                    point: selectedPoint,
                                    width: 42,
                                    height: 42,
                                    child: const Icon(
                                      Icons.location_on,
                                      color: CashuranceTheme.teal,
                                      size: 36,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      TextField(
                        controller: zoneController,
                        decoration:
                            const InputDecoration(labelText: 'Zone Label'),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: latController,
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                decimal: true,
                                signed: true,
                              ),
                              decoration: const InputDecoration(
                                  labelText: 'Latitude'),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: TextField(
                              controller: lonController,
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                decimal: true,
                                signed: true,
                              ),
                              decoration: const InputDecoration(
                                  labelText: 'Longitude'),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () =>
                                  Navigator.pop(context, false),
                              child: const Text('Cancel'),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: FilledButton(
                              onPressed: () =>
                                  Navigator.pop(context, true),
                              child: const Text('Confirm Location'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );

    if (confirmed != true) {
      zoneController.dispose();
      latController.dispose();
      lonController.dispose();
      return;
    }

    final zone = zoneController.text.trim();
    final latitude = double.tryParse(latController.text.trim());
    final longitude = double.tryParse(lonController.text.trim());
    zoneController.dispose();
    latController.dispose();
    lonController.dispose();

    if (zone.isEmpty || latitude == null || longitude == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter valid location values.')),
      );
      return;
    }

    final error = await widget.state.updateLocation(
      zoneName: zone,
      latitude: latitude,
      longitude: longitude,
    );
    if (!mounted) return;
    final success = error == null;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(success ? 'Location updated.' : error)),
    );

    if (!success &&
        (error.contains('Invalid or expired session') ||
            error.contains('No active session'))) {
      widget.onLogout();
    }
  }

  @override
  Widget build(BuildContext context) {
    final profile = widget.state.profile;
    final policy = widget.state.activePolicy;
    final prefs = widget.state.notificationPreferences;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
      children: [
        // ── Avatar Card ────────────────────────────────────────────────
        CashuranceCard(
          child: Row(
            children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: CashuranceTheme.ice,
                child: Text(
                  profile.name.substring(0, 1).toUpperCase(),
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: CashuranceTheme.teal,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      profile.name,
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: CashuranceTheme.deep,
                      ),
                    ),
                    Text(
                      profile.phone,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: CashuranceTheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: CashuranceTheme.ice.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        profile.platform,
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: CashuranceTheme.teal,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),

        // ── Personal Details ───────────────────────────────────────────
        CashuranceCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const SectionLabel('Personal Details'),
                  TextButton(
                    onPressed: _saving
                        ? null
                        : () {
                            setState(() {
                              _editing = !_editing;
                              if (!_editing) {
                                _nameController.text = profile.name;
                                _platformController.text = profile.platform;
                                _upiController.text = profile.upiId;
                              }
                            });
                          },
                    child: Text(_editing ? 'Cancel' : 'Edit'),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (_editing) ...[
                TextField(
                  controller: _nameController,
                  decoration:
                      const InputDecoration(labelText: 'Full Name'),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _platformController,
                  decoration:
                      const InputDecoration(labelText: 'Platform'),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _upiController,
                  decoration: const InputDecoration(labelText: 'UPI ID'),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: _saving ? null : _saveProfile,
                    child: Text(_saving ? 'Saving...' : 'Save Profile'),
                  ),
                ),
                const SizedBox(height: 8),
              ],
              _kv('Full Name', profile.name),
              _kv('Phone', profile.phone),
              _kv('Platform', profile.platform),
              _kv('Zone', profile.zoneName),
              _kv('Latitude', profile.latitude.toStringAsFixed(6)),
              _kv('Longitude', profile.longitude.toStringAsFixed(6)),
              _kv('UPI ID', profile.upiId),
              _kv('Zone Radius', '${profile.zoneRadius} km'),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _changeLocation,
                  icon:
                      const Icon(Icons.my_location_outlined, size: 16),
                  label: const Text('Change Location (Demo)'),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),

        // ── Active Policy ──────────────────────────────────────────────
        if (policy != null) ...[
          CashuranceCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SectionLabel('Active Policy'),
                const SizedBox(height: 12),
                _kv('Coverage', policy.coverageBadge),
                _kv('Premium Paid',
                    'INR ${policy.premiumPaid.toStringAsFixed(0)}'),
                _kv('Days Remaining', '${policy.daysRemaining}'),
                _kv('Zone', policy.zoneName),
              ],
            ),
          ),
          const SizedBox(height: 14),
        ],

        // ── Policy History ─────────────────────────────────────────────
        CashuranceCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SectionLabel('Policy History'),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _statCard(
                      '${profile.policiesPurchased}',
                      'Policies Purchased',
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _statCard(
                      '${profile.payoutsSettled}',
                      'Payouts Settled',
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _statCard(
                        profile.avgSettlementFormatted, 'Avg Settlement'),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),

        // ── Notifications ──────────────────────────────────────────────
        CashuranceCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SectionLabel('Notifications'),
              const SizedBox(height: 8),
              SwitchListTile.adaptive(
                value: prefs.eventAlerts,
                contentPadding: EdgeInsets.zero,
                activeThumbColor: CashuranceTheme.teal,
                activeTrackColor: CashuranceTheme.ice,
                title: Text(
                  'Live Event Alerts',
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: CashuranceTheme.deep,
                  ),
                ),
                subtitle: Text(
                  'Flood, heat, AQI, traffic triggers',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: CashuranceTheme.onSurfaceVariant,
                  ),
                ),
                onChanged: (v) =>
                    _updatePrefs(prefs.copyWith(eventAlerts: v)),
              ),
              Divider(
                  height: 1,
                  color: CashuranceTheme.sage.withValues(alpha: 0.2)),
              SwitchListTile.adaptive(
                value: prefs.weeklyReminders,
                contentPadding: EdgeInsets.zero,
                activeThumbColor: CashuranceTheme.teal,
                activeTrackColor: CashuranceTheme.ice,
                title: Text(
                  'Weekly Renewal Reminders',
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: CashuranceTheme.deep,
                  ),
                ),
                subtitle: Text(
                  'Every Sunday before cycle starts',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: CashuranceTheme.onSurfaceVariant,
                  ),
                ),
                onChanged: (v) =>
                    _updatePrefs(prefs.copyWith(weeklyReminders: v)),
              ),
              Divider(
                  height: 1,
                  color: CashuranceTheme.sage.withValues(alpha: 0.2)),
              SwitchListTile.adaptive(
                value: prefs.payoutNotifs,
                contentPadding: EdgeInsets.zero,
                activeThumbColor: CashuranceTheme.teal,
                activeTrackColor: CashuranceTheme.ice,
                title: Text(
                  'Payout Confirmations',
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: CashuranceTheme.deep,
                  ),
                ),
                subtitle: Text(
                  'UPI credit confirmation alerts',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: CashuranceTheme.onSurfaceVariant,
                  ),
                ),
                onChanged: (v) =>
                    _updatePrefs(prefs.copyWith(payoutNotifs: v)),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),

        // ── Platform Integrity ─────────────────────────────────────────
        CashuranceCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.verified_user_outlined,
                    size: 16,
                    color: CashuranceTheme.teal,
                  ),
                  const SizedBox(width: 6),
                  const SectionLabel('Platform Integrity'),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                'CashUrance uses multi-signal fraud detection: GPS trajectory, app foreground activity, cell tower triangulation, and device fingerprint consistency.',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: CashuranceTheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),

        // ── Logout ─────────────────────────────────────────────────────
        OutlinedButton.icon(
          onPressed: widget.onLogout,
          icon: const Icon(Icons.logout, size: 18),
          label: const Text('Logout'),
        ),
      ],
    );
  }

  Widget _kv(String key, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 100,
            child: Text(
              key,
              style: GoogleFonts.inter(
                fontSize: 12,
                color: CashuranceTheme.onSurfaceVariant,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: CashuranceTheme.deep),
            ),
          ),
        ],
      ),
    );
  }

  Widget _statCard(String value, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: CashuranceTheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: GoogleFonts.spaceGrotesk(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: CashuranceTheme.teal,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            textAlign: TextAlign.center,
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
