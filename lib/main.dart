import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:supabase_flutter/supabase_flutter.dart';

import 'data/repositories/auth_repository.dart';
import 'data/repositories/fake_auth_repository.dart';
import 'data/repositories/fake_inventory_repository.dart';
import 'data/repositories/item_repository.dart';
import 'data/repositories/supabase_auth_repository.dart';
import 'data/repositories/transaction_repository.dart';
import 'ui/auth/auth_gate.dart';
import 'ui/auth/session_view_model.dart';
import 'ui/inventory/inventory_screen.dart';
import 'ui/profile/settings_view_model.dart';

/// Supabase keys, passed with `--dart-define-from-file=supabase.json` (see
/// the README). Without them the app runs with fake accounts.
const _supabaseUrl = String.fromEnvironment('SUPABASE_URL');
const _supabaseKey = String.fromEnvironment('SUPABASE_KEY');

/// Composition root: the only place that knows which repository
/// implementations the app uses. Screens ask for the interfaces.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // One instance behind both interfaces: taking stock changes the item and
  // the history together.
  final inventory = FakeInventoryRepository(failureRate: 0.2);
  final auth = await _createAuthRepository();

  runApp(
    MultiProvider(
      providers: [
        Provider<ItemRepository>.value(value: inventory),
        Provider<TransactionRepository>.value(value: inventory),
        Provider<AuthRepository>.value(value: auth),
        ChangeNotifierProvider(create: (_) => SessionViewModel(auth)),
        ChangeNotifierProvider(create: (_) => SettingsViewModel()),
      ],
      child: Consumer<SettingsViewModel>(
        builder: (context, settings, _) =>
            EleStockApp(themeMode: settings.themeMode, home: const AuthGate()),
      ),
    ),
  );
}

Future<AuthRepository> _createAuthRepository() async {
  if (_supabaseUrl.isEmpty || _supabaseKey.isEmpty) {
    debugPrint(
      'No Supabase keys given: using fake accounts '
      '($fakeDemoEmail / $fakeDemoPassword).',
    );
    return FakeAuthRepository(failureRate: 0.1);
  }
  await Supabase.initialize(url: _supabaseUrl, publishableKey: _supabaseKey);
  return SupabaseAuthRepository(Supabase.instance.client.auth);
}

class EleStockApp extends StatelessWidget {
  const EleStockApp({
    super.key,
    this.home = const InventoryScreen(),
    this.themeMode = ThemeMode.system,
  });

  /// The first screen. `main.dart` passes the auth gate; tests that only
  /// need the inventory keep the default.
  final Widget home;
  final ThemeMode themeMode;

  static const _seed = Color.fromARGB(255, 251, 159, 201);
  static const minWidth = 320.0; // Any smaller and the app shits itself - MW

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'EleStock',
      debugShowCheckedModeBanner: false,
      builder: (context, child) => LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth >= minWidth) return child!;
          final media = MediaQuery.of(context);
          return ClipRect(
            child: OverflowBox(
              alignment: Alignment.topLeft,
              minWidth: minWidth,
              maxWidth: minWidth,
              child: MediaQuery(
                data: media.copyWith(size: Size(minWidth, media.size.height)),
                child: child!,
              ),
            ),
          );
        },
      ),
      theme: ThemeData(colorScheme: ColorScheme.fromSeed(seedColor: _seed)),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: _seed,
          brightness: Brightness.dark,
        ),
      ),
      themeMode: themeMode,
      home: home,
    );
  }
}
