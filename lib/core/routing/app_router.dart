import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/enter_otp_page.dart';
import '../../features/auth/login_page.dart';
import '../../features/customers/add_customer_page.dart';
import '../../features/customers/customers_page.dart';
import '../../features/dashboard/dashboard_page.dart';
import '../../features/products/add_product_page.dart';
import '../../features/products/products_page.dart';
import '../../features/settings/settings_page.dart';
import '../../features/shell/admin_shell.dart';
import '../../features/shell/module_page.dart';
import '../auth/session_controller.dart';
import 'admin_destination.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'root');

GoRouter createAppRouter(SessionController session) {
  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/login',
    refreshListenable: session,
    redirect: (context, state) {
      if (!session.isReady) return null;

      final onAuth = state.matchedLocation.startsWith('/login');
      if (!session.isSignedIn) {
        return onAuth ? null : '/login';
      }
      if (onAuth) return '/';
      return null;
    },
    routes: [
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginPage(),
        routes: [
          GoRoute(
            path: 'otp',
            builder: (context, state) {
              final identifier =
                  state.uri.queryParameters['identifier'] ?? '';
              final type = state.uri.queryParameters['type'] ?? 'M';
              return EnterOtpPage(identifier: identifier, type: type);
            },
          ),
        ],
      ),
      ShellRoute(
        builder: (context, state, child) => AdminShell(child: child),
        routes: [
          for (final destination in adminDestinations)
            GoRoute(
              path: destination.path,
              builder: (context, state) => _pageFor(destination),
            ),
        ],
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: '/customers/add',
        builder: (context, state) => const AddCustomerPage(),
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: '/products/add',
        builder: (context, state) => const AddProductPage(),
      ),
    ],
  );
}

Widget _pageFor(AdminDestination destination) {
  return switch (destination.path) {
    '/' => const DashboardPage(),
    '/customers' => const CustomersPage(),
    '/products' => const ProductsPage(),
    '/settings' => const SettingsPage(),
    _ => ModulePage(
      title: destination.label,
      subtitle: destination.subtitle,
    ),
  };
}
