import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../data/repositories/auth_repository.dart';
import '../../domain/models/member.dart';

/// Who is logged in, for the whole app.
///
/// Created once in `main.dart`. The auth gate shows the login screen or the
/// app depending on [member]; the profile shows it and signs out.
class SessionViewModel extends ChangeNotifier {
  SessionViewModel(this._auth) : _member = _auth.currentMember {
    _subscription = _auth.memberChanges.listen((member) {
      if (member == _member) return;
      _member = member;
      _notify();
    });
  }

  final AuthRepository _auth;
  late final StreamSubscription<Member?> _subscription;
  bool _disposed = false;

  Member? _member;
  Member? get member => _member;
  bool get isSignedIn => _member != null;

  bool _signingOut = false;
  bool get isSigningOut => _signingOut;

  /// Returns false when signing out failed; the member stays logged in.
  Future<bool> signOut() async {
    _signingOut = true;
    _notify();
    try {
      await _auth.signOut();
      return true;
    } catch (_) {
      return false;
    } finally {
      _signingOut = false;
      _notify();
    }
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _subscription.cancel();
    super.dispose();
  }
}
