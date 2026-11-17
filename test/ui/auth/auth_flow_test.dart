import 'package:elestock/main.dart';
import 'package:elestock/ui/auth/auth_gate.dart';
import 'package:elestock/ui/auth/login_screen.dart';
import 'package:elestock/ui/profile/settings_view_model.dart';
import 'package:elestock/ui/shell/app_shell.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/auth.dart';

void setScreenSize(WidgetTester tester, Size size) {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}

Future<void> _logIn(WidgetTester tester, String password) async {
  await tester.enterText(
    find.widgetWithText(TextFormField, 'Email'),
    testMember.email,
  );
  await tester.enterText(
    find.widgetWithText(TextFormField, 'Password'),
    password,
  );
  await tester.tap(find.widgetWithText(FilledButton, 'Log in'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('wrong password shows an error and stays on login', (
    tester,
  ) async {
    setScreenSize(tester, const Size(390, 844));
    await tester.pumpWidget(withApp(const EleStockApp(home: AuthGate())));

    await _logIn(tester, 'wrong');

    expect(find.text('Wrong email or password.'), findsOneWidget);
    expect(find.byType(LoginScreen), findsOneWidget);
  });

  testWidgets('logging in opens the app, logging out returns to login', (
    tester,
  ) async {
    setScreenSize(tester, const Size(390, 844));
    await tester.pumpWidget(withApp(const EleStockApp(home: AuthGate())));

    await _logIn(tester, testPassword);
    expect(find.byType(AppShell), findsOneWidget);
    expect(find.byType(NavigationBar), findsOneWidget);

    await tester.tap(find.text('Profile'));
    await tester.pumpAndSettle();
    expect(find.text('Ola Nowak'), findsOneWidget);

    await tester.tap(find.text('Log out'));
    await tester.pumpAndSettle();
    expect(find.byType(LoginScreen), findsOneWidget);
  });

  testWidgets('wide window uses a navigation rail', (tester) async {
    setScreenSize(tester, const Size(1280, 800));
    await tester.pumpWidget(
      withApp(
        const EleStockApp(home: AuthGate()),
        auth: instantAuth(signedIn: true),
      ),
    );
    await tester.pump();

    expect(find.byType(NavigationRail), findsOneWidget);
    expect(find.byType(NavigationBar), findsNothing);
  });

  testWidgets('choosing Dark on the profile changes the app theme', (
    tester,
  ) async {
    setScreenSize(tester, const Size(390, 844));
    final settings = SettingsViewModel();
    await tester.pumpWidget(
      withApp(
        // Same wiring as main.dart: the app rebuilds when settings change.
        ListenableBuilder(
          listenable: settings,
          builder: (_, _) => EleStockApp(
            themeMode: settings.themeMode,
            home: const AuthGate(),
          ),
        ),
        auth: instantAuth(signedIn: true),
        settings: settings,
      ),
    );
    await tester.tap(find.text('Profile'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Dark'));
    await tester.pumpAndSettle();

    final app = tester.widget<MaterialApp>(find.byType(MaterialApp));
    expect(app.themeMode, ThemeMode.dark);
  });
}
