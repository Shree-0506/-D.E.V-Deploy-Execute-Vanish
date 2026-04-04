import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';

import 'package:cashurance/main.dart';

void main() {
  testWidgets('Login screen renders on launch', (WidgetTester tester) async {
    tester.view.devicePixelRatio = 1.0;
    tester.view.physicalSize = const Size(1440, 900);
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(const CashuranceApp());
    await tester.pumpAndSettle();

    expect(find.text('Sign in'), findsWidgets);
    expect(find.text('Continue with OTP'), findsOneWidget);
  });
}
