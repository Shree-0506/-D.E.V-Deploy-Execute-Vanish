import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme.dart';

/// Shared top app bar used across all screens
class CashuranceAppBar extends StatelessWidget implements PreferredSizeWidget {
  final bool showMenuButton;

  const CashuranceAppBar({super.key, this.showMenuButton = true});

  @override
  Size get preferredSize => const Size.fromHeight(64);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: CashuranceTheme.surface,
      elevation: 0,
      scrolledUnderElevation: 0.5,
      leadingWidth: showMenuButton ? 56 : 16,
      leading: showMenuButton
          ? IconButton(
              icon: const Icon(Icons.menu_rounded,
                  color: CashuranceTheme.onSurfaceVariant),
              onPressed: () {},
            )
          : null,
      title: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Image.asset('assets/logo.png',
              width: 24, height: 24, color: CashuranceTheme.teal),
          const SizedBox(width: 8),
          Text(
            'CASHURANCE',
            style: GoogleFonts.spaceGrotesk(
              fontWeight: FontWeight.w800,
              fontSize: 18,
              letterSpacing: -0.5,
              color: CashuranceTheme.deep,
            ),
          ),
        ],
      ),
      centerTitle: false,
      actions: [
        IconButton(
          icon: const Icon(Icons.help_outline_rounded,
              color: CashuranceTheme.onSurfaceVariant),
          onPressed: () {},
        ),
        const SizedBox(width: 8),
      ],
    );
  }
}
