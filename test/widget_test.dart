import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/test_app.dart';

void main() {
  testWidgets('shows email/mobile OTP login when signed out', (tester) async {
    await pumpAdminApp(tester, size: const Size(390, 844));

    expect(find.textContaining('Verify your'), findsOneWidget);
    expect(find.text('Mobile number'), findsWidgets);
    expect(find.text('Email'), findsOneWidget);
    expect(find.text('Send OTP'), findsOneWidget);
    expect(find.text('Password'), findsNothing);
  });

  testWidgets('OTP login opens the dashboard', (tester) async {
    await pumpAdminApp(
      tester,
      size: const Size(390, 844),
      mockAuthApi: true,
    );

    await tester.enterText(
      find.byKey(const ValueKey('login-mobile')),
      '9876543210',
    );
    await tester.pump();
    await tester.tap(find.text('Send OTP'));
    await tester.pumpAndSettle();

    expect(find.text('Enter OTP'), findsWidgets);

    for (var i = 0; i < 6; i++) {
      await tester.enterText(find.byType(TextField).at(i), '${i + 1}');
      await tester.pump();
    }

    await tester.tap(find.text('Verify OTP'));
    await tester.pumpAndSettle();

    expect(find.text('Dashboard'), findsWidgets);
    expect(find.text('Customers'), findsOneWidget);
    expect(find.text('Active policies'), findsOneWidget);
    expect(find.text('Inquiries'), findsOneWidget);
    expect(find.text('Product'), findsOneWidget);
  });

  testWidgets('product opens from the dashboard card', (tester) async {
    await pumpAdminApp(
      tester,
      size: const Size(390, 844),
      token: 'test-token',
    );

    await tester.ensureVisible(find.text('Product').first);
    await tester.tap(find.text('Product').first);
    await tester.pumpAndSettle();

    expect(find.text('Add Product'), findsOneWidget);
    expect(find.text('Health Insurance'), findsOneWidget);
    expect(find.byType(Switch), findsWidgets);

    final firstSwitch = tester.widget<Switch>(find.byType(Switch).first);
    expect(firstSwitch.value, isTrue);

    await tester.tap(find.byType(Switch).first);
    await tester.pumpAndSettle();

    expect(
      tester.widget<Switch>(find.byType(Switch).first).value,
      isFalse,
    );
  });

  testWidgets('customers opens from the dashboard card', (tester) async {
    await pumpAdminApp(
      tester,
      size: const Size(390, 844),
      token: 'test-token',
    );

    await tester.tap(find.text('Customers').first);
    await tester.pumpAndSettle();

    expect(find.text('Add Customer'), findsOneWidget);
    expect(find.text('Search by name, mobile or email...'), findsOneWidget);
    expect(find.text('Atish Vaidya'), findsOneWidget);
    expect(find.text('Filter'), findsNothing);
    expect(find.textContaining('Sort: Name'), findsOneWidget);

    await tester.tap(find.text('Add Customer'));
    await tester.pumpAndSettle();

    expect(find.textContaining('First Name'), findsOneWidget);
    expect(find.textContaining('Last Name'), findsOneWidget);
    expect(find.textContaining('Email'), findsOneWidget);
    expect(find.textContaining('Mobile'), findsOneWidget);
    expect(find.textContaining('Role'), findsOneWidget);
    expect(find.byKey(const ValueKey('add-customer-role')), findsOneWidget);
    expect(find.text('Customer'), findsOneWidget);
    expect(find.text('Save Customer'), findsOneWidget);
    expect(find.textContaining('Date of Birth'), findsNothing);
  });

  testWidgets('add customer posts to /users and returns to list', (
    tester,
  ) async {
    await pumpAdminApp(
      tester,
      size: const Size(390, 844),
      token: 'test-token',
      mockUsersApi: true,
    );

    await tester.tap(find.text('Customers').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Add Customer'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextFormField).at(0), 'Riya');
    await tester.enterText(find.byType(TextFormField).at(1), 'Sharma');
    await tester.enterText(
      find.byType(TextFormField).at(2),
      'riya@example.com',
    );
    await tester.enterText(find.byType(TextFormField).at(3), '9876543210');
    await tester.tap(find.text('Save Customer'));
    await tester.pumpAndSettle();

    expect(find.text('Customer saved'), findsOneWidget);
    expect(find.text('Add Customer'), findsOneWidget);
    expect(find.text('Search by name, mobile or email...'), findsOneWidget);
  });

  testWidgets('wide layout shows the side navigation and dashboard', (
    tester,
  ) async {
    await pumpAdminApp(
      tester,
      size: const Size(1400, 900),
      token: 'test-token',
    );

    expect(find.text('Dashboard'), findsWidgets);
    expect(find.text('Expiring Policies'), findsOneWidget);
    expect(find.byKey(const ValueKey('nav-/policies')), findsOneWidget);
    expect(find.byIcon(Icons.menu), findsNothing);

    await tester.tap(find.byKey(const ValueKey('nav-/policies')));
    await tester.pumpAndSettle();

    expect(find.text('Issued cover across insurers.'), findsOneWidget);
  });

  testWidgets('phone layout opens sections from the drawer', (tester) async {
    await pumpAdminApp(
      tester,
      size: const Size(390, 844),
      token: 'test-token',
    );

    expect(find.byIcon(Icons.menu), findsOneWidget);
    expect(find.text('Issued cover across insurers.'), findsNothing);

    await tester.tap(find.byIcon(Icons.menu));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('nav-/claims')));
    await tester.pumpAndSettle();

    expect(find.text('Filings, reviews, and settlements.'), findsOneWidget);
    expect(find.byIcon(Icons.menu), findsOneWidget);
    expect(find.byKey(const ValueKey('nav-/customers')), findsNothing);
  });
}
