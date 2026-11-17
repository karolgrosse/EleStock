import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'data/repositories/fake_inventory_repository.dart';
import 'data/repositories/item_repository.dart';
import 'data/repositories/transaction_repository.dart';
import 'ui/inventory/inventory_screen.dart';

/// Composition root: the only place that knows which repository
/// implementations the app uses. Screens ask for the interfaces.
void main() {
  // One instance behind both interfaces: taking stock changes the item and
  // the history together.
  final inventory = FakeInventoryRepository(failureRate: 0.2);

  runApp(
    MultiProvider(
      providers: [
        Provider<ItemRepository>.value(value: inventory),
        Provider<TransactionRepository>.value(value: inventory),
      ],
      child: const EleStockApp(),
    ),
  );
}

class EleStockApp extends StatelessWidget {
  const EleStockApp({super.key});

  static const _seed = Color.fromARGB(255, 251, 159, 201);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'EleStock',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(colorScheme: ColorScheme.fromSeed(seedColor: _seed)),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: _seed,
          brightness: Brightness.dark,
        ),
      ),
      home: const InventoryScreen(),
    );
  }
}
