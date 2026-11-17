import 'package:elestock/data/repositories/fake_inventory_repository.dart';
import 'package:elestock/data/repositories/item_repository.dart';
import 'package:elestock/data/repositories/transaction_repository.dart';
import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';

/// A fake that answers at once and never fails, unless told otherwise.
FakeInventoryRepository instantRepository({double failureRate = 0}) =>
    FakeInventoryRepository(delay: Duration.zero, failureRate: failureRate);

/// Provides [repository] the same way `main.dart` does.
Widget withRepository(Widget child, {FakeInventoryRepository? repository}) {
  final repo = repository ?? instantRepository();
  return MultiProvider(
    providers: [
      Provider<ItemRepository>.value(value: repo),
      Provider<TransactionRepository>.value(value: repo),
    ],
    child: child,
  );
}
