import 'package:elestock/ui/auth/login_view_model.dart';
import 'package:elestock/ui/auth/session_view_model.dart';
import 'package:elestock/ui/profile/settings_view_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/auth.dart';

void main() {
  group('LoginViewModel', () {
    test('signs in with the right password', () async {
      final auth = instantAuth();
      final vm = LoginViewModel(auth);

      final ok = await vm.signIn(
        email: testMember.email,
        password: testPassword,
      );

      expect(ok, isTrue);
      expect(vm.state, isA<LoginIdle>());
      expect(auth.currentMember, testMember);
    });

    test('says so when the password is wrong', () async {
      final vm = LoginViewModel(instantAuth());

      final ok = await vm.signIn(email: testMember.email, password: 'nope');

      expect(ok, isFalse);
      expect(
        vm.state,
        isA<LoginFailed>().having(
          (s) => s.message,
          'message',
          contains('Wrong email or password'),
        ),
      );
    });

    test('reports a connection problem when the server fails', () async {
      final vm = LoginViewModel(instantAuth(failureRate: 1));

      await vm.signIn(email: testMember.email, password: testPassword);

      expect(
        vm.state,
        isA<LoginFailed>().having(
          (s) => s.message,
          'message',
          contains('Could not reach the server'),
        ),
      );
    });

    test('does not call the server for an invalid email', () async {
      final auth = instantAuth(failureRate: 1);
      final vm = LoginViewModel(auth);

      final ok = await vm.signIn(email: 'not-an-email', password: 'x');

      expect(ok, isFalse);
      expect(vm.state, isA<LoginIdle>());
    });

    test('validates the fields', () {
      expect(LoginViewModel.validateEmail(''), isNotNull);
      expect(LoginViewModel.validateEmail('ola@team'), isNotNull);
      expect(LoginViewModel.validateEmail(' ola@team.pl '), isNull);
      expect(LoginViewModel.validatePassword(''), isNotNull);
    });
  });

  group('SessionViewModel', () {
    test('starts with a session saved on the device', () {
      final vm = SessionViewModel(instantAuth(signedIn: true));
      expect(vm.member, testMember);
    });

    test('follows sign-in and sign-out', () async {
      final auth = instantAuth();
      final vm = SessionViewModel(auth);
      expect(vm.isSignedIn, isFalse);

      await auth.signIn(email: testMember.email, password: testPassword);
      await pumpEventQueue();
      expect(vm.member, testMember);

      expect(await vm.signOut(), isTrue);
      await pumpEventQueue();
      expect(vm.isSignedIn, isFalse);
    });

    test('stays signed in when signing out fails', () async {
      final vm = SessionViewModel(instantAuth(signedIn: true, failureRate: 1));

      expect(await vm.signOut(), isFalse);
      expect(vm.member, testMember);
      expect(vm.isSigningOut, isFalse);
    });
  });

  group('SettingsViewModel', () {
    test('changes the theme and notifies once', () {
      final vm = SettingsViewModel();
      var notified = 0;
      vm.addListener(() => notified++);

      vm.setThemeMode(ThemeMode.dark);
      vm.setThemeMode(ThemeMode.dark);

      expect(vm.themeMode, ThemeMode.dark);
      expect(notified, 1);
    });
  });
}
