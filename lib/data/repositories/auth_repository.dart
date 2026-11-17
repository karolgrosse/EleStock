import '../../domain/models/member.dart';

/// Thrown by [AuthRepository.signIn] when the email or password is wrong.
/// Any other exception means the sign-in could not be checked (no network,
/// server down).
class InvalidCredentialsException implements Exception {
  const InvalidCredentialsException();

  @override
  String toString() => 'InvalidCredentialsException';
}

/// Who is logged in. The app depends on this contract only.
///
/// `main.dart` picks [SupabaseAuthRepository] when Supabase keys are given,
/// otherwise [FakeAuthRepository]. Accounts are created by the team lead in
/// the Supabase dashboard; there is no public sign-up.
abstract interface class AuthRepository {
  /// The member logged in right now, or null. A session saved on the device
  /// counts, so this can be non-null straight after the app starts.
  Member? get currentMember;

  /// Emits the member after every sign-in and null after every sign-out
  /// (including a session that expired).
  Stream<Member?> get memberChanges;

  /// Throws [InvalidCredentialsException] for a wrong email or password.
  Future<Member> signIn({required String email, required String password});

  Future<void> signOut();
}
