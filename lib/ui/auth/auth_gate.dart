import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../shell/app_shell.dart';
import 'login_screen.dart';
import 'session_view_model.dart';

/// Shows the login screen until a member is signed in, then the app.
///
/// Signing out anywhere brings the login screen back. In lab 3 this becomes
/// a go_router redirect to `/login`.
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    final signedIn = context.select<SessionViewModel, bool>(
      (session) => session.isSignedIn,
    );
    return signedIn ? const AppShell() : const LoginScreen();
  }
}
