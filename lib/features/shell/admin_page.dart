import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';

class AdminPage extends StatelessWidget {
  const AdminPage({
    required this.title,
    required this.child,
    this.subtitle,
    super.key,
  });

  final String title;
  final String? subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: AppColors.background,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final padding = constraints.maxWidth >= 720 ? 28.0 : 16.0;
          return SingleChildScrollView(
            padding: EdgeInsets.all(padding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: AppColors.navy,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 6),
                  Text(
                    subtitle!,
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                ],
                const SizedBox(height: 24),
                child,
              ],
            ),
          );
        },
      ),
    );
  }
}
