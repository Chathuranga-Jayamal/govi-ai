import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/network/api_exception.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../data/disease_repository.dart';
import '../../domain/capture_result_args.dart';

class _CropOption {
  const _CropOption(this.value, this.label, this.icon);

  final String value;
  final String label;
  final IconData icon;
}

const List<_CropOption> _cropOptions = [
  _CropOption('rice', 'Rice', Icons.grass),
  _CropOption('tea', 'Tea', Icons.spa_outlined),
  _CropOption('coconut', 'Coconut', Icons.park_outlined),
  _CropOption('tomato', 'Tomato', Icons.local_florist_outlined),
  _CropOption('chili', 'Chili', Icons.whatshot_outlined),
  _CropOption('potato', 'Potato', Icons.egg_outlined),
  _CropOption('corn', 'Corn', Icons.eco_outlined),
  _CropOption('banana', 'Banana', Icons.nature_outlined),
];

class CaptureScreen extends StatefulWidget {
  const CaptureScreen({super.key});

  @override
  State<CaptureScreen> createState() => _CaptureScreenState();
}

class _CaptureScreenState extends State<CaptureScreen> {
  final ImagePicker _picker = ImagePicker();
  final DiseaseRepository _diseaseRepository = DiseaseRepository();
  String? _selectedCrop;
  bool _isAnalyzing = false;

  Future<void> _pickImage(ImageSource source) async {
    final String? crop = _selectedCrop;
    if (crop == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a crop first.')),
      );
      return;
    }

    final XFile? image = await _picker.pickImage(
      source: source,
      imageQuality: 85,
    );
    if (image == null || !mounted) return;

    setState(() => _isAnalyzing = true);

    try {
      final result = await _diseaseRepository.predict(
        imagePath: image.path,
        crop: crop,
      );
      if (!mounted) return;
      context.push(
        '/capture/result',
        extra: CaptureResultArgs(image: image, result: result),
      );
    } on ApiException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.message),
          backgroundColor: AppColors.alertRed,
        ),
      );
    } finally {
      if (mounted) setState(() => _isAnalyzing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: _isAnalyzing
            ? _AnalyzingView(theme: theme)
            : SingleChildScrollView(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Container(
                      width: 96,
                      height: 96,
                      alignment: Alignment.center,
                      decoration: const BoxDecoration(
                        color: AppColors.paddyGreenContainer,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.eco_outlined,
                        color: AppColors.paddyGreen,
                        size: 44,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    Text(
                      'Scan Your Crop',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.headlineSmall,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      'Take a clear photo of the affected leaf and we\'ll '
                      'check it for signs of disease.',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: AppColors.soilInkSoft,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xl),

                    // Crop selector — required before a scan can be taken
                    Text('Select Crop', style: theme.textTheme.titleMedium),
                    const SizedBox(height: AppSpacing.sm),
                    Wrap(
                      spacing: AppSpacing.sm,
                      runSpacing: AppSpacing.sm,
                      children: [
                        for (final crop in _cropOptions)
                          ChoiceChip(
                            avatar: Icon(
                              crop.icon,
                              size: 18,
                              color: _selectedCrop == crop.value
                                  ? AppColors.paddyGreenOnContainer
                                  : AppColors.soilInkSoft,
                            ),
                            label: Text(crop.label),
                            selected: _selectedCrop == crop.value,
                            onSelected: (_) =>
                                setState(() => _selectedCrop = crop.value),
                          ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xl),

                    // Primary action card
                    Material(
                      color: AppColors.paddyGreen,
                      borderRadius: BorderRadius.circular(20),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(20),
                        onTap: () => _pickImage(ImageSource.camera),
                        child: Padding(
                          padding: const EdgeInsets.all(AppSpacing.lg),
                          child: Row(
                            children: [
                              Container(
                                width: 56,
                                height: 56,
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.16),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.camera_alt,
                                  color: AppColors.riceHusk,
                                  size: 28,
                                ),
                              ),
                              const SizedBox(width: AppSpacing.md),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Take Photo',
                                      style: theme.textTheme.titleLarge
                                          ?.copyWith(
                                            color: AppColors.riceHusk,
                                          ),
                                    ),
                                    const SizedBox(height: AppSpacing.xs),
                                    Text(
                                      'Use your camera right now',
                                      style: theme.textTheme.bodyMedium
                                          ?.copyWith(
                                            color: AppColors.riceHusk
                                                .withValues(alpha: 0.85),
                                          ),
                                    ),
                                  ],
                                ),
                              ),
                              const Icon(
                                Icons.arrow_forward_ios,
                                color: AppColors.riceHusk,
                                size: 18,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),

                    // Secondary action
                    OutlinedButton.icon(
                      onPressed: () => _pickImage(ImageSource.gallery),
                      icon: const Icon(Icons.photo_library_outlined),
                      label: const Text('Choose from Gallery'),
                    ),
                    const SizedBox(height: AppSpacing.xl),

                    // Tips for a good scan
                    Text(
                      'Tips for a good scan',
                      style: theme.textTheme.titleMedium,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(AppSpacing.md),
                        child: Column(
                          children: const [
                            _ScanTipRow(
                              icon: Icons.wb_sunny_outlined,
                              text:
                                  'Shoot in natural daylight, avoid harsh '
                                  'shadows',
                            ),
                            SizedBox(height: AppSpacing.sm),
                            _ScanTipRow(
                              icon: Icons.center_focus_strong_outlined,
                              text: 'Center the affected leaf in frame',
                            ),
                            SizedBox(height: AppSpacing.sm),
                            _ScanTipRow(
                              icon: Icons.blur_off_outlined,
                              text: 'Hold steady to avoid a blurry photo',
                            ),
                            SizedBox(height: AppSpacing.sm),
                            _ScanTipRow(
                              icon: Icons.zoom_in_outlined,
                              text: 'Get close enough to see detail clearly',
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xl),

                  ],
                ),
              ),
      ),
    );
  }
}

class _ScanTipRow extends StatelessWidget {
  const _ScanTipRow({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 28,
          height: 28,
          alignment: Alignment.center,
          decoration: const BoxDecoration(
            color: AppColors.monsoonTealContainer,
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            color: AppColors.monsoonTealOnContainer,
            size: 16,
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(text, style: Theme.of(context).textTheme.bodyMedium),
          ),
        ),
      ],
    );
  }
}

class _AnalyzingView extends StatelessWidget {
  const _AnalyzingView({required this.theme});

  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(color: AppColors.paddyGreen),
          const SizedBox(height: AppSpacing.lg),
          Text('Analyzing...', style: theme.textTheme.titleMedium),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Checking your photo for signs of disease',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: AppColors.soilInkSoft,
            ),
          ),
        ],
      ),
    );
  }
}
