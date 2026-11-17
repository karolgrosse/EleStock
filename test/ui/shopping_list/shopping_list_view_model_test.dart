import 'package:elestock/data/repositories/fake_inventory_repository.dart';
import 'package:elestock/domain/models/item.dart';
import 'package:elestock/domain/models/order_entry.dart';
import 'package:elestock/domain/models/stock_transaction.dart';
import 'package:elestock/ui/shopping_list/shopping_list_view_model.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/repositories.dart';

/// Loads fine, but every order and delivery fails to save.
class _SaveFailsRepository extends FakeInventoryRepository {
  _SaveFailsRepository() : super(delay: Duration.zero);

  @override
  Future<OrderEntry> placeOrder({
    required String itemId,
    required int quantity,
    required String memberName,
  }) async => throw Exception('offline');

  @override
  Future<Item> receiveOrder(
    String orderId, {
    required String memberName,
  }) async => throw Exception('offline');
}

ShoppingListViewModel _vm(FakeInventoryRepository repo) =>
    ShoppingListViewModel(items: repo, orders: repo, memberName: 'Tester');

ShoppingListLoaded _loaded(ShoppingListViewModel vm) =>
    vm.state as ShoppingListLoaded;

List<String> _ids(List<ShoppingEntry> entries) =>
    entries.map((e) => e.item.id).toList();

/// Lets the stream event from the repository reach the view model.
Future<void> _settle() async {
  for (var i = 0; i < 5; i++) {
    await Future<void>.delayed(Duration.zero);
  }
}

void main() {
  test('lists only low-stock items, split into to order and ordered', () async {
    final vm = _vm(instantRepository());
    expect(vm.state, isA<ShoppingListLoading>());

    await vm.load();

    final state = _loaded(vm);
    // Crimp contacts are 14 below their level, the sensor is exactly at it.
    expect(_ids(state.toOrder), ['dt-crimp-16', 'tps']);
    // The nyloc nuts ran out and were already ordered in the fake data.
    expect(_ids(state.ordered), ['m5-nyloc']);
    expect(state.toOrder.first.suggestedQuantity, 34);
  });

  test('shows an error when the repository fails', () async {
    final vm = _vm(instantRepository(failureRate: 1));

    await vm.load();

    expect(vm.state, isA<ShoppingListError>());
  });

  test('is loaded but empty when every item is above its level', () async {
    final vm = _vm(
      FakeInventoryRepository(
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

    await vm.load();

    expect(_loaded(vm).entries, isEmpty);
  });

  test('markOrdered() moves the item to ordered and saves the order', () async {
    final repo = instantRepository();
    final vm = _vm(repo);
    await vm.load();

    final result = await vm.markOrdered('dt-crimp-16');

    expect(result, ShoppingActionResult.saved);
    expect(_ids(_loaded(vm).ordered), contains('dt-crimp-16'));
    final saved = (await repo.fetchOrders()).last;
    expect(saved.itemId, 'dt-crimp-16');
    expect(saved.quantity, 34);
    expect(saved.memberName, 'Tester');
  });

  test('markOrdered() moves the item back when saving fails', () async {
    final vm = _vm(_SaveFailsRepository());
    await vm.load();

    final result = await vm.markOrdered('dt-crimp-16');

    expect(result, ShoppingActionResult.failed);
    expect(_ids(_loaded(vm).toOrder), contains('dt-crimp-16'));
    expect(_ids(_loaded(vm).ordered), isNot(contains('dt-crimp-16')));
    expect(vm.isBusy('dt-crimp-16'), isFalse);
  });

  test('markReceived() restocks the item, which leaves the list', () async {
    final repo = instantRepository();
    final vm = _vm(repo);
    await vm.load();

    final result = await vm.markReceived('m5-nyloc');

    expect(result, ShoppingActionResult.saved);
    expect(_ids(_loaded(vm).entries), isNot(contains('m5-nyloc')));
    expect((await repo.fetchItem('m5-nyloc'))!.quantity, 100);
    // The delivery is in the shared history, so the history screen shows it.
    final history = await repo.fetchTransactions(itemId: 'm5-nyloc');
    expect(
      history.where((t) => t.type == TransactionType.restock).single.quantity,
      100,
    );
  });

  test('markReceived() keeps the item as ordered when saving fails', () async {
    final vm = _vm(_SaveFailsRepository());
    await vm.load();

    final result = await vm.markReceived('m5-nyloc');

    expect(result, ShoppingActionResult.failed);
    expect(_ids(_loaded(vm).ordered), ['m5-nyloc']);
  });

  test('an item taken below its level on another screen appears', () async {
    final repo = instantRepository();
    final vm = _vm(repo);
    await vm.load();
    expect(_ids(_loaded(vm).entries), isNot(contains('heatshrink')));

    // 8 m on the shelf, reorder at 5: taking 4 leaves 4.
    await repo.recordTransaction(
      StockTransaction(
        id: 'take-heatshrink',
        itemId: 'heatshrink',
        memberName: 'Ola Nowak',
        type: TransactionType.take,
        quantity: 4,
        timestamp: DateTime(2026, 11, 17, 12),
      ),
    );
    await _settle();

    expect(_ids(_loaded(vm).toOrder), contains('heatshrink'));
  });
}
