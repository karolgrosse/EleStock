import 'package:elestock/data/repositories/fake_inventory_repository.dart';
import 'package:elestock/domain/models/stock_transaction.dart';
import 'package:elestock/ui/history/history_view_model.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/repositories.dart';

/// Loads fine until [fail] is set, then every history fetch fails.
class _FlakyRepository extends FakeInventoryRepository {
  _FlakyRepository() : super(delay: Duration.zero);

  bool fail = false;

  @override
  Future<List<StockTransaction>> fetchTransactions({String? itemId}) async {
    if (fail) throw Exception('offline');
    return super.fetchTransactions(itemId: itemId);
  }
}

HistoryViewModel _vm(FakeInventoryRepository repo) =>
    HistoryViewModel(items: repo, transactions: repo);

List<String> _ids(HistoryViewModel vm) =>
    vm.visibleEntries.map((e) => e.transaction.id).toList();

/// Lets the stream event and the reload it triggers finish.
Future<void> _settle() async {
  for (var i = 0; i < 5; i++) {
    await Future<void>.delayed(Duration.zero);
  }
}

void main() {
  test('starts loading, then lists every movement newest first', () async {
    final vm = _vm(instantRepository());
    expect(vm.state, isA<HistoryLoading>());

    await vm.load();

    expect(vm.state, isA<HistoryLoaded>());
    expect(_ids(vm), ['t4', 't1', 't3', 't6', 't5', 't2']);
    expect(vm.visibleEntries.first.itemName, 'Throttle position sensor');
    expect(vm.visibleEntries.first.unit, 'pcs');
  });

  test('shows an error when the repository fails', () async {
    final vm = _vm(instantRepository(failureRate: 1));

    await vm.load();

    expect(vm.state, isA<HistoryError>());
    expect(vm.visibleEntries, isEmpty);
  });

  test('is loaded but empty when nothing has moved yet', () async {
    final vm = _vm(
      FakeInventoryRepository(delay: Duration.zero, transactions: const []),
    );

    await vm.load();

    expect((vm.state as HistoryLoaded).entries, isEmpty);
  });

  test('the type filter shows only that type, null shows all again', () async {
    final vm = _vm(instantRepository());
    await vm.load();

    vm.setTypeFilter(TransactionType.take);
    expect(_ids(vm), ['t1', 't3', 't6']);

    vm.setTypeFilter(null);
    expect(_ids(vm), hasLength(6));
  });

  test('a take recorded on another screen appears at the top', () async {
    final repo = instantRepository();
    final vm = _vm(repo);
    await vm.load();

    await repo.recordTransaction(
      StockTransaction(
        id: 'new',
        itemId: 'm6-bolt',
        memberName: 'Tester',
        type: TransactionType.take,
        quantity: 4,
        timestamp: DateTime(2026, 11, 17, 12),
      ),
    );
    await _settle();

    expect(_ids(vm).first, 'new');
    expect(vm.visibleEntries.first.itemName, startsWith('M6×20 bolt'));
  });

  test('a failed refresh keeps the history already on screen', () async {
    final repo = _FlakyRepository();
    final vm = _vm(repo);
    await vm.load();

    repo.fail = true;
    await vm.refresh();

    expect(vm.state, isA<HistoryLoaded>());
    expect(_ids(vm), hasLength(6));
  });
}
