import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/user_profile.dart';
import '../widgets/order_card.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({this.scrollToOrderHistory = false, super.key});

  final bool scrollToOrderHistory;

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final TextEditingController _nameController = TextEditingController(
    text: mockUserName,
  );
  final TextEditingController _emailController = TextEditingController(
    text: mockUserEmail,
  );
  final TextEditingController _phoneController = TextEditingController(
    text: mockUserPhone,
  );

  final TextEditingController _currentPasswordController =
      TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  bool _obscureCurrent = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;

  String _selectedLanguage = 'English';
  static const List<String> _languages = ['සිංහල', 'தமிழ்', 'English'];

  final GlobalKey _orderHistoryKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    if (widget.scrollToOrderHistory) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final BuildContext? sectionContext = _orderHistoryKey.currentContext;
        if (sectionContext == null) return;
        Scrollable.ensureVisible(
          sectionContext,
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeOut,
        );
      });
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _saveProfile() {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Profile updated')));
  }

  void _updatePassword() {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Password updated')));
    _currentPasswordController.clear();
    _newPasswordController.clear();
    _confirmPasswordController.clear();
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // a. Personal Details
              Text('Personal Details', style: theme.textTheme.titleMedium),
              const SizedBox(height: AppSpacing.sm),
              TextField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Full Name',
                  prefixIcon: Icon(Icons.person_outline),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  prefixIcon: Icon(Icons.mail_outline),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              TextField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: 'Phone',
                  prefixIcon: Icon(Icons.phone_outlined),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              FilledButton(
                onPressed: _saveProfile,
                child: const Text('Save Changes'),
              ),
              const SizedBox(height: AppSpacing.xl),
              const Divider(),
              const SizedBox(height: AppSpacing.lg),

              // b. Language Preference
              Text('Language Preference', style: theme.textTheme.titleMedium),
              const SizedBox(height: AppSpacing.sm),
              Wrap(
                spacing: AppSpacing.sm,
                children: _languages.map((language) {
                  return ChoiceChip(
                    label: Text(language),
                    selected: _selectedLanguage == language,
                    onSelected: (_) {
                      setState(() => _selectedLanguage = language);
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: AppSpacing.xl),
              const Divider(),
              const SizedBox(height: AppSpacing.lg),

              // c. Change Password
              Text('Change Password', style: theme.textTheme.titleMedium),
              const SizedBox(height: AppSpacing.sm),
              TextField(
                controller: _currentPasswordController,
                obscureText: _obscureCurrent,
                decoration: InputDecoration(
                  labelText: 'Current Password',
                  prefixIcon: const Icon(Icons.lock_outline),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscureCurrent
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                    ),
                    onPressed: () {
                      setState(() => _obscureCurrent = !_obscureCurrent);
                    },
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              TextField(
                controller: _newPasswordController,
                obscureText: _obscureNew,
                decoration: InputDecoration(
                  labelText: 'New Password',
                  prefixIcon: const Icon(Icons.lock_outline),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscureNew
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                    ),
                    onPressed: () {
                      setState(() => _obscureNew = !_obscureNew);
                    },
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              TextField(
                controller: _confirmPasswordController,
                obscureText: _obscureConfirm,
                decoration: InputDecoration(
                  labelText: 'Confirm New Password',
                  prefixIcon: const Icon(Icons.lock_outline),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscureConfirm
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                    ),
                    onPressed: () {
                      setState(() => _obscureConfirm = !_obscureConfirm);
                    },
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              FilledButton(
                onPressed: _updatePassword,
                child: const Text('Update Password'),
              ),
              const SizedBox(height: AppSpacing.xl),
              const Divider(),
              const SizedBox(height: AppSpacing.lg),

              // d. Order History
              Container(
                key: _orderHistoryKey,
                child: Text(
                  'Order History',
                  style: theme.textTheme.titleMedium,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              for (final order in mockOrders)
                Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                  child: OrderCard(order: order),
                ),
              const SizedBox(height: AppSpacing.xl),

              // e. Log Out
              OutlinedButton.icon(
                onPressed: () => context.go('/login'),
                icon: const Icon(Icons.logout, color: AppColors.alertRed),
                label: const Text(
                  'Log Out',
                  style: TextStyle(color: AppColors.alertRed),
                ),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppColors.alertRed),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
