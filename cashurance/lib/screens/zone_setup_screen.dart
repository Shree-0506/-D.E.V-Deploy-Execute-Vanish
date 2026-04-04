import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../theme.dart';
import '../services/reverse_geocoding_service.dart';

class ZoneSetupScreen extends StatefulWidget {
  const ZoneSetupScreen({
    super.key,
    required this.initialZoneName,
    required this.onConfirmZone,
  });

  final String initialZoneName;
  final Future<bool> Function(String zone, double latitude, double longitude)
      onConfirmZone;

  @override
  State<ZoneSetupScreen> createState() => _ZoneSetupScreenState();
}

class _ZoneSetupScreenState extends State<ZoneSetupScreen> {
  final _mapCtrl = MapController();
  final _zoneCtrl = TextEditingController();
  LatLng? _selectedPoint;
  bool _isConfirming = false;

  @override
  void initState() {
    super.initState();
    _zoneCtrl.text = widget.initialZoneName;
  }

  @override
  void dispose() {
    _zoneCtrl.dispose();
    super.dispose();
  }

  Future<void> _selectPoint(LatLng point) async {
    setState(() => _selectedPoint = point);
    final label = await ReverseGeocodingService.reverseLookup(
      latitude: point.latitude,
      longitude: point.longitude,
    );
    if (!mounted) return;
    if (label != null && label.trim().isNotEmpty) {
      setState(() => _zoneCtrl.text = label);
    }
  }

  Future<void> _confirm() async {
    if (_selectedPoint == null || _zoneCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a location on the map.')),
      );
      return;
    }
    setState(() => _isConfirming = true);
    final ok = await widget.onConfirmZone(
      _zoneCtrl.text.trim(),
      _selectedPoint!.latitude,
      _selectedPoint!.longitude,
    );
    if (!mounted) return;
    setState(() => _isConfirming = false);
    if (!ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to confirm zone.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: Stack(
            children: [
              FlutterMap(
                mapController: _mapCtrl,
                options: MapOptions(
                  initialCenter: const LatLng(12.9716, 77.5946),
                  initialZoom: 11,
                  onTap: (_, point) => _selectPoint(point),
                ),
                children: [
                  TileLayer(
                    urlTemplate:
                        'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.cashurance.app',
                  ),
                  if (_selectedPoint != null)
                    MarkerLayer(
                      markers: [
                        Marker(
                          point: _selectedPoint!,
                          width: 48,
                          height: 48,
                          child: const Icon(
                            Icons.location_on,
                            color: CashuranceTheme.teal,
                            size: 42,
                          ),
                        ),
                      ],
                    ),
                ],
              ),
              Positioned(
                top: 12,
                left: 16,
                right: 16,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: CashuranceTheme.deep.withValues(alpha: 0.08),
                        blurRadius: 16,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.map_outlined,
                          color: CashuranceTheme.teal, size: 22),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Select Your Delivery Zone',
                              style: GoogleFonts.spaceGrotesk(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: CashuranceTheme.deep,
                              ),
                            ),
                            Text(
                              'Tap anywhere on the map to place your pin.',
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
                ),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border(
              top: BorderSide(
                  color: CashuranceTheme.sage.withValues(alpha: 0.2)),
            ),
          ),
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: _zoneCtrl,
                  style: GoogleFonts.inter(
                      fontSize: 14, color: CashuranceTheme.deep),
                  decoration: InputDecoration(
                    labelText: 'Zone Label',
                    labelStyle: GoogleFonts.spaceGrotesk(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: CashuranceTheme.sage,
                    ),
                    filled: true,
                    fillColor: CashuranceTheme.surfaceContainerLow,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(
                          color: CashuranceTheme.teal, width: 1.5),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 14),
                  ),
                ),
                if (_selectedPoint != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    '${_selectedPoint!.latitude.toStringAsFixed(5)}, ${_selectedPoint!.longitude.toStringAsFixed(5)}',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      color: CashuranceTheme.onSurfaceVariant,
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: _isConfirming ? null : _confirm,
                    child: Text(
                        _isConfirming ? 'Confirming...' : 'Confirm Zone'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
