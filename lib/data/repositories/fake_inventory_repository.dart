import 'dart:async';
import 'dart:math';

import '../../domain/models/item.dart';
import '../../domain/models/order_entry.dart';
import '../../domain/models/stock_transaction.dart';
import '../fake_inventory.dart';
import 'item_repository.dart';
import 'order_repository.dart';
import 'transaction_repository.dart';

/// In-memory items, transactions and orders with a network-like [delay] and
/// random failures, so that loading and error states can be seen and tested.
///
/// One class implements all three interfaces because taking stock or
/// receiving an order changes both the history and the item. `main.dart`
/// provides the same instance as [ItemRepository], [TransactionRepository]
/// and [OrderRepository].
class FakeInventoryRepository
    implements ItemRepository, TransactionRepository, OrderRepository {
  FakeInventoryRepository({
    List<Item>? items,
    List<StockTransaction>? transactions,
    List<OrderEntry>? orders,
    this.delay = const Duration(milliseconds: 800),
    this.failureRate = 0.0,
    Random? random,
    DateTime Function()? clock,
  }) : assert(failureRate >= 0 && failureRate <= 1),
       _items = {for (final item in items ?? fakeItems) item.id: item},
       _transactions = [...(transactions ?? fakeTransactions)],
       _orders = [...(orders ?? fakeOrders)],
       _random = random ?? Random(),
       _clock = clock ?? DateTime.now;

  /// How long every call takes.
  final Duration delay;

  /// 0.0 never fails, 1.0 always fails.
  final double failureRate;

  final Map<String, Item> _items;
  final List<StockTransaction> _transactions;
  final List<OrderEntry> _orders;
  final Random _random;
  final DateTime Function() _clock;
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
    return _apply(transaction);
  }

  /// Applies [transaction] to its item's stock, records it and tells every
  /// listener of [itemUpdates].
  Item _apply(StockTransaction transaction) {
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

  @override
  Future<List<OrderEntry>> fetchOrders() async {
    await _simulateNetwork();
    return List.unmodifiable(_orders);
  }

  @override
  Future<OrderEntry> placeOrder({
    required String itemId,
    required int quantity,
    required String memberName,
  }) async {
    await _simulateNetwork();
    if (!_items.containsKey(itemId)) {
      throw StateError('No item with id $itemId');
    }
    final order = OrderEntry(
      id: 'o${_orders.length + 1}',
      itemId: itemId,
      quantity: quantity,
      memberName: memberName,
      orderedAt: _clock(),
    );
    _orders.add(order);
    return order;
  }

  @override
  Future<Item> receiveOrder(
    String orderId, {
    required String memberName,
  }) async {
    await _simulateNetwork();
    final index = _orders.indexWhere((o) => o.id == orderId);
    if (index == -1) throw StateError('No order with id $orderId');
    final order = _orders[index];
    if (!order.isOpen) throw StateError('Order $orderId was already received');

    final updated = _apply(
      StockTransaction(
        id: 'restock-$orderId',
        itemId: order.itemId,
        memberName: memberName,
        type: TransactionType.restock,
        quantity: order.quantity,
        timestamp: _clock(),
        note: 'Order delivered',
      ),
    );
    _orders[index] = order.copyWith(status: OrderStatus.received);
    return updated;
  }

  void dispose() => _updates.close();
}
