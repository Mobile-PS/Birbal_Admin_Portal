import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';
import '../../core/config/app_config.dart';
import '../shell/admin_page.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final platform = kIsWeb ? 'Web' : defaultTargetPlatform.name;
    return AdminPage(
      title: 'Settings',
      subtitle: 'API target and app configuration.',
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.line),
        ),
        child: Column(
          children: [
            _SettingRow(label: 'App', value: AppConfig.appName),
            const Divider(height: 1),
            _SettingRow(label: 'Platform', value: platform),
            const Divider(height: 1),
            _SettingRow(label: 'API base URL', value: AppConfig.baseUrl),
            const Divider(height: 1),
            _SettingRow(
              label: 'API calls',
              value: AppConfig.disableApiCalls ? 'Disabled' : 'Enabled',
            ),
            const Divider(height: 1),
            const _SettingRow(
              label: 'Override',
              value: '--dart-define=BASE_URL=http://host/api/v1',
            ),
          ],
        ),
      ),
    );
  }
}

class _SettingRow extends StatelessWidget {
  const _SettingRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(label, style: Theme.of(context).textTheme.titleMedium),
          ),
          Expanded(
            child: Text(
              value,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
