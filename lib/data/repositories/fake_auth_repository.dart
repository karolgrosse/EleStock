import 'dart:async';
import 'dart:math';

import '../../domain/models/member.dart';
import 'auth_repository.dart';

/// Demo account of [FakeAuthRepository], listed in the README.
const fakeDemoEmail = 'demo@elestock.dev';
const fakeDemoPassword = 'elestock';

/// In-memory accounts with a network-like [delay] and random failures.
///
/// Used in tests, and in the app when no Supabase keys are given, so that
/// nobody needs keys to work on their own screens.
class FakeAuthRepository implements AuthRepository {
  FakeAuthRepository({
    Map<String, ({String password, Member member})>? accounts,
    Member? signedIn,
    this.delay = const Duration(milliseconds: 800),
    this.failureRate = 0.0,
    Random? random,
  }) : assert(failureRate >= 0 && failureRate <= 1),
       _accounts = accounts ?? _demoAccounts,
       _current = signedIn,
       _random = random ?? Random();

  static final _demoAccounts = {
    fakeDemoEmail: (
      password: fakeDemoPassword,
      member: const Member(
        id: 'demo',
        email: fakeDemoEmail,
        displayName: 'Demo Member',
      ),
    ),
  };

  /// How long every call takes.
  final Duration delay;

  /// 0.0 never fails, 1.0 always fails.
  final double failureRate;

  final Map<String, ({String password, Member member})> _accounts;
  final Random _random;
  final _changes = StreamController<Member?>.broadcast();
  Member? _current;

  Future<void> _simulateNetwork() async {
    await Future<void>.delayed(delay);
    if (failureRate > 0 && _random.nextDouble() < failureRate) {
      throw Exception('Simulated network failure');
    }
  }

  @override
  Member? get currentMember => _current;

  @override
  Stream<Member?> get memberChanges => _changes.stream;

  @override
  Future<Member> signIn({
    required String email,
    required String password,
  }) async {
    await _simulateNetwork();
    final account = _accounts[email.trim().toLowerCase()];
    if (account == null || account.password != password) {
      throw const InvalidCredentialsException();
    }
    _set(account.member);
    return account.member;
  }

  @override
  Future<void> signOut() async {
    await _simulateNetwork();
    _set(null);
  }

  void _set(Member? member) {
    _current = member;
    _changes.add(member);
  }

  void dispose() => _changes.close();
}
