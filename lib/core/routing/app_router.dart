import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/enter_otp_page.dart';
import '../../features/auth/login_page.dart';
import '../../data/models/customer_summary.dart';
import '../../data/models/insurance_plan_model.dart';
import '../../features/customers/add_customer_page.dart';
import '../../features/customers/add_policy_page.dart';
import '../../features/customers/customer_policies_page.dart';
import '../../features/customers/customers_page.dart';
import '../../features/customers/edit_customer_page.dart';
import '../../features/customers/edit_policy_args.dart';
import '../../features/dashboard/dashboard_page.dart';
import '../../features/crm/add_edit_lead_page.dart';
import '../../features/crm/crm_leads_page.dart';
import '../../features/crm/lead_detail_page.dart';
import '../../features/inquiries/inquiries_page.dart';
import '../../data/models/product_entry.dart';
import '../../features/products/add_plan_page.dart';
import '../../features/products/add_product_page.dart';
import '../../features/products/product_plan_detail_page.dart';
import '../../features/products/product_plans_page.dart';
import '../../features/products/products_page.dart';
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
        path: '/customers/edit',
        builder: (context, state) {
          final customer = state.extra is CustomerSummary
              ? state.extra! as CustomerSummary
              : null;
          if (customer == null) {
            return const ModulePage(
              title: 'Edit Customer',
              subtitle: 'Customer details are missing. Go back and try again.',
            );
          }
          return EditCustomerPage(customer: customer);
        },
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: '/customers/add-policy',
        builder: (context, state) {
          final customer = state.extra is CustomerSummary
              ? state.extra! as CustomerSummary
              : null;
          if (customer == null) {
            return const ModulePage(
              title: 'Add Policy',
              subtitle: 'Customer details are missing. Go back and try again.',
            );
          }
          return AddPolicyPage(customer: customer);
        },
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: '/customers/edit-policy',
        builder: (context, state) {
          final args = state.extra is EditPolicyArgs
              ? state.extra! as EditPolicyArgs
              : null;
          if (args == null) {
            return const ModulePage(
              title: 'Edit Policy',
              subtitle: 'Policy details are missing. Go back and try again.',
            );
          }
          return AddPolicyPage(
            customer: args.customer,
            policy: args.policy,
          );
        },
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: '/customers/policies',
        builder: (context, state) {
          final customer = state.extra is CustomerSummary
              ? state.extra! as CustomerSummary
              : null;
          if (customer == null) {
            return const ModulePage(
              title: 'Policies',
              subtitle: 'Customer details are missing. Go back and try again.',
            );
          }
          return CustomerPoliciesPage(customer: customer);
        },
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: '/crm/add',
        builder: (context, state) => const AddEditLeadPage(),
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: '/crm/edit',
        builder: (context, state) {
          final leadId = state.extra is String ? state.extra! as String : null;
          if (leadId == null || leadId.trim().isEmpty) {
            return const ModulePage(
              title: 'Edit Lead',
              subtitle: 'Lead details are missing. Go back and try again.',
            );
          }
          return AddEditLeadPage(leadId: leadId);
        },
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: '/crm/detail',
        builder: (context, state) {
          final leadId = state.extra is String ? state.extra! as String : null;
          if (leadId == null || leadId.trim().isEmpty) {
            return const ModulePage(
              title: 'Lead details',
              subtitle: 'Lead details are missing. Go back and try again.',
            );
          }
          return LeadDetailPage(leadId: leadId);
        },
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: '/products/add',
        builder: (context, state) => const AddProductPage(),
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: '/products/edit',
        builder: (context, state) {
          final product = state.extra is ProductEntry
              ? state.extra! as ProductEntry
              : null;
          if (product == null) {
            return const ModulePage(
              title: 'Edit Product',
              subtitle: 'Product details are missing. Go back and try again.',
            );
          }
          return AddProductPage(product: product);
        },
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: '/products/plans',
        builder: (context, state) {
          final code = state.uri.queryParameters['code'] ?? '';
          final title = state.uri.queryParameters['title'] ?? 'Insurance';
          return ProductPlansPage(
            categoryCode: code,
            categoryTitle: title,
          );
        },
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: '/products/plans/add',
        builder: (context, state) {
          final code = state.uri.queryParameters['code'] ?? '';
          final title = state.uri.queryParameters['title'] ?? '';
          return AddPlanPage(
            categoryCode: code,
            categoryTitle: title,
          );
        },
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: '/products/plans/edit',
        builder: (context, state) {
          final code = state.uri.queryParameters['code'] ?? '';
          final title = state.uri.queryParameters['title'] ?? '';
          final plan = state.extra is InsurancePlanModel
              ? state.extra! as InsurancePlanModel
              : null;
          if (plan == null) {
            return const ModulePage(
              title: 'Edit Plan',
              subtitle: 'Plan details are missing. Go back and try again.',
            );
          }
          return AddPlanPage(
            categoryCode: code.isNotEmpty ? code : plan.category,
            categoryTitle: title.isNotEmpty ? title : plan.category,
            plan: plan,
          );
        },
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: '/products/plans/detail',
        builder: (context, state) {
          final plan = state.extra is InsurancePlanModel
              ? state.extra! as InsurancePlanModel
              : null;
          return ProductPlanDetailPage(plan: plan);
        },
      ),
    ],
  );
}

Widget _pageFor(AdminDestination destination) {
  return switch (destination.path) {
    '/' => const DashboardPage(),
    '/customers' => const CustomersPage(),
    '/inquiries' => const InquiriesPage(),
    '/crm' => const CrmLeadsPage(),
    '/products' => const ProductsPage(),
    _ => ModulePage(
      title: destination.label,
      subtitle: destination.subtitle,
    ),
  };
}
