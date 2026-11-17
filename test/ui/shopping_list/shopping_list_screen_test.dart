import 'package:elestock/data/repositories/fake_inventory_repository.dart';
import 'package:elestock/domain/models/item.dart';
import 'package:elestock/ui/core/widgets/error_view.dart';
import 'package:elestock/ui/shopping_list/shopping_list_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/repositories.dart';

/// Fails to load until [fail] is set to false, to test Retry.
class _FlakyRepository extends FakeInventoryRepository {
  _FlakyRepository() : super(delay: Duration.zero);

  bool fail = true;

  @override
  Future<List<Item>> fetchItems() async {
    if (fail) throw Exception('offline');
    return super.fetchItems();
  }
}

Future<void> _pumpShoppingList(
  WidgetTester tester, {
  FakeInventoryRepository? repository,
}) async {
  tester.view.physicalSize = const Size(600, 2000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    withRepository(
      const MaterialApp(home: ShoppingListScreen()),
      repository: repository,
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('shows what to order and what is on its way', (tester) async {
    await _pumpShoppingList(tester);

    expect(find.text('To order (2)'), findsOneWidget);
    expect(find.text('Ordered (1)'), findsOneWidget);
    expect(find.text('Order 34 pcs'), findsOneWidget);
    expect(find.text('M5 nyloc nut'), findsOneWidget);
    expect(find.text('Received'), findsOneWidget);
  });

  testWidgets('shows the error with Retry, and Retry loads the list', (
    tester,
  ) async {
    final repo = _FlakyRepository();
    await _pumpShoppingList(tester, repository: repo);

    expect(find.byType(ErrorView), findsOneWidget);

    repo.fail = false;
    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();

    expect(find.byType(ErrorView), findsNothing);
    expect(find.text('To order (2)'), findsOneWidget);
  });

  testWidgets('tapping Order moves the item to Ordered', (tester) async {
    await _pumpShoppingList(tester);

    await tester.tap(find.text('Order 34 pcs'));
    await tester.pumpAndSettle();

    expect(find.text('To order (1)'), findsOneWidget);
    expect(find.text('Ordered (2)'), findsOneWidget);
    expect(find.text('Ordered 34 pcs'), findsOneWidget); // the SnackBar
  });

  testWidgets('shows the empty state when nothing is low', (tester) async {
    await _pumpShoppingList(
      tester,
      repository: FakeInventoryRepository(
        delay: Duration.zero,
        orders: const [],
        items: const [
          Item(
            id: 'bolt',
            name: 'Bolt',
            category: ItemCategory.fasteners,
            location: 'Drawer 1',
            quantity: 50,
            unit: 'pcs',
            lowStockThreshold: 10,
          ),
        ],
      ),
    );

    expect(
      find.text('Nothing to buy. Every item is above its reorder level.'),
      findsOneWidget,
    );
  });
}
