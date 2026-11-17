import 'dart:async';
import 'dart:math';

import '../../domain/models/item.dart';
import '../../domain/models/stock_transaction.dart';
import '../fake_inventory.dart';
import 'item_repository.dart';
import 'transaction_repository.dart';

/// In-memory items and transactions with a network-like [delay] and random
/// failures, so that loading and error states can be seen and tested.
///
/// One class implements both interfaces because taking stock changes both
/// the history and the item. `main.dart` provides the same instance as
/// [ItemRepository] and as [TransactionRepository].
class FakeInventoryRepository implements ItemRepository, TransactionRepository {
  FakeInventoryRepository({
    List<Item>? items,
    List<StockTransaction>? transactions,
    this.delay = const Duration(milliseconds: 800),
    this.failureRate = 0.0,
    Random? random,
  }) : assert(failureRate >= 0 && failureRate <= 1),
       _items = {for (final item in items ?? fakeItems) item.id: item},
       _transactions = [...(transactions ?? fakeTransactions)],
       _random = random ?? Random();

  /// How long every call takes.
  final Duration delay;

  /// 0.0 never fails, 1.0 always fails.
  final double failureRate;

  final Map<String, Item> _items;
  final List<StockTransaction> _transactions;
  final Random _random;
  final _updates = StreamController<Item>.broadcast();

  Future<void> _simulateNetwork() async {
    await Future<void>.delayed(delay);
    if (failureRate > 0 && _random.nextDouble() < failureRate) {
      throw Exception('Simulated network failure');
    }
  }

  @override
  Future<List<Item>> fetchItems() async {
    await _simulateNetwork();
    return List.unmodifiable(_items.values);
  }

  @override
  Future<Item?> fetchItem(String id) async {
    await _simulateNetwork();
    return _items[id];
  }

  @override
  Stream<Item> get itemUpdates => _updates.stream;

  @override
  Future<List<StockTransaction>> fetchTransactions({String? itemId}) async {
    await _simulateNetwork();
    return List.unmodifiable(
      itemId == null
          ? _transactions
          : _transactions.where((t) => t.itemId == itemId),
    );
  }

  @override
  Future<Item> recordTransaction(StockTransaction transaction) async {
    await _simulateNetwork();
    final item = _items[transaction.itemId];
    if (item == null) {
      throw StateError('No item with id ${transaction.itemId}');
    }
    final newQuantity = item.quantity + transaction.delta;
    if (newQuantity < 0) throw InsufficientStockException(item.quantity);

    final updated = item.copyWith(quantity: newQuantity);
    _items[item.id] = updated;
    _transactions.add(transaction);
    _updates.add(updated);
    return updated;
  }

  void dispose() => _updates.close();
}
