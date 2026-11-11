import 'package:flutter/material.dart';

class AdminDestination {
  const AdminDestination({
    required this.label,
    required this.path,
    required this.icon,
    required this.selectedIcon,
    required this.subtitle,
  });

  final String label;
  final String path;
  final IconData icon;
  final IconData selectedIcon;
  final String subtitle;
}

const adminDestinations = <AdminDestination>[
  AdminDestination(
    label: 'Dashboard',
    path: '/',
    icon: Icons.space_dashboard_outlined,
    selectedIcon: Icons.space_dashboard_rounded,
    subtitle: 'Operations overview for Birbal Advice.',
  ),
  AdminDestination(
    label: 'Customers',
    path: '/customers',
    icon: Icons.people_outline,
    selectedIcon: Icons.people_rounded,
    subtitle: 'Policyholders and contact records.',
  ),
  AdminDestination(
    label: 'Policies',
    path: '/policies',
    icon: Icons.verified_user_outlined,
    selectedIcon: Icons.verified_user_rounded,
    subtitle: 'Issued cover across insurers.',
  ),
  AdminDestination(
    label: 'Claims',
    path: '/claims',
    icon: Icons.assignment_outlined,
    selectedIcon: Icons.assignment_rounded,
    subtitle: 'Filings, reviews, and settlements.',
  ),
  AdminDestination(
    label: 'Inquiries',
    path: '/inquiries',
    icon: Icons.forum_outlined,
    selectedIcon: Icons.forum_rounded,
    subtitle: 'Advice requests waiting on the team.',
  ),
  AdminDestination(
    label: 'Product',
    path: '/products',
    icon: Icons.inventory_2_outlined,
    selectedIcon: Icons.inventory_2_rounded,
    subtitle: 'Product categories.',
  ),
  AdminDestination(
    label: 'Settings',
    path: '/settings',
    icon: Icons.settings_outlined,
    selectedIcon: Icons.settings_rounded,
    subtitle: 'API target and app configuration.',
  ),
];
