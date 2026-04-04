import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'theme.dart';
import 'app_shell.dart';
import 'services/auth_session.dart';
import 'screens/create_account_screen.dart';
import 'screens/login_screen.dart';
import 'screens/personal_details_screen.dart';
import 'screens/identity_verification_screen.dart';
import 'screens/platform_integration_screen.dart';

void main() {
  runApp(const CashuranceApp());
}

class CashuranceApp extends StatelessWidget {
  const CashuranceApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CashUrance',
      debugShowCheckedModeBanner: false,
      theme: CashuranceTheme.light,
      builder: (context, child) {
        final appChild = child ?? const SizedBox.shrink();

        // Keep native mobile/tablet full-bleed. Only constrain hosted web.
        if (!kIsWeb) return appChild;

        return Container(
          color: const Color(0xFF0B2E33),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 430),
              child: DecoratedBox(
                decoration: const BoxDecoration(color: Color(0xFFF4FAFB)),
                child: appChild,
              ),
            ),
          ),
        );
      },
      initialRoute: '/',
      routes: {
        '/': (_) => const CreateAccountScreen(),
        '/login': (_) => const LoginScreen(),
        '/personal': (_) => const PersonalDetailsScreen(),
        '/identity': (_) => const IdentityVerificationScreen(),
        '/platform': (_) => const PlatformIntegrationScreen(),
        '/app': (_) =>
            AppShell(firstTimeSetup: AuthSession.instance.firstTimeSetup),
      },
    );
  }
}
