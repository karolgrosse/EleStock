import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/models/member.dart';
import 'auth_repository.dart';

/// [AuthRepository] backed by Supabase Auth (email and password).
///
/// Supabase keeps the session on the device and refreshes it, so a member
/// stays logged in between app starts.
class SupabaseAuthRepository implements AuthRepository {
  SupabaseAuthRepository(this._auth);

  final GoTrueClient _auth;

  @override
  Member? get currentMember => _toMember(_auth.currentUser);

  @override
  Stream<Member?> get memberChanges => _auth.onAuthStateChange
      .map((state) => _toMember(state.session?.user))
      .distinct();

  @override
  Future<Member> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _auth.signInWithPassword(
        email: email.trim(),
        password: password,
      );
      final member = _toMember(response.user);
      if (member == null) throw const InvalidCredentialsException();
      return member;
    } on AuthApiException catch (e) {
      if (e.code == 'invalid_credentials') {
        throw const InvalidCredentialsException();
      }
      rethrow;
    }
  }

  @override
  Future<void> signOut() => _auth.signOut();

  /// The display name is the `name` field of the user metadata (set it in the
  /// dashboard), or the part of the email before the @.
  static Member? _toMember(User? user) {
    if (user == null) return null;
    final email = user.email ?? '';
    final name = user.userMetadata?['name'];
    return Member(
      id: user.id,
      email: email,
      displayName: name is String && name.trim().isNotEmpty
          ? name.trim()
          : email.split('@').first,
    );
  }
}
