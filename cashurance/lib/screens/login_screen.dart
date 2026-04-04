import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:geolocator/geolocator.dart';
import '../theme.dart';
import '../services/api_service.dart';
import '../services/auth_session.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _phoneCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;
  bool _backendAvailable = false;
  String? _error;

  Future<Position?> _getLoginLocation() async {
    try {
      final enabled = await Geolocator.isLocationServiceEnabled();
      if (!enabled) return null;
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return null;
      }
      final first = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.best,
          distanceFilter: 0,
          timeLimit: Duration(seconds: 15),
        ),
      );
      if (kIsWeb && first.accuracy > 3000) {
        try {
          final second = await Geolocator.getCurrentPosition(
            locationSettings: const LocationSettings(
              accuracy: LocationAccuracy.bestForNavigation,
              distanceFilter: 0,
              timeLimit: Duration(seconds: 20),
            ),
          );
          return second.accuracy <= first.accuracy ? second : first;
        } catch (_) {
          return first;
        }
      }
      return first;
    } catch (_) {
      return null;
    }
  }

  @override
  void initState() {
    super.initState();
    _checkBackend();
  }

  @override
  void dispose() {
    _phoneCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _checkBackend() async {
    try {
      await ApiService.healthCheck();
      if (!mounted) return;
      setState(() => _backendAvailable = true);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _backendAvailable = false;
        _error = 'Backend is offline. Start backend server first.';
      });
    }
  }

  Future<void> _login() async {
    final phone = _phoneCtrl.text.trim();
    if (!RegExp(r'^\d{10}$').hasMatch(phone)) {
      setState(() => _error = 'Phone number must be exactly 10 digits.');
      return;
    }
    if (!_backendAvailable) {
      setState(
          () => _error = 'Backend is offline. Start backend server first.');
      return;
    }
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final position = await _getLoginLocation();
      final data = await ApiService.login(
        phone: phone,
        password: _passwordCtrl.text,
        latitude: position?.latitude,
        longitude: position?.longitude,
      );
      AuthSession.instance.setSession(
        token: data['token'] as String,
        workerId: data['worker_id'] as int,
        fullName: (data['full_name'] ?? '').toString(),
        phone: (data['phone'] ?? '').toString(),
        firstTimeSetup: data['first_time_setup'] == true,
      );
      if (!mounted) return;
      Navigator.pushReplacementNamed(context, '/app');
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _error = e.message);
    } catch (_) {
      if (!mounted) return;
      setState(() => _error = 'Login failed. Please try again.');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth > 720;
          return isWide
              ? _buildWideLayout(context)
              : _buildNarrowLayout(context);
        },
      ),
    );
  }

  Widget _buildWideLayout(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [CashuranceTheme.deep, Color(0xFF163E44)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: _buildBrandPanel(),
          ),
        ),
        Expanded(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: SingleChildScrollView(
                padding:
                    const EdgeInsets.symmetric(horizontal: 48, vertical: 64),
                child: _buildForm(context),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNarrowLayout(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [CashuranceTheme.deep, Color(0xFF163E44)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(24, 64, 24, 40),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Image.asset('assets/logo.png',
                        width: 42, height: 42, color: Colors.white),
                    const SizedBox(width: 12),
                    Text(
                      'CASHURANCE',
                      style: GoogleFonts.spaceGrotesk(
                        fontWeight: FontWeight.w700,
                        fontSize: 17,
                        letterSpacing: 2,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),
                Text(
                  'Welcome\nback.',
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 40,
                    fontWeight: FontWeight.w600,
                    height: 1.1,
                    letterSpacing: -1.5,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Your income, protected.',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: CashuranceTheme.sage,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 40, 24, 48),
            child: _buildForm(context),
          ),
        ],
      ),
    );
  }

  Widget _buildBrandPanel() {
    return Padding(
      padding: const EdgeInsets.all(64),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Image.asset('assets/logo.png',
                  width: 52, height: 52, color: Colors.white),
              const SizedBox(width: 14),
              Text(
                'CASHURANCE',
                style: GoogleFonts.spaceGrotesk(
                  fontWeight: FontWeight.w700,
                  fontSize: 20,
                  letterSpacing: 2.5,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const Spacer(),
          Text(
            'Welcome\nback.',
            style: GoogleFonts.spaceGrotesk(
              fontSize: 64,
              fontWeight: FontWeight.w600,
              height: 1.05,
              letterSpacing: -3,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Your income, protected.',
            style: GoogleFonts.inter(
              fontSize: 16,
              height: 1.6,
              color: CashuranceTheme.sage,
            ),
          ),
          const Spacer(),
          Row(
            children: [
              _BrandStat(value: '24k+', label: 'Partners'),
              const SizedBox(width: 40),
              _BrandStat(value: '4 min', label: 'Avg. Payout'),
              const SizedBox(width: 40),
              _BrandStat(value: '99.9%', label: 'Settled'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildForm(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Sign in',
          style: GoogleFonts.spaceGrotesk(
            fontSize: 32,
            fontWeight: FontWeight.w600,
            letterSpacing: -1,
            color: CashuranceTheme.deep,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 4,
          runSpacing: 4,
          children: [
            Text(
              'No account? ',
              style: GoogleFonts.inter(
                fontSize: 14,
                color: CashuranceTheme.sage,
              ),
            ),
            GestureDetector(
              onTap: () => Navigator.pushNamed(context, '/personal'),
              child: Text(
                'Register now',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: CashuranceTheme.teal,
                  decoration: TextDecoration.underline,
                  decorationColor: CashuranceTheme.teal,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Icon(
              _backendAvailable ? Icons.cloud_done : Icons.cloud_off,
              size: 14,
              color: _backendAvailable
                  ? CashuranceTheme.successGreen
                  : CashuranceTheme.rejectRed,
            ),
            const SizedBox(width: 6),
            Text(
              _backendAvailable
                  ? 'Backend connected'
                  : 'Backend disconnected',
              style: GoogleFonts.inter(
                fontSize: 12,
                color: _backendAvailable
                    ? CashuranceTheme.successGreen
                    : CashuranceTheme.rejectRed,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 48),

        // Phone Field
        _MinimalField(
          label: 'Phone Number',
          placeholder: '9876543210',
          controller: _phoneCtrl,
          keyboardType: TextInputType.phone,
          prefixText: '+91 ',
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(10),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          'Test login: phone 9999999999  |  pass abcdef (No location restriction)',
          style: GoogleFonts.inter(
            fontSize: 12,
            color: CashuranceTheme.sage,
          ),
        ),
        const SizedBox(height: 24),

        // Password Field
        _MinimalField(
          label: 'Password / OTP',
          placeholder: '••••••',
          controller: _passwordCtrl,
          obscureText: _obscurePassword,
          suffixIcon: GestureDetector(
            onTap: () => setState(() => _obscurePassword = !_obscurePassword),
            child: Icon(
              _obscurePassword
                  ? Icons.visibility_off_outlined
                  : Icons.visibility_outlined,
              size: 18,
              color: CashuranceTheme.sage,
            ),
          ),
        ),
        const SizedBox(height: 12),

        Align(
          alignment: Alignment.centerRight,
          child: Text(
            'Forgot password?',
            style: GoogleFonts.inter(
              fontSize: 13,
              color: CashuranceTheme.sage,
              decoration: TextDecoration.underline,
              decorationColor: CashuranceTheme.sage,
            ),
          ),
        ),
        const SizedBox(height: 48),

        if (_error != null) ...[
          Text(
            _error!,
            style: GoogleFonts.inter(
              fontSize: 12,
              color: CashuranceTheme.rejectRed,
            ),
          ),
          const SizedBox(height: 12),
        ],

        // Sign in button
        _LoginButton(
          isLoading: _isLoading,
          enabled: _backendAvailable,
          onPressed: () {
            _login();
          },
        ),
        const SizedBox(height: 24),

        // Divider
        Row(
          children: [
            Expanded(
                child: Divider(
                    color: CashuranceTheme.sage.withValues(alpha: 0.3))),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'or',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: CashuranceTheme.sage,
                ),
              ),
            ),
            Expanded(
                child: Divider(
                    color: CashuranceTheme.sage.withValues(alpha: 0.3))),
          ],
        ),
        const SizedBox(height: 24),

        // OTP Sign in
        _OutlineButton(
          label: 'Continue with OTP',
          onPressed: () {},
        ),
        const SizedBox(height: 48),

        Center(
          child: Text(
            'For delivery partners only.\nCashUrance © 2026',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 12,
              color: CashuranceTheme.sage.withValues(alpha: 0.6),
              height: 1.6,
            ),
          ),
        ),
      ],
    );
  }
}

// ─── Sub-Components ──────────────────────────────────────────────────────────

class _BrandStat extends StatelessWidget {
  final String value;
  final String label;
  const _BrandStat({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          style: GoogleFonts.spaceGrotesk(
            fontSize: 22,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.5,
            color: CashuranceTheme.ice,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label.toUpperCase(),
          style: GoogleFonts.spaceGrotesk(
            fontSize: 9,
            fontWeight: FontWeight.w600,
            letterSpacing: 1.5,
            color: CashuranceTheme.sage,
          ),
        ),
      ],
    );
  }
}

class _MinimalField extends StatelessWidget {
  final String label;
  final String placeholder;
  final TextEditingController controller;
  final TextInputType? keyboardType;
  final bool obscureText;
  final String? prefixText;
  final Widget? suffixIcon;
  final List<TextInputFormatter>? inputFormatters;

  const _MinimalField({
    required this.label,
    required this.placeholder,
    required this.controller,
    this.keyboardType,
    this.obscureText = false,
    this.prefixText,
    this.suffixIcon,
    this.inputFormatters,
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
          obscureText: obscureText,
          inputFormatters: inputFormatters,
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
            ),
            suffixIcon: suffixIcon != null
                ? Padding(
                    padding: const EdgeInsets.only(right: 16),
                    child: suffixIcon,
                  )
                : null,
            suffixIconConstraints:
                const BoxConstraints(minWidth: 0, minHeight: 0),
            filled: true,
            fillColor: Colors.transparent,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(
                  color: CashuranceTheme.sage.withValues(alpha: 0.4)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(
                  color: CashuranceTheme.sage.withValues(alpha: 0.4)),
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

class _LoginButton extends StatelessWidget {
  final bool isLoading;
  final bool enabled;
  final VoidCallback onPressed;
  const _LoginButton({
    required this.isLoading,
    required this.enabled,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isLoading || !enabled ? null : onPressed,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          gradient: isLoading || !enabled
              ? null
              : const LinearGradient(
                  colors: [CashuranceTheme.teal, Color(0xFF3D6A70)],
                ),
          color: isLoading || !enabled ? CashuranceTheme.sage : null,
          borderRadius: BorderRadius.circular(12),
          boxShadow: isLoading || !enabled
              ? null
              : [
                  BoxShadow(
                    color: CashuranceTheme.teal.withValues(alpha: 0.3),
                    blurRadius: 14,
                    offset: const Offset(0, 4),
                  ),
                ],
        ),
        child: Center(
          child: isLoading
              ? const SizedBox(
                  height: 18,
                  width: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : Text(
                  'Sign in',
                  style: GoogleFonts.spaceGrotesk(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                ),
        ),
      ),
    );
  }
}

class _OutlineButton extends StatefulWidget {
  final String label;
  final VoidCallback onPressed;
  const _OutlineButton({required this.label, required this.onPressed});

  @override
  State<_OutlineButton> createState() => _OutlineButtonState();
}

class _OutlineButtonState extends State<_OutlineButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        widget.onPressed();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedOpacity(
        opacity: _pressed ? 0.6 : 1.0,
        duration: const Duration(milliseconds: 100),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 18),
          decoration: BoxDecoration(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
                color: CashuranceTheme.sage.withValues(alpha: 0.4)),
          ),
          child: Center(
            child: Text(
              widget.label,
              style: GoogleFonts.spaceGrotesk(
                color: CashuranceTheme.teal,
                fontWeight: FontWeight.w600,
                fontSize: 15,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
