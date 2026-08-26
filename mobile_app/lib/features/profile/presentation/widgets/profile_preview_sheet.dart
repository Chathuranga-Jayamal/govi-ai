import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/state/current_user_controller.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../auth/data/auth_repository.dart';
import '../../../auth/domain/auth_user.dart';
import '../../domain/user_profile.dart';

class ProfilePreviewSheet extends StatelessWidget {
  const ProfilePreviewSheet({super.key});

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final CurrentUserController userController = CurrentUserScope.of(context);
    final AuthUser? user = userController.user;

    final String displayName =
        user?.fullName ??
        (userController.errorMessage != null
            ? 'Couldn\'t load profile'
            : 'Loading…');
    final String displayEmail = user?.email ?? '';
    final String avatarInitial = (user != null && user.fullName.isNotEmpty)
        ? user.fullName[0].toUpperCase()
        : '?';

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              alignment: Alignment.center,
              decoration: const BoxDecoration(
                color: AppColors.paddyGreenContainer,
                shape: BoxShape.circle,
              ),
              child: Text(
                avatarInitial,
                style: theme.textTheme.headlineSmall?.copyWith(
                  color: AppColors.paddyGreenOnContainer,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(displayName, style: theme.textTheme.titleLarge),
            const SizedBox(height: AppSpacing.xs),
            Text(
              displayEmail,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: AppColors.soilInkSoft,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _StatChip(label: '${mockOrders.length} Orders'),
                const SizedBox(width: AppSpacing.sm),
                _StatChip(label: 'Member since $mockMemberSince'),
              ],
            ),
            const SizedBox(height: AppSpacing.xl),
            FilledButton.icon(
              onPressed: () {
                Navigator.pop(context);
                context.push('/profile');
              },
              icon: const Icon(Icons.person_outline),
              label: const Text('View Full Profile'),
            ),
            const SizedBox(height: AppSpacing.sm),
            OutlinedButton.icon(
              onPressed: () {
                Navigator.pop(context);
                context.push('/profile', extra: true);
              },
              icon: const Icon(Icons.receipt_long_outlined),
              label: const Text('Order History'),
            ),
            const SizedBox(height: AppSpacing.sm),
            TextButton.icon(
              onPressed: () async {
                Navigator.pop(context);
                await AuthRepository().logout();
                if (context.mounted) {
                  CurrentUserScope.of(context).clear();
                  context.go('/login');
                }
              },
              icon: const Icon(Icons.logout, color: AppColors.alertRed),
              label: const Text(
                'Log Out',
                style: TextStyle(color: AppColors.alertRed),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm + AppSpacing.xs,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: AppColors.monsoonTealContainer,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
          color: AppColors.monsoonTealOnContainer,
        ),
      ),
    );
  }
}
