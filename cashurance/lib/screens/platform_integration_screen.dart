import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme.dart';
import '../widgets/progress_footer.dart';
import '../services/api_service.dart';
import '../services/registration_draft.dart';

class PlatformIntegrationScreen extends StatefulWidget {
  const PlatformIntegrationScreen({super.key});

  @override
  State<PlatformIntegrationScreen> createState() =>
      _PlatformIntegrationScreenState();
}

class _PlatformIntegrationScreenState extends State<PlatformIntegrationScreen> {
  final _workerIdCtrl = TextEditingController();
  bool _submitting = false;

  @override
  void dispose() {
    _workerIdCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final draft = RegistrationDraft.instance;
    final fullName = draft.fullName?.trim() ?? '';
    final phone = draft.phone?.trim() ?? '';
    final password = draft.password ?? '';
    final workerId = _workerIdCtrl.text.trim();

    if (fullName.isEmpty || phone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please complete personal details before submitting.'),
        ),
      );
      return;
    }
    if (workerId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Partner / Worker ID is required.')),
      );
      return;
    }
    if (password.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Password from Step 1 is missing or invalid.')),
      );
      return;
    }

    setState(() => _submitting = true);
    try {
      await ApiService.register(
        fullName: fullName,
        phone: phone,
        password: password,
        platform: 'Other',
        upiId: '',
        dob: draft.dob,
        address: draft.address,
        pincode: draft.pincode,
        platformWorkerId: workerId,
      );

      if (!mounted) return;
      showDialog(
        context: context,
        barrierDismissible: false,
        barrierColor: CashuranceTheme.deep.withValues(alpha: 0.6),
        builder: (ctx) => _SuccessDialog(
          onDone: () {
            RegistrationDraft.instance.clear();
            Navigator.of(ctx).pop();
            Navigator.of(context)
                .pushNamedAndRemoveUntil('/login', (_) => false);
          },
        ),
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message)),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Registration failed. Please try again.')),
      );
    } finally {
      if (mounted) {
        setState(() => _submitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CashuranceTheme.surface,
      appBar: AppBar(
        backgroundColor: CashuranceTheme.surface,
        elevation: 0,
        leading: const BackButton(color: CashuranceTheme.deep),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset('assets/logo.png',
                width: 22, height: 22, color: CashuranceTheme.deep),
            const SizedBox(width: 8),
            Text(
              'CASHURANCE',
              style: GoogleFonts.spaceGrotesk(
                fontWeight: FontWeight.w700,
                fontSize: 14,
                letterSpacing: 2,
                color: CashuranceTheme.deep,
              ),
            ),
          ],
        ),
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth > 720;
          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 600),
              child: SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(
                    isWide ? 48 : 24, 32, isWide ? 48 : 24, 100),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        border:
                            Border.all(color: CashuranceTheme.outlineVariant),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        'STEP 03',
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 1,
                          color: CashuranceTheme.teal,
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                    Text(
                      'Platform\nIntegration',
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 40,
                        fontWeight: FontWeight.w600,
                        height: 1.1,
                        letterSpacing: -1.5,
                        color: CashuranceTheme.deep,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Add your partner worker ID to finish account setup.',
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        height: 1.6,
                        color: CashuranceTheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 48),
                    _Field(
                        label: 'Partner / Worker ID',
                        placeholder: 'Your platform ID',
                        controller: _workerIdCtrl),
                    const SizedBox(height: 48),
                    _SubmitButton(
                      onPressed: _submitting ? () {} : _submit,
                      label: _submitting
                          ? 'Submitting...'
                          : 'Complete Registration',
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
      bottomNavigationBar: const ProgressFooter(currentStep: 3),
    );
  }
}

class _Field extends StatelessWidget {
  final String label;
  final String placeholder;
  final TextEditingController controller;
  const _Field({
    required this.label,
    required this.placeholder,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label.toUpperCase(),
          style: GoogleFonts.spaceGrotesk(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              letterSpacing: 1,
              color: CashuranceTheme.sage)),
      const SizedBox(height: 8),
      TextField(
        controller: controller,
        style: GoogleFonts.inter(fontSize: 15, color: CashuranceTheme.deep),
        decoration: InputDecoration(
          hintText: placeholder,
          filled: true,
          fillColor: Colors.transparent,
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(
                  color: CashuranceTheme.sage.withValues(alpha: 0.4))),
          enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(
                  color: CashuranceTheme.sage.withValues(alpha: 0.4))),
          focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide:
                  const BorderSide(color: CashuranceTheme.teal, width: 1.5)),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          hintStyle: GoogleFonts.inter(
              color: CashuranceTheme.sage.withValues(alpha: 0.6), fontSize: 15),
        ),
      ),
    ]);
  }
}

class _SubmitButton extends StatefulWidget {
  final VoidCallback onPressed;
  final String label;
  const _SubmitButton({required this.onPressed, required this.label});

  @override
  State<_SubmitButton> createState() => _SubmitButtonState();
}

class _SubmitButtonState extends State<_SubmitButton> {
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
        opacity: _pressed ? 0.7 : 1.0,
        duration: const Duration(milliseconds: 100),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [CashuranceTheme.teal, Color(0xFF3D6A70)],
            ),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: CashuranceTheme.teal.withValues(alpha: 0.3),
                blurRadius: 14,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Center(
            child: Text(
              widget.label,
              style: GoogleFonts.spaceGrotesk(
                color: Colors.white,
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

class _SuccessDialog extends StatelessWidget {
  final VoidCallback onDone;
  const _SuccessDialog({required this.onDone});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 400),
        child: Padding(
          padding: const EdgeInsets.all(40),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: CashuranceTheme.ice,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.check_rounded,
                    color: CashuranceTheme.teal, size: 32),
              ),
              const SizedBox(height: 32),
              Text(
                'Registration\nComplete.',
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 32,
                  fontWeight: FontWeight.w600,
                  height: 1.1,
                  letterSpacing: -1,
                  color: CashuranceTheme.deep,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Your account is now active. You will receive a verification SMS shortly.',
                style: GoogleFonts.inter(
                  fontSize: 15,
                  height: 1.6,
                  color: CashuranceTheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 48),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: onDone,
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    side: const BorderSide(
                        color: CashuranceTheme.teal, width: 1.5),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text(
                    'Go to Dashboard',
                    style: GoogleFonts.spaceGrotesk(
                      color: CashuranceTheme.teal,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
