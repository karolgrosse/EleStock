import 'package:elestock/data/repositories/auth_repository.dart';
import 'package:elestock/data/repositories/fake_auth_repository.dart';
import 'package:elestock/domain/models/member.dart';
import 'package:elestock/ui/auth/session_view_model.dart';
import 'package:elestock/ui/profile/settings_view_model.dart';
import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';

import 'repositories.dart';

const testMember = Member(
  id: 'ola',
  email: 'ola@team.pl',
  displayName: 'Ola Nowak',
);
const testPassword = 'secret';

/// A fake that answers at once and never fails, unless told otherwise.
FakeAuthRepository instantAuth({
  bool signedIn = false,
  double failureRate = 0,
}) => FakeAuthRepository(
  accounts: {testMember.email: (password: testPassword, member: testMember)},
  signedIn: signedIn ? testMember : null,
  delay: Duration.zero,
  failureRate: failureRate,
);

/// Provides everything `main.dart` provides: inventory, auth, session and
/// settings.
Widget withApp(
  Widget child, {
  AuthRepository? auth,
  SettingsViewModel? settings,
}) {
  final authRepo = auth ?? instantAuth();
  return withRepository(
    MultiProvider(
      providers: [
        Provider<AuthRepository>.value(value: authRepo),
        ChangeNotifierProvider(create: (_) => SessionViewModel(authRepo)),
        ChangeNotifierProvider.value(value: settings ?? SettingsViewModel()),
      ],
      child: child,
    ),
  );
}
