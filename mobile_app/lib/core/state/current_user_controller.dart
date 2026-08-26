import 'package:flutter/material.dart';

import '../../features/auth/data/auth_repository.dart';
import '../../features/auth/domain/auth_user.dart';
import '../network/api_exception.dart';

/// Lives above the whole app (see [CurrentUserScope], wrapped around
/// `MaterialApp.router` in app.dart) for the same reason as
/// [CartController]: the logged-in user's data is needed both from a
/// shell-branch screen (Dashboard's profile-preview sheet) and from a
/// top-level route declared outside the shell (`/profile`), which don't
/// share a common ancestor below MaterialApp.router.
///
/// Caches a single `/auth/me` fetch so both call sites read the same data
/// instead of issuing their own duplicate requests.
class CurrentUserController extends ChangeNotifier {
  CurrentUserController({AuthRepository? authRepository})
    : _authRepository = authRepository ?? AuthRepository();

  final AuthRepository _authRepository;

  AuthUser? _user;
  bool _isLoading = false;
  String? _errorMessage;

  AuthUser? get user => _user;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> load({bool force = false}) async {
    if (_isLoading || (_user != null && !force)) return;

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _user = await _authRepository.getCurrentUser();
    } on ApiException catch (error) {
      _errorMessage = error.message;
    } catch (_) {
      _errorMessage = 'Something went wrong. Please try again.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Calls `PATCH /auth/me` with whichever fields are provided and
  /// replaces the cached user with the server's response on success, so
  /// every reader (Profile screen, preview sheet) reflects the change
  /// immediately without a re-fetch. Rethrows on failure so callers can
  /// show their own error feedback; the cache is left untouched.
  Future<void> updateProfile({
    String? fullName,
    String? phoneNumber,
    String? preferredLanguage,
  }) async {
    final AuthUser updated = await _authRepository.updateProfile(
      fullName: fullName,
      phoneNumber: phoneNumber,
      preferredLanguage: preferredLanguage,
    );
    _user = updated;
    _errorMessage = null;
    notifyListeners();
  }

  void clear() {
    _user = null;
    _errorMessage = null;
    _isLoading = false;
    notifyListeners();
  }
}

class CurrentUserScope extends InheritedNotifier<CurrentUserController> {
  const CurrentUserScope({
    required CurrentUserController controller,
    required super.child,
    super.key,
  }) : super(notifier: controller);

  static CurrentUserController of(BuildContext context) {
    final CurrentUserScope? scope = context
        .dependOnInheritedWidgetOfExactType<CurrentUserScope>();
    assert(scope != null, 'CurrentUserScope not found in context');
    return scope!.notifier!;
  }
}
