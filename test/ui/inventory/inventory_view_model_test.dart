import 'package:elestock/data/repositories/fake_inventory_repository.dart';
import 'package:elestock/domain/models/item.dart';
import 'package:elestock/domain/models/stock_transaction.dart';
import 'package:elestock/ui/inventory/inventory_view_model.dart';
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

InventoryViewModel _vm(FakeInventoryRepository repo) =>
    InventoryViewModel(items: repo);

List<String> _visibleIds(InventoryViewModel vm) =>
    vm.visibleItems.map((i) => i.id).toList();

void main() {
  group('load()', () {
    test('starts loading, then shows every item', () async {
      final vm = _vm(instantRepository());
      expect(vm.state, isA<InventoryLoading>());

      await vm.load();

      final state = vm.state as InventoryLoaded;
      expect(state.items, hasLength(greaterThan(5)));
      expect(vm.visibleItems, state.items);
    });

    test('shows an error when the repository fails', () async {
      final vm = _vm(instantRepository(failureRate: 1));

      await vm.load();

      expect(vm.state, isA<InventoryError>());
      expect(vm.visibleItems, isEmpty);
    });

    test('retry after an error loads the items', () async {
      final repo = _FlakyRepository();
      final vm = _vm(repo);
      await vm.load();
      expect(vm.state, isA<InventoryError>());

      repo.fail = false;
      await vm.load();

      expect(vm.state, isA<InventoryLoaded>());
    });

    test('an empty workshop is loaded with no items', () async {
      final vm = _vm(FakeInventoryRepository(items: [], delay: Duration.zero));

      await vm.load();

      expect((vm.state as InventoryLoaded).items, isEmpty);
    });
  });

  group('search and filter', () {
    test('search matches names case-insensitively', () async {
      final vm = _vm(instantRepository());
      await vm.load();

      vm.search('  DEUTSCH ');

      expect(_visibleIds(vm), containsAll(['dt-crimp-16', 'dt-04-housing']));
      expect(vm.visibleItems.every((i) => i.name.contains('Deutsch')), isTrue);
    });

    test('category filter combines with the search text', () async {
      final vm = _vm(instantRepository());
      await vm.load();

      vm.filterBy(ItemCategory.fasteners);
      expect(
        vm.visibleItems.every((i) => i.category == ItemCategory.fasteners),
        isTrue,
      );

      vm.search('nyloc');
      expect(_visibleIds(vm), ['m5-nyloc']);

      vm.filterBy(null);
      vm.search('');
      expect(vm.visibleItems, (vm.state as InventoryLoaded).items);
    });

    test('notifies listeners only when something changes', () async {
      final vm = _vm(instantRepository());
      await vm.load();
      var notifications = 0;
      vm.addListener(() => notifications++);

      vm.search('bolt');
      vm.search('bolt');
      vm.select('m6-bolt');
      vm.select('m6-bolt');

      expect(notifications, 2);
      expect(vm.selectedId, 'm6-bolt');
    });
  });

  test('a stock change elsewhere updates the item in the list', () async {
    final repo = instantRepository();
    final vm = _vm(repo);
    await vm.load();

    // The details screen records "Take 20" through the same repository.
    await repo.recordTransaction(
      StockTransaction(
        id: 'test-take',
        itemId: 'm6-bolt',
        memberName: 'Tester',
        type: TransactionType.take,
        quantity: 20,
        timestamp: DateTime(2026, 11, 17),
      ),
    );
    await pumpEventQueue();

    final bolt = vm.visibleItems.singleWhere((i) => i.id == 'm6-bolt');
    expect(bolt.quantity, 100);
  });

  test('ignores updates and results after dispose', () async {
    final repo = FakeInventoryRepository(
      delay: const Duration(milliseconds: 10),
    );
    final vm = _vm(repo);
    final loading = vm.load();

    vm.dispose();

    // Would throw "used after being disposed" if it still notified.
    await expectLater(loading, completes);
  });
}
