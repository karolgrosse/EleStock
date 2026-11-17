import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';

import '../../data/repositories/auth_repository.dart';

/// What the login screen shows under the form. Exactly one at a time.
sealed class LoginState {
  const LoginState();
}

final class LoginIdle extends LoginState {
  const LoginIdle();
}

final class LoginSubmitting extends LoginState {
  const LoginSubmitting();
}

final class LoginFailed extends LoginState {
  const LoginFailed(this.message);

  final String message;
}

/// Signs a member in. On success the [SessionViewModel] hears about it from
/// the repository and the auth gate switches to the app, so this view model
/// never navigates.
class LoginViewModel extends ChangeNotifier {
  LoginViewModel(this._auth);

  /// Creates the view model from the repository provided in `main.dart`.
  factory LoginViewModel.of(BuildContext context) =>
      LoginViewModel(context.read<AuthRepository>());

  final AuthRepository _auth;
  bool _disposed = false;

  LoginState _state = const LoginIdle();
  LoginState get state => _state;

  /// Field rules, used by the form and by [signIn].
  static String? validateEmail(String? value) {
    final email = value?.trim() ?? '';
    if (email.isEmpty) return 'Enter your email';
    if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email)) {
      return 'This is not an email address';
    }
    return null;
  }

  static String? validatePassword(String? value) =>
      (value == null || value.isEmpty) ? 'Enter your password' : null;

  /// Returns true when the member is signed in.
  Future<bool> signIn({required String email, required String password}) async {
    if (_state is LoginSubmitting) return false;
    if (validateEmail(email) != null || validatePassword(password) != null) {
      return false;
    }
    _setState(const LoginSubmitting());
    try {
      await _auth.signIn(email: email, password: password);
      _setState(const LoginIdle());
      return true;
    } on InvalidCredentialsException {
      _setState(const LoginFailed('Wrong email or password.'));
    } catch (_) {
      _setState(
        const LoginFailed('Could not reach the server. Check your connection.'),
      );
    }
    return false;
  }

  void _setState(LoginState state) {
    _state = state;
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
