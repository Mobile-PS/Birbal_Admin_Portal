import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';
import 'admin_page.dart';

class ModulePage extends StatelessWidget {
  const ModulePage({
    required this.title,
    required this.subtitle,
    super.key,
  });

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return AdminPage(
      title: title,
      subtitle: subtitle,
      child: const _ReadyCard(),
    );
  }
}

class _ReadyCard extends StatelessWidget {
  const _ReadyCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.line),
      ),
      child: Text(
        'This section is wired into navigation. '
        'Load it with ApiClient when the admin endpoint is ready.',
        style: Theme.of(context).textTheme.bodyLarge,
      ),
    );
  }
}
