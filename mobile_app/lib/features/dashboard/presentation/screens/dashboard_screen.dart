import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/state/current_user_controller.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../auth/domain/auth_user.dart';
import '../../../marketplace/data/product_repository.dart';
import '../../../marketplace/domain/product.dart';
import '../../../marketplace/presentation/widgets/product_card.dart';
import '../../../profile/presentation/widgets/profile_preview_sheet.dart';

class _RecentScan {
  const _RecentScan({
    required this.diseaseName,
    required this.cropLabel,
    required this.dateLabel,
    required this.confidencePercent,
    required this.icon,
  });

  final String diseaseName;
  final String cropLabel;
  final String dateLabel;
  final int confidencePercent;
  final IconData icon;
}

const List<_RecentScan> _recentScans = [
  _RecentScan(
    diseaseName: 'Rice Blast',
    cropLabel: 'Paddy leaf',
    dateLabel: 'Today, 8:30 AM',
    confidencePercent: 92,
    icon: Icons.grass,
  ),
  _RecentScan(
    diseaseName: 'Tea Blister Blight',
    cropLabel: 'Tea leaf',
    dateLabel: 'Yesterday',
    confidencePercent: 87,
    icon: Icons.eco,
  ),
];

const List<String> _weekdayNames = [
  'Monday',
  'Tuesday',
  'Wednesday',
  'Thursday',
  'Friday',
  'Saturday',
  'Sunday',
];

const List<String> _monthNames = [
  'January',
  'February',
  'March',
  'April',
  'May',
  'June',
  'July',
  'August',
  'September',
  'October',
  'November',
  'December',
];

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  bool _didRequestLoad = false;

  List<Product>? _popularProducts;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_didRequestLoad) return;
    _didRequestLoad = true;
    final CurrentUserController controller = CurrentUserScope.of(context);
    // Deferred to a microtask so the controller's first notifyListeners()
    // never fires synchronously from within another element's
    // didChangeDependencies/build pass (same reasoning as ProfileScreen).
    Future.microtask(controller.load);
    Future.microtask(_loadPopularProducts);
  }

  // This is a decorative secondary section, not core functionality — on
  // failure it just stays hidden (see build()) rather than showing an
  // error banner on the dashboard.
  Future<void> _loadPopularProducts() async {
    try {
      final List<Product> products = await ProductRepository().getProducts(
        bestSeller: true,
      );
      if (!mounted) return;
      setState(() => _popularProducts = products);
    } catch (_) {
      // Left as null — the section simply doesn't render.
    }
  }

  String _formatToday() {
    final DateTime now = DateTime.now();
    final String weekday = _weekdayNames[now.weekday - 1];
    final String month = _monthNames[now.month - 1];
    return '$weekday, ${now.day} $month';
  }

  void _showComingSoon(BuildContext context) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Coming soon')));
  }

  void _showProfilePreview(BuildContext context) {
    // Kicks off the shared fetch here (a plain tap handler, not a build
    // pass) so it's safe to call synchronously; CurrentUserController.load()
    // is a no-op if the user is already loaded or a fetch is in flight.
    CurrentUserScope.of(context).load();
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) => const ProfilePreviewSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final AuthUser? user = CurrentUserScope.of(context).user;
    final String? firstName = (user != null && user.fullName.trim().isNotEmpty)
        ? user.fullName.trim().split(RegExp(r'\s+')).first
        : null;
    final String greeting = firstName != null
        ? 'Good morning, $firstName'
        : 'Good morning';

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.md,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(greeting, style: theme.textTheme.titleLarge),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          _formatToday(),
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: AppColors.soilInkSoft,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  InkWell(
                    borderRadius: BorderRadius.circular(22),
                    onTap: () => _showProfilePreview(context),
                    child: Container(
                      width: 44,
                      height: 44,
                      alignment: Alignment.center,
                      decoration: const BoxDecoration(
                        color: AppColors.paddyGreenContainer,
                        shape: BoxShape.circle,
                      ),
                      child: firstName != null
                          ? Text(
                              firstName[0].toUpperCase(),
                              style: theme.textTheme.titleMedium?.copyWith(
                                color: AppColors.paddyGreenOnContainer,
                              ),
                            )
                          : const Icon(
                              Icons.person_outline,
                              color: AppColors.paddyGreenOnContainer,
                            ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),

              // Primary action card
              Material(
                color: AppColors.paddyGreen,
                borderRadius: BorderRadius.circular(20),
                child: InkWell(
                  borderRadius: BorderRadius.circular(20),
                  onTap: () => context.go('/capture'),
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
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Scan Crop',
                                style: theme.textTheme.titleLarge?.copyWith(
                                  color: AppColors.riceHusk,
                                ),
                              ),
                              const SizedBox(height: AppSpacing.xs),
                              Text(
                                'Detect diseases in seconds',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: AppColors.riceHusk.withValues(
                                    alpha: 0.85,
                                  ),
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
              const SizedBox(height: AppSpacing.lg),

              // Quick actions row
              Row(
                children: [
                  Expanded(
                    child: _QuickActionCard(
                      icon: Icons.chat_bubble_outline,
                      label: 'Ask Advisory',
                      onTap: () => context.go('/advisory'),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: _QuickActionCard(
                      icon: Icons.receipt_long_outlined,
                      label: 'My Orders',
                      onTap: () => _showComingSoon(context),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: _QuickActionCard(
                      icon: Icons.storefront_outlined,
                      label: 'Marketplace',
                      onTap: () => context.go('/marketplace'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xl),

              // Recent activity
              Text('Recent Scans', style: theme.textTheme.titleMedium),
              const SizedBox(height: AppSpacing.sm),
              SizedBox(
                height: 132,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: _recentScans.length,
                  separatorBuilder: (_, _) =>
                      const SizedBox(width: AppSpacing.sm),
                  itemBuilder: (context, index) =>
                      _RecentScanCard(scan: _recentScans[index]),
                ),
              ),
              const SizedBox(height: AppSpacing.xl),

              // Popular products — hidden until loaded (or if the fetch
              // failed / returned nothing), since this is a secondary,
              // decorative section rather than core functionality.
              if (_popularProducts != null && _popularProducts!.isNotEmpty) ...[
                Text(
                  'Popular in your area',
                  style: theme.textTheme.titleMedium,
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'Trusted by farmers near you',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: AppColors.soilInkSoft,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                SizedBox(
                  height: 196,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: _popularProducts!.length,
                    separatorBuilder: (_, _) =>
                        const SizedBox(width: AppSpacing.sm),
                    itemBuilder: (context, index) {
                      final Product product = _popularProducts![index];
                      return SizedBox(
                        width: 156,
                        child: ProductCard(
                          product: product,
                          onTap: () => context.push(
                            '/marketplace/product',
                            extra: product,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _QuickActionCard extends StatelessWidget {
  const _QuickActionCard({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm,
            vertical: AppSpacing.md,
          ),
          child: Column(
            children: [
              Icon(icon, color: AppColors.paddyGreen, size: 24),
              const SizedBox(height: AppSpacing.xs),
              Text(
                label,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.labelMedium,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RecentScanCard extends StatelessWidget {
  const _RecentScanCard({required this.scan});

  final _RecentScan scan;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.sm + AppSpacing.xs),
        child: SizedBox(
          width: 176,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    alignment: Alignment.center,
                    decoration: const BoxDecoration(
                      color: AppColors.monsoonTealContainer,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      scan.icon,
                      color: AppColors.monsoonTealOnContainer,
                      size: 20,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.paddyGreenContainer,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${scan.confidencePercent}%',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: AppColors.paddyGreenOnContainer,
                        letterSpacing: 0,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                scan.diseaseName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.titleSmall,
              ),
              const SizedBox(height: 2),
              Text(
                '${scan.cropLabel} · ${scan.dateLabel}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
