import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/prediction_result.dart';

/// Turns "leaf_spot" into "Leaf Spot" for display.
String _titleCase(String value) => value
    .split('_')
    .map((word) => word.isEmpty ? word : word[0].toUpperCase() + word.substring(1))
    .join(' ');

class ResultScreen extends StatelessWidget {
  const ResultScreen({required this.image, required this.result, super.key});

  final XFile image;
  final PredictionResult result;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    if (!result.isOk) {
      return _UncertainResultView(image: image, result: result, theme: theme);
    }

    final String cropName = _titleCase(result.crop!);
    final String diseaseName = _titleCase(result.disease!);
    final String displayName = result.disease == 'healthy'
        ? '$cropName — Healthy'
        : '$cropName — $diseaseName';
    final int confidencePercent = (result.confidence * 100).round();

    Uint8List? heatmapBytes;
    if (result.heatmapUrl != null) {
      try {
        heatmapBytes = base64Decode(result.heatmapUrl!);
      } catch (_) {
        heatmapBytes = null;
      }
    }

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

              // Grad-CAM heatmap: real decoded overlay when the backend sent
              // one, otherwise the same placeholder as before.
              Container(
                clipBehavior: Clip.antiAlias,
                padding: heatmapBytes == null
                    ? const EdgeInsets.all(AppSpacing.md)
                    : EdgeInsets.zero,
                decoration: BoxDecoration(
                  gradient: heatmapBytes == null
                      ? LinearGradient(
                          colors: [
                            AppColors.turmericGoldContainer,
                            AppColors.alertRedContainer,
                          ],
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                        )
                      : null,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: heatmapBytes != null
                    ? Image.memory(
                        heatmapBytes,
                        height: 240,
                        width: double.infinity,
                        fit: BoxFit.cover,
                      )
                    : Row(
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
                      displayName,
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
                      '$confidencePercent% confidence',
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: AppColors.paddyGreenOnContainer,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xl),

              FilledButton.icon(
                onPressed: () => context.go('/advisory', extra: displayName),
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

/// Shown for the `low_confidence` and `not_a_leaf` statuses — no crop or
/// disease is available in either case, so this shows the backend's
/// user-facing message and prompts a retake instead.
class _UncertainResultView extends StatelessWidget {
  const _UncertainResultView({
    required this.image,
    required this.result,
    required this.theme,
  });

  final XFile image;
  final PredictionResult result;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
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
              const SizedBox(height: AppSpacing.xl),
              Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: AppColors.turmericGoldContainer,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      color: AppColors.turmericGoldOnContainer,
                      size: 28,
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text(
                        result.message ?? 'Unable to identify this photo.',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: AppColors.turmericGoldOnContainer,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              FilledButton.icon(
                onPressed: () => context.pop(),
                icon: const Icon(Icons.camera_alt_outlined),
                label: const Text('Retake Photo'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
