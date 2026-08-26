import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/network/api_exception.dart';
import '../../../../core/state/current_user_controller.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../auth/data/auth_repository.dart';
import '../../../auth/domain/auth_user.dart';
import '../../domain/user_profile.dart';
import '../widgets/order_card.dart';

/// Maps the `preferred_language` code the backend stores (see
/// RegisterRequest.preferred_language) to the native-script chip label
/// shown in the UI, and back again when sending an update.
const Map<String, String> _languageLabelsByCode = {
  'si': 'සිංහල',
  'ta': 'தமிழ்',
  'en': 'English',
};
const Map<String, String> _languageCodesByLabel = {
  'සිංහල': 'si',
  'தமிழ்': 'ta',
  'English': 'en',
};

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({this.scrollToOrderHistory = false, super.key});

  final bool scrollToOrderHistory;

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();

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

  bool _didRequestLoad = false;
  int? _syncedUserId;

  bool _isSavingProfile = false;
  bool _isUpdatingLanguage = false;
  bool _isChangingPassword = false;

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
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_didRequestLoad) return;
    _didRequestLoad = true;
    final CurrentUserController controller = CurrentUserScope.of(context);
    // Deferred to a microtask so the controller's first notifyListeners()
    // (isLoading = true) never fires synchronously from within another
    // element's didChangeDependencies/build pass.
    Future.microtask(controller.load);
  }

  void _syncControllersWith(AuthUser user) {
    if (_syncedUserId == user.userId) return;
    _syncedUserId = user.userId;
    _nameController.text = user.fullName;
    _emailController.text = user.email;
    _phoneController.text = user.phoneNumber ?? '';
    _selectedLanguage =
        _languageLabelsByCode[user.preferredLanguage] ?? 'English';
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

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? AppColors.alertRed : null,
        duration: Duration(seconds: isError ? 6 : 4),
      ),
    );
  }

  Future<void> _saveProfile() async {
    setState(() => _isSavingProfile = true);
    try {
      await CurrentUserScope.of(context).updateProfile(
        fullName: _nameController.text.trim(),
        phoneNumber: _phoneController.text.trim(),
      );
      if (!mounted) return;
      _showSnackBar('Profile updated');
    } on ApiException catch (error) {
      if (!mounted) return;
      _showSnackBar(error.message, isError: true);
    } finally {
      if (mounted) setState(() => _isSavingProfile = false);
    }
  }

  Future<void> _selectLanguage(String language) async {
    if (_isUpdatingLanguage || language == _selectedLanguage) return;
    final String previousLanguage = _selectedLanguage;
    setState(() {
      _selectedLanguage = language;
      _isUpdatingLanguage = true;
    });
    try {
      await CurrentUserScope.of(
        context,
      ).updateProfile(preferredLanguage: _languageCodesByLabel[language]);
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() => _selectedLanguage = previousLanguage);
      _showSnackBar(
        "Couldn't update language: ${error.message}",
        isError: true,
      );
    } finally {
      if (mounted) setState(() => _isUpdatingLanguage = false);
    }
  }

  Future<void> _updatePassword() async {
    if (_currentPasswordController.text.isEmpty ||
        _newPasswordController.text.isEmpty) {
      _showSnackBar('Please fill in all password fields.', isError: true);
      return;
    }
    if (_newPasswordController.text != _confirmPasswordController.text) {
      _showSnackBar(
        "New password and confirmation don't match.",
        isError: true,
      );
      return;
    }

    setState(() => _isChangingPassword = true);
    try {
      await AuthRepository().changePassword(
        currentPassword: _currentPasswordController.text,
        newPassword: _newPasswordController.text,
      );
      if (!mounted) return;
      _showSnackBar('Password updated');
      _currentPasswordController.clear();
      _newPasswordController.clear();
      _confirmPasswordController.clear();
    } on ApiException catch (error) {
      if (!mounted) return;
      _showSnackBar(error.message, isError: true);
    } finally {
      if (mounted) setState(() => _isChangingPassword = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final CurrentUserController userController = CurrentUserScope.of(context);
    final AuthUser? user = userController.user;

    if (user != null) _syncControllersWith(user);

    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: SafeArea(
        child: user == null
            ? _buildUnloadedState(userController)
            : _buildForm(theme),
      ),
    );
  }

  Widget _buildUnloadedState(CurrentUserController userController) {
    if (userController.errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.error_outline,
                color: AppColors.alertRed,
                size: 40,
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(userController.errorMessage!, textAlign: TextAlign.center),
              const SizedBox(height: AppSpacing.md),
              FilledButton(
                onPressed: () => userController.load(force: true),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }
    return const Center(child: CircularProgressIndicator());
  }

  Widget _buildForm(ThemeData theme) {
    return SingleChildScrollView(
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
            enabled: false,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(
              labelText: 'Email',
              helperText: "Email can't be changed",
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
            onPressed: _isSavingProfile ? null : _saveProfile,
            child: _isSavingProfile
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Save Changes'),
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
                onSelected: _isUpdatingLanguage
                    ? null
                    : (_) => _selectLanguage(language),
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
            onPressed: _isChangingPassword ? null : _updatePassword,
            child: _isChangingPassword
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Update Password'),
          ),
          const SizedBox(height: AppSpacing.xl),
          const Divider(),
          const SizedBox(height: AppSpacing.lg),

          // d. Order History
          Container(
            key: _orderHistoryKey,
            child: Text('Order History', style: theme.textTheme.titleMedium),
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
            onPressed: () async {
              await AuthRepository().logout();
              if (!mounted) return;
              CurrentUserScope.of(context).clear();
              context.go('/login');
            },
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
    );
  }
}
