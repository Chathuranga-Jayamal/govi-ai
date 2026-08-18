import 'dart:io';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';

/// Mock prediction data — real inference wiring against
/// ai_model/artifacts/model.tflite comes in a later phase.
const String _mockDiseaseName = 'Rice Blast';
const int _mockConfidencePercent = 92;
const String _mockRecommendation =
    'Apply a tricyclazole-based fungicide and avoid excess nitrogen '
    'fertilizer until symptoms clear.';

class ResultScreen extends StatelessWidget {
  const ResultScreen({required this.image, super.key});

  final XFile image;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Scan Result')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.file(
                  File(image.path),
                  height: 240,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(height: AppSpacing.md),

              // Mock heatmap placeholder
              Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.turmericGoldContainer,
                      AppColors.alertRedContainer,
                    ],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.local_fire_department,
                      color: AppColors.alertRedOnContainer,
                      size: 28,
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Heatmap preview',
                            style: theme.textTheme.titleSmall?.copyWith(
                              color: AppColors.alertRedOnContainer,
                            ),
                          ),
                          Text(
                            'Grad-CAM explainability coming later',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: AppColors.alertRedOnContainer,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.xl),

              // Prediction
              Row(
                children: [
                  Expanded(
                    child: Text(
                      _mockDiseaseName,
                      style: theme.textTheme.headlineSmall,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm + AppSpacing.xs,
                      vertical: AppSpacing.xs,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.paddyGreenContainer,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '$_mockConfidencePercent% confidence',
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: AppColors.paddyGreenOnContainer,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                _mockRecommendation,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: AppColors.soilInkSoft,
                ),
              ),
              const SizedBox(height: AppSpacing.xl),

              FilledButton.icon(
                onPressed: () => context.go(
                  '/advisory',
                  extra: _mockDiseaseName,
                ),
                icon: const Icon(Icons.chat_bubble_outline),
                label: const Text('Ask Advisory About This'),
              ),
              const SizedBox(height: AppSpacing.sm),
              OutlinedButton.icon(
                onPressed: () => context.pop(),
                icon: const Icon(Icons.camera_alt_outlined),
                label: const Text('Scan Another'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
