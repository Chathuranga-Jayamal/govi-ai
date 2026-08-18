import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';

class AuthBrandHeader extends StatelessWidget {
  const AuthBrandHeader({required this.tagline, super.key});

  final String tagline;

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;

    return Column(
      children: [
        Container(
          width: 64,
          height: 64,
          alignment: Alignment.center,
          decoration: const BoxDecoration(
            color: AppColors.paddyGreenContainer,
            shape: BoxShape.circle,
          ),
          child: const Text('🌾', style: TextStyle(fontSize: 30)),
        ),
        const SizedBox(height: AppSpacing.md),
        Text('Govi-AI', style: textTheme.headlineMedium),
        const SizedBox(height: AppSpacing.xs),
        Text(
          tagline,
          textAlign: TextAlign.center,
          style: textTheme.bodyMedium?.copyWith(color: AppColors.soilInkSoft),
        ),
      ],
    );
  }
}
