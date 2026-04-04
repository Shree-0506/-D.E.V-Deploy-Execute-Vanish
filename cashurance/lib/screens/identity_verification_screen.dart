import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import '../theme.dart';
import '../widgets/progress_footer.dart';
import '../services/registration_draft.dart';

class IdentityVerificationScreen extends StatefulWidget {
  const IdentityVerificationScreen({super.key});

  @override
  State<IdentityVerificationScreen> createState() =>
      _IdentityVerificationScreenState();
}

class _IdentityVerificationScreenState
    extends State<IdentityVerificationScreen> {
  File? _frontImage;
  File? _backImage;
  final _picker = ImagePicker();

  Future<void> _pickImage(bool isFront) async {
    final source = await _showSourceDialog();
    if (source == null) return;
    final picked = await _picker.pickImage(source: source, imageQuality: 85);
    if (picked == null) return;
    setState(() {
      if (isFront) {
        _frontImage = File(picked.path);
      } else {
        _backImage = File(picked.path);
      }
    });

    final draft = RegistrationDraft.instance;
    if (isFront) {
      draft.idFrontPath = picked.path;
    } else {
      draft.idBackPath = picked.path;
    }
  }

  void _continue() {
    Navigator.pushNamed(context, '/platform');
  }

  Future<ImageSource?> _showSourceDialog() {
    return showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        margin: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              Container(
                width: 48,
                height: 4,
                decoration: BoxDecoration(
                  color: CashuranceTheme.outlineVariant,
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'UPLOAD SOURCE',
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 2,
                  color: CashuranceTheme.sage,
                ),
              ),
              const SizedBox(height: 12),
              ListTile(
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                leading: const Icon(Icons.camera_alt_outlined,
                    color: CashuranceTheme.teal),
                title: Text('Take a Photo',
                    style: GoogleFonts.inter(fontWeight: FontWeight.w500)),
                onTap: () => Navigator.pop(ctx, ImageSource.camera),
              ),
              Divider(
                  height: 1,
                  color: CashuranceTheme.sage.withValues(alpha: 0.15)),
              ListTile(
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                leading: const Icon(Icons.photo_library_outlined,
                    color: CashuranceTheme.teal),
                title: Text('Choose from Gallery',
                    style: GoogleFonts.inter(fontWeight: FontWeight.w500)),
                onTap: () => Navigator.pop(ctx, ImageSource.gallery),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
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
              constraints: const BoxConstraints(maxWidth: 800),
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
                        'STEP 02',
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
                      'Identity\nVerification',
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
                      'Please provide a high-resolution scan of a valid Government-issued ID. For testing, you can continue without uploading.',
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        height: 1.6,
                        color: CashuranceTheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 48),
                    if (isWide)
                      Row(
                        children: [
                          Expanded(
                              child: _IDCard(
                                  isFront: true,
                                  image: _frontImage,
                                  onTap: () => _pickImage(true))),
                          const SizedBox(width: 24),
                          Expanded(
                              child: _IDCard(
                                  isFront: false,
                                  image: _backImage,
                                  onTap: () => _pickImage(false))),
                        ],
                      )
                    else
                      Column(
                        children: [
                          _IDCard(
                              isFront: true,
                              image: _frontImage,
                              onTap: () => _pickImage(true)),
                          const SizedBox(height: 24),
                          _IDCard(
                              isFront: false,
                              image: _backImage,
                              onTap: () => _pickImage(false)),
                        ],
                      ),
                    const SizedBox(height: 48),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        _NextButton(
                          label: 'Continue',
                          onPressed: _continue,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
      bottomNavigationBar: const ProgressFooter(currentStep: 2),
    );
  }
}

class _IDCard extends StatelessWidget {
  final bool isFront;
  final File? image;
  final VoidCallback onTap;
  const _IDCard(
      {required this.isFront, required this.image, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                isFront ? 'FRONT OF ID' : 'BACK OF ID',
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 2,
                  color: CashuranceTheme.deep,
                ),
              ),
              if (image != null)
                const Icon(Icons.check_circle,
                    color: CashuranceTheme.teal, size: 16),
            ],
          ),
          const SizedBox(height: 16),
          AspectRatio(
            aspectRatio: 1.6,
            child: Container(
              decoration: BoxDecoration(
                color: image != null
                    ? Colors.transparent
                    : CashuranceTheme.surfaceContainerLow,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: image != null
                        ? CashuranceTheme.teal
                        : CashuranceTheme.outlineVariant),
              ),
              child: image != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(11),
                      child: Image.file(image!, fit: BoxFit.cover),
                    )
                  : Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          isFront
                              ? Icons.document_scanner_outlined
                              : Icons.flip_outlined,
                          color: CashuranceTheme.sage,
                          size: 32,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Tap to upload',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            color: CashuranceTheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ],
      ),
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
          padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 16),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [CashuranceTheme.teal, Color(0xFF3D6A70)],
            ),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: CashuranceTheme.teal.withValues(alpha: 0.3),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
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
    );
  }
}
