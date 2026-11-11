import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme/app_colors.dart';
import '../shell/admin_page.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  static const metrics = <DashboardMetric>[
    DashboardMetric(
      label: 'Customers',
      value: '248',
      icon: Icons.people_alt_rounded,
      iconColor: Color(0xFF2F80ED),
      iconBackground: Color(0xFFE8F1FF),
      route: '/customers',
    ),
    DashboardMetric(
      label: 'Policies',
      value: '320',
      icon: Icons.description_rounded,
      iconColor: Color(0xFF27AE60),
      iconBackground: Color(0xFFE8F8EF),
      route: '/policies',
    ),
    DashboardMetric(
      label: 'Active policies',
      value: '286',
      icon: Icons.verified_user_rounded,
      iconColor: Color(0xFF219653),
      iconBackground: Color(0xFFE7F6EF),
      route: '/policies',
    ),
    DashboardMetric(
      label: 'Expiring Policies',
      value: '32',
      icon: Icons.schedule_rounded,
      iconColor: Color(0xFFEB5757),
      iconBackground: Color(0xFFFDECEC),
      route: '/policies',
    ),
    DashboardMetric(
      label: 'Inquiries',
      value: '18',
      icon: Icons.forum_rounded,
      iconColor: Color(0xFF9B51E0),
      iconBackground: Color(0xFFF3E9FC),
      route: '/inquiries',
    ),
    DashboardMetric(
      label: 'Product',
      value: '6',
      icon: Icons.inventory_2_rounded,
      iconColor: Color(0xFF2F6BFF),
      iconBackground: Color(0xFFE8F0FF),
      route: '/products',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return AdminPage(
      title: 'Dashboard',
      child: LayoutBuilder(
        builder: (context, constraints) {
          final columns = constraints.maxWidth >= 1100
              ? 4
              : constraints.maxWidth >= 720
              ? 3
              : 2;
          const spacing = 14.0;
          final cardWidth =
              (constraints.maxWidth - spacing * (columns - 1)) / columns;

          return Wrap(
            spacing: spacing,
            runSpacing: spacing,
            children: [
              for (final metric in metrics)
                SizedBox(
                  width: cardWidth,
                  child: DashboardMetricCard(
                    metric: metric,
                    onTap: () => context.go(metric.route),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

class DashboardMetric {
  const DashboardMetric({
    required this.label,
    required this.value,
    required this.icon,
    required this.iconColor,
    required this.iconBackground,
    required this.route,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color iconColor;
  final Color iconBackground;
  final String route;
}

class DashboardMetricCard extends StatelessWidget {
  const DashboardMetricCard({
    required this.metric,
    required this.onTap,
    super.key,
  });

  final DashboardMetric metric;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Ink(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(18),
            boxShadow: const [
              BoxShadow(
                color: Color(0x14000000),
                blurRadius: 18,
                offset: Offset(0, 8),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: metric.iconBackground,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(metric.icon, color: metric.iconColor, size: 22),
                ),
                const SizedBox(height: 18),
                Text(
                  metric.label,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  metric.value,
                  style: const TextStyle(
                    color: AppColors.navy,
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    height: 1.1,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
