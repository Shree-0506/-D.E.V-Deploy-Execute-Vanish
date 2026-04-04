import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_state.dart';
import 'theme.dart';
import 'services/auth_session.dart';
import 'screens/home_screen.dart';
import 'screens/zone_setup_screen.dart';
import 'screens/policy_purchase_screen.dart';
import 'screens/trigger_alerts_screen.dart';
import 'screens/payout_history_screen.dart';
import 'screens/profile_screen.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key, this.firstTimeSetup = false});

  final bool firstTimeSetup;

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  late final AppState _state;
  int _selectedTab = 0;

  static const _tabLabels = [
    'Home',
    'Buy Policy',
    'Alerts',
    'History',
    'Profile',
  ];
  static const _tabIcons = [
    Icons.home_outlined,
    Icons.add_card_outlined,
    Icons.warning_amber_outlined,
    Icons.timeline_outlined,
    Icons.person_outline,
  ];
  static const _tabActiveIcons = [
    Icons.home_rounded,
    Icons.add_card_rounded,
    Icons.warning_amber_rounded,
    Icons.timeline_rounded,
    Icons.person_rounded,
  ];

  @override
  void initState() {
    super.initState();
    _state = AppState();
    if (widget.firstTimeSetup) {
      _state.zoneConfirmed = false;
    }
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    if (!AuthSession.instance.isAuthenticated) {
      if (!mounted) return;
      Navigator.pushReplacementNamed(context, '/login');
      return;
    }
    await _state.loadFromBackend();
  }

  void _goToTab(int index) => setState(() => _selectedTab = index);

  bool get _needsZoneSetup => widget.firstTimeSetup && !_state.zoneConfirmed;

  Widget _buildBody() {
    if (_needsZoneSetup) {
      return ZoneSetupScreen(
        initialZoneName: _state.profile.zoneName,
        onConfirmZone: (zone, latitude, longitude) async {
          final ok = await _state.confirmZone(
            zone,
            latitude: latitude,
            longitude: longitude,
          );
          if (!ok && mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content:
                    Text('Failed to confirm zone. Backend may be unavailable.'),
              ),
            );
          }
          return ok;
        },
      );
    }
    switch (_selectedTab) {
      case 0:
        return HomeScreen(
          state: _state,
          onBuyPolicy: () => _goToTab(1),
          onOpenAlerts: () => _goToTab(2),
          onOpenHistory: () => _goToTab(3),
          onOpenProfile: () => _goToTab(4),
        );
      case 1:
        return PolicyPurchaseScreen(
          state: _state,
          onPurchased: () => _goToTab(0),
        );
      case 2:
        return TriggerAlertsScreen(state: _state);
      case 3:
        return PayoutHistoryScreen(state: _state);
      case 4:
        return ProfileScreen(
          state: _state,
          onLogout: () {
            AuthSession.instance.clear();
            Navigator.pushReplacementNamed(context, '/login');
          },
        );
      default:
        return const SizedBox.shrink();
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _state,
      builder: (context, _) {
        if (_state.isLoading) {
          return Scaffold(
            backgroundColor: CashuranceTheme.surface,
            body: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: 48,
                    height: 48,
                    child: CircularProgressIndicator(
                      strokeWidth: 3,
                      color: CashuranceTheme.teal,
                      backgroundColor:
                          CashuranceTheme.ice.withValues(alpha: 0.3),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Loading...',
                    style: GoogleFonts.inter(
                      color: CashuranceTheme.sage,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        if (_state.loadError != null) {
          return Scaffold(
            backgroundColor: CashuranceTheme.surface,
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.cloud_off_rounded,
                        size: 44, color: CashuranceTheme.sage),
                    const SizedBox(height: 12),
                    Text(
                      _state.loadError!,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(
                          color: CashuranceTheme.onSurfaceVariant),
                    ),
                    const SizedBox(height: 12),
                    FilledButton(
                      onPressed: _bootstrap,
                      child: const Text('Retry'),
                    ),
                    const SizedBox(height: 8),
                    OutlinedButton(
                      onPressed: () {
                        AuthSession.instance.clear();
                        Navigator.pushReplacementNamed(context, '/login');
                      },
                      child: const Text('Back to Login'),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        return Scaffold(
          appBar: AppBar(
            backgroundColor: CashuranceTheme.surfaceContainerLowest,
            elevation: 0,
            scrolledUnderElevation: 1,
            title: Row(
              children: [
                Image.asset('assets/logo.png',
                    width: 24, height: 24, color: CashuranceTheme.teal),
                const SizedBox(width: 8),
                Text(
                  'CashUrance',
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: CashuranceTheme.deep,
                  ),
                ),
              ],
            ),
            actions: [
              if (!_needsZoneSetup)
                Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: CashuranceTheme.ice.withValues(alpha: 0.4),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                            color: CashuranceTheme.outlineVariant),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.location_on_outlined,
                            size: 12,
                            color: CashuranceTheme.teal,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _state.profile.zoneName.split(',').first,
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: CashuranceTheme.deep,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
          body: AnimatedSwitcher(
            duration: const Duration(milliseconds: 220),
            child: KeyedSubtree(
              key: ValueKey(_needsZoneSetup ? 'zone' : 'tab_$_selectedTab'),
              child: _buildBody(),
            ),
          ),
          bottomNavigationBar: _needsZoneSetup
              ? null
              : NavigationBar(
                  selectedIndex: _selectedTab,
                  onDestinationSelected: _goToTab,
                  destinations: List.generate(
                    _tabLabels.length,
                    (i) => NavigationDestination(
                      icon: Icon(_tabIcons[i]),
                      selectedIcon: Icon(_tabActiveIcons[i]),
                      label: _tabLabels[i],
                    ),
                  ),
                ),
        );
      },
    );
  }
}
