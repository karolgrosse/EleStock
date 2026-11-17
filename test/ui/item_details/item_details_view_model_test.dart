import 'package:elestock/data/repositories/fake_inventory_repository.dart';
import 'package:elestock/domain/models/item.dart';
import 'package:elestock/domain/models/stock_transaction.dart';
import 'package:elestock/ui/item_details/item_details_view_model.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/repositories.dart';

/// Loads fine, but every save fails (e.g. the connection dropped).
class _SaveFailsRepository extends FakeInventoryRepository {
  _SaveFailsRepository() : super(delay: Duration.zero);

  @override
  Future<Item> recordTransaction(StockTransaction transaction) async =>
      throw Exception('offline');
}

ItemDetailsViewModel _vm(
  String itemId,
  FakeInventoryRepository repo, {
  DateTime? now,
}) => ItemDetailsViewModel(
  itemId: itemId,
  items: repo,
  transactions: repo,
  memberName: 'Tester',
  clock: () => now ?? DateTime(2026, 11, 17, 12),
);

ItemDetailsLoaded _loaded(ItemDetailsViewModel vm) =>
    vm.state as ItemDetailsLoaded;

void main() {
  group('load()', () {
    test(
      'starts loading, then shows the item with its history newest first',
      () async {
        final vm = _vm('dt-crimp-16', instantRepository());
        expect(vm.state, isA<ItemDetailsLoading>());

        await vm.load();

        final state = _loaded(vm);
        expect(state.item.quantity, 6);
        expect(state.history.map((t) => t.id), ['t1', 't6']);
      },
    );

    test('shows an error when the repository fails', () async {
      final vm = _vm('dt-crimp-16', instantRepository(failureRate: 1));

      await vm.load();

      expect(vm.state, isA<ItemDetailsError>());
    });

    test('says "not found" for an unknown id', () async {
      final vm = _vm('flux-capacitor', instantRepository());

      await vm.load();

      expect(vm.state, isA<ItemDetailsNotFound>());
    });
  });

  group('take() and putBack()', () {
    test('take(4) lowers the stock and records the transaction', () async {
      final repo = instantRepository();
      final vm = _vm('dt-crimp-16', repo);
      await vm.load();

      final result = await vm.take(4, note: 'Harness');

      expect(result, StockChangeResult.saved);
      expect(_loaded(vm).item.quantity, 2);
      final newest = _loaded(vm).history.first;
      expect(newest.type, TransactionType.take);
      expect(newest.memberName, 'Tester');
      expect(newest.note, 'Harness');
      // The repository has it too, so other screens see it.
      expect((await repo.fetchItem('dt-crimp-16'))!.quantity, 2);
      expect(await repo.fetchTransactions(itemId: 'dt-crimp-16'), hasLength(3));
    });

    test('putBack(3) raises the stock', () async {
      final vm = _vm('m5-nyloc', instantRepository());
      await vm.load();

      await vm.putBack(3);

      expect(_loaded(vm).item.quantity, 3);
      expect(_loaded(vm).item.isOutOfStock, isFalse);
    });

    test('taking more than is in stock changes nothing', () async {
      final repo = instantRepository();
      final vm = _vm('tps', repo);
      await vm.load();

      final result = await vm.take(5);

      expect(result, StockChangeResult.notEnoughStock);
      expect(_loaded(vm).item.quantity, 2);
      expect(await repo.fetchTransactions(itemId: 'tps'), hasLength(1));
    });

    test('rolls back when saving fails', () async {
      final vm = _vm('dt-crimp-16', _SaveFailsRepository());
      await vm.load();

      final result = await vm.take(4);

      expect(result, StockChangeResult.failed);
      expect(_loaded(vm).item.quantity, 6);
      expect(_loaded(vm).history.map((t) => t.id), ['t1', 't6']);
      expect(vm.isSaving, isFalse);
    });
  });

  test('a take on one screen is visible on another (shared state)', () async {
    final repo = instantRepository();
    final phone = _vm('heatshrink', repo);
    final tablet = _vm('heatshrink', repo);
    await phone.load();
    await tablet.load();

    await phone.take(3);
    await Future<void>.delayed(Duration.zero); // let the update stream deliver

    expect(_loaded(tablet).item.quantity, 5);
    expect(_loaded(tablet).item.isLowStock, isTrue);
  });
}
