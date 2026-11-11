import 'package:flutter/material.dart';

import '../../../app/theme/app_colors.dart';

class AuthSecureBanner extends StatelessWidget {
  const AuthSecureBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFFE8F1F0),
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Row(
        children: [
          Icon(Icons.verified_user_outlined, color: AppColors.brand, size: 22),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'Your information is secure and will never be shared.',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 13,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
