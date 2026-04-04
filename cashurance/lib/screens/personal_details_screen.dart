import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme.dart';
import '../widgets/step_input.dart';
import '../widgets/progress_footer.dart';
import '../services/registration_draft.dart';

class PersonalDetailsScreen extends StatefulWidget {
  const PersonalDetailsScreen({super.key});

  @override
  State<PersonalDetailsScreen> createState() => _PersonalDetailsScreenState();
}

class _PersonalDetailsScreenState extends State<PersonalDetailsScreen> {
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _pincodeCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmPasswordCtrl = TextEditingController();
  DateTime? _dob;
  bool _agreed = false;

  void _continue() {
    final name = _nameCtrl.text.trim();
    final phone = _phoneCtrl.text.trim();
    final address = _addressCtrl.text.trim();
    final pincode = _pincodeCtrl.text.trim();
    final password = _passwordCtrl.text;
    final confirmPassword = _confirmPasswordCtrl.text;
    final phoneRegex = RegExp(r'^\d{10}$');
    final pincodeRegex = RegExp(r'^\d{6}$');

    if (name.length < 3) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid full name.')),
      );
      return;
    }
    if (!phoneRegex.hasMatch(phone)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Phone must be exactly 10 digits.')),
      );
      return;
    }
    if (_dob == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select date of birth.')),
      );
      return;
    }
    if (address.length < 8) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid address.')),
      );
      return;
    }
    if (!pincodeRegex.hasMatch(pincode)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pincode must be exactly 6 digits.')),
      );
      return;
    }
    if (password.length < 6 || password != confirmPassword) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content:
              Text('Passwords must match and be at least 6 characters long.'),
        ),
      );
      return;
    }
    if (!_agreed) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please accept terms to continue.')),
      );
      return;
    }

    final draft = RegistrationDraft.instance;
    draft.fullName = name;
    draft.phone = phone;
    draft.address = address;
    draft.pincode = pincode;
    draft.password = password;
    draft.dob = _dob == null
        ? null
        : '${_dob!.year.toString().padLeft(4, '0')}-${_dob!.month.toString().padLeft(2, '0')}-${_dob!.day.toString().padLeft(2, '0')}';

    Navigator.pushNamed(context, '/identity');
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _addressCtrl.dispose();
    _pincodeCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmPasswordCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime(2000),
      firstDate: DateTime(1950),
      lastDate: DateTime.now().subtract(const Duration(days: 365 * 18)),
      builder: (ctx, child) => Theme(
        data: ThemeData.light().copyWith(
          colorScheme: const ColorScheme.light(
            primary: CashuranceTheme.teal,
            onPrimary: Colors.white,
            surface: Colors.white,
            onSurface: CashuranceTheme.deep,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _dob = picked);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CashuranceTheme.surface,
      appBar: _buildAppBar(),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth > 720;
          return isWide
              ? _buildWideLayout(context)
              : _buildNarrowLayout(context);
        },
      ),
      bottomNavigationBar: const ProgressFooter(currentStep: 1),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
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
    );
  }

  Widget _buildWideLayout(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          width: 380,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFFE8F4F6), Color(0xFFF4FAFB)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: _buildSidebar(),
        ),
        Expanded(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 600),
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(48, 64, 48, 100),
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
      padding: const EdgeInsets.fromLTRB(24, 32, 24, 100),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildFormHeader(),
          const SizedBox(height: 48),
          _buildFormFields(context),
        ],
      ),
    );
  }

  Widget _buildSidebar() {
    return Padding(
      padding: const EdgeInsets.all(48),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              border: Border.all(color: CashuranceTheme.outlineVariant),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              'STEP 01',
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
            'Personal\nInformation',
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
            'We need some official details to verify your identity against national records.',
            style: GoogleFonts.inter(
              fontSize: 15,
              height: 1.6,
              color: CashuranceTheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFormHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            border: Border.all(color: CashuranceTheme.outlineVariant),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            'STEP 01',
            style: GoogleFonts.spaceGrotesk(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              letterSpacing: 1,
              color: CashuranceTheme.teal,
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Personal Details',
          style: GoogleFonts.spaceGrotesk(
            fontSize: 32,
            fontWeight: FontWeight.w600,
            letterSpacing: -1,
            color: CashuranceTheme.deep,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'Please provide your legal information exactly as it appears on official documents.',
          style: GoogleFonts.inter(
            fontSize: 14,
            color: CashuranceTheme.onSurfaceVariant,
            height: 1.5,
          ),
        ),
      ],
    );
  }

  Widget _buildForm(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildFormHeader(),
        const SizedBox(height: 48),
        _buildFormFields(context),
      ],
    );
  }

  Widget _buildFormFields(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        StepInput(
          label: 'Full Legal Name',
          placeholder: 'Johnathan Doe',
          controller: _nameCtrl,
          keyboardType: TextInputType.name,
        ),
        const SizedBox(height: 24),
        Row(
          children: [
            Expanded(
              child: StepInput(
                label: 'Phone Number',
                placeholder: '98765 43210',
                controller: _phoneCtrl,
                keyboardType: TextInputType.phone,
                prefixText: '+91 ',
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'DATE OF BIRTH',
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1,
                      color: CashuranceTheme.sage,
                    ),
                  ),
                  const SizedBox(height: 8),
                  GestureDetector(
                    onTap: _pickDate,
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 16),
                      decoration: BoxDecoration(
                        color: Colors.transparent,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                            color:
                                CashuranceTheme.sage.withValues(alpha: 0.4)),
                      ),
                      child: Text(
                        _dob == null
                            ? 'DD / MM / YYYY'
                            : '${_dob!.day.toString().padLeft(2, '0')} / ${_dob!.month.toString().padLeft(2, '0')} / ${_dob!.year}',
                        style: GoogleFonts.inter(
                          fontSize: 15,
                          color: _dob == null
                              ? CashuranceTheme.sage.withValues(alpha: 0.6)
                              : CashuranceTheme.deep,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        StepInput(
          label: 'Permanent Address',
          placeholder: 'House No, Street, Landmark...',
          controller: _addressCtrl,
          maxLines: 3,
        ),
        const SizedBox(height: 24),
        Row(
          children: [
            Expanded(
              child: StepInput(
                label: 'Create Password',
                placeholder: 'At least 6 characters',
                controller: _passwordCtrl,
                obscureText: true,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: StepInput(
                label: 'Confirm Password',
                placeholder: 'Re-enter password',
                controller: _confirmPasswordCtrl,
                obscureText: true,
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        SizedBox(
          width: 150,
          child: StepInput(
            label: 'PINCODE',
            placeholder: '400001',
            controller: _pincodeCtrl,
            keyboardType: TextInputType.number,
            maxLength: 6,
          ),
        ),
        const SizedBox(height: 32),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: 24,
              width: 24,
              child: Checkbox(
                value: _agreed,
                onChanged: (v) => setState(() => _agreed = v ?? false),
                activeColor: CashuranceTheme.teal,
                checkColor: Colors.white,
                side: BorderSide(
                    color: CashuranceTheme.sage.withValues(alpha: 0.5)),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: RichText(
                text: TextSpan(
                  style: GoogleFonts.inter(
                      fontSize: 13,
                      color: CashuranceTheme.onSurfaceVariant,
                      height: 1.5),
                  children: const [
                    TextSpan(
                        text:
                            'I verify that the above information is accurate and matches my official PAN/Aadhaar cards. I agree to the '),
                    TextSpan(
                        text: 'Terms',
                        style: TextStyle(
                            color: CashuranceTheme.teal,
                            fontWeight: FontWeight.w600)),
                    TextSpan(text: '.'),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 48),
        _NextButton(
          label: 'Continue',
          onPressed: _continue,
        ),
      ],
    );
  }
}

class _NextButton extends StatefulWidget {
  final String label;
  final VoidCallback onPressed;
  const _NextButton({required this.label, required this.onPressed});

  @override
  State<_NextButton> createState() => _NextButtonState();
}

class _NextButtonState extends State<_NextButton> {
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
