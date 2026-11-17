import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';

import '../../data/repositories/item_repository.dart';
import '../../data/repositories/order_repository.dart';
import '../../domain/models/item.dart';
import '../../domain/models/order_entry.dart';

/// One row of the shopping list: a low-stock item and its open order, if
/// someone already ordered it.
class ShoppingEntry {
  const ShoppingEntry({required this.item, this.openOrder});

  final Item item;
  final OrderEntry? openOrder;

  bool get isOrdered => openOrder != null;

  /// How many to order: enough to get back to twice the reorder level, and
  /// at least one.
  int get suggestedQuantity {
    final missing = item.lowStockThreshold * 2 - item.quantity;
    return missing < 1 ? 1 : missing;
  }
}

/// What the shopping list screen can show. Exactly one at a time.
sealed class ShoppingListState {
  const ShoppingListState();
}

final class ShoppingListLoading extends ShoppingListState {
  const ShoppingListLoading();
}

final class ShoppingListLoaded extends ShoppingListState {
  const ShoppingListLoaded(this.entries);

  /// Every item at or below its reorder level, most urgent first.
  final List<ShoppingEntry> entries;

  /// Items nobody has ordered yet.
  List<ShoppingEntry> get toOrder =>
      entries.where((e) => !e.isOrdered).toList(growable: false);

  /// Items that are on their way.
  List<ShoppingEntry> get ordered =>
      entries.where((e) => e.isOrdered).toList(growable: false);
}

final class ShoppingListError extends ShoppingListState {
  const ShoppingListError(this.message);

  final String message;
}

/// Result of [ShoppingListViewModel.markOrdered] and
/// [ShoppingListViewModel.markReceived].
enum ShoppingActionResult { saved, failed }

/// Items at or below their reorder level, and the orders for them.
///
/// Shares [ItemRepository] with the inventory and item details: it listens to
/// [ItemRepository.itemUpdates], so an item that drops below its threshold
/// after a take appears here at once, and a received order makes it leave.
class ShoppingListViewModel extends ChangeNotifier {
  ShoppingListViewModel({
    required this._items,
    required this._orders,
    this.memberName = 'You',
  }) {
    _subscription = _items.itemUpdates.listen(_onItemUpdated);
  }

  /// Creates the view model from the repositories provided in `main.dart`,
  /// so that the screen never imports anything from `data/`.
  factory ShoppingListViewModel.of(BuildContext context) =>
      ShoppingListViewModel(
        items: context.read<ItemRepository>(),
        orders: context.read<OrderRepository>(),
      );

  /// Who orders and receives. Replaced by the logged-in member when Supabase
  /// Auth arrives in lab 3.
  final String memberName;

  final ItemRepository _items;
  final OrderRepository _orders;
  late final StreamSubscription<Item> _subscription;

  /// Every item by id and every order, as last loaded. The list on screen is
  /// computed from these, so an update to one item only replaces that item.
  Map<String, Item> _allItems = const {};
  List<OrderEntry> _allOrders = const [];

  ShoppingListState _state = const ShoppingListLoading();
  ShoppingListState get state => _state;

  final Set<String> _busy = {};

  /// True while an order for [itemId] is being saved or received. The
  /// buttons are disabled, so a double tap doesn't order twice.
  bool isBusy(String itemId) => _busy.contains(itemId);

  bool _disposed = false;

  Future<void> load() async {
    _setState(const ShoppingListLoading());
    try {
      final (items, orders) = await (
        _items.fetchItems(),
        _orders.fetchOrders(),
      ).wait;
      _allItems = {for (final item in items) item.id: item};
      _allOrders = orders;
      _rebuild();
    } catch (_) {
      _setState(const ShoppingListError('Could not load the shopping list.'));
    }
  }

  /// Orders [itemId] with its suggested quantity.
  ///
  /// Optimistic: the item moves to "Ordered" at once and moves back if
  /// saving fails.
  Future<ShoppingActionResult> markOrdered(String itemId) async {
    final entry = _entry(itemId);
    if (entry == null || entry.isOrdered || _busy.contains(itemId)) {
      return ShoppingActionResult.failed;
    }

    final before = _allOrders;
    final draft = OrderEntry(
      id: 'local-$itemId',
      itemId: itemId,
      quantity: entry.suggestedQuantity,
      memberName: memberName,
      orderedAt: DateTime.now(),
    );
    _busy.add(itemId);
    _allOrders = [...before, draft];
    _rebuild();

    try {
      final saved = await _orders.placeOrder(
        itemId: itemId,
        quantity: draft.quantity,
        memberName: memberName,
      );
      _allOrders = [for (final o in _allOrders) o.id == draft.id ? saved : o];
      return ShoppingActionResult.saved;
    } catch (_) {
      _allOrders = [
        for (final o in _allOrders)
          if (o.id != draft.id) o,
      ];
      return ShoppingActionResult.failed;
    } finally {
      _busy.remove(itemId);
      _rebuild();
    }
  }

  /// The parts of [itemId]'s open order arrived: they go on the shelf as a
  /// restock, and the item leaves the list once it is above its reorder
  /// level.
  Future<ShoppingActionResult> markReceived(String itemId) async {
    final order = _entry(itemId)?.openOrder;
    if (order == null || _busy.contains(itemId)) {
      return ShoppingActionResult.failed;
    }

    _busy.add(itemId);
    _rebuild();
    try {
      // The repository also emits the restocked item on itemUpdates, which
      // updates the stock here, in the inventory and in the history.
      final item = await _orders.receiveOrder(order.id, memberName: memberName);
      _allItems = {..._allItems, item.id: item};
      _allOrders = [
        for (final o in _allOrders)
          o.id == order.id ? o.copyWith(status: OrderStatus.received) : o,
      ];
      return ShoppingActionResult.saved;
    } catch (_) {
      return ShoppingActionResult.failed;
    } finally {
      _busy.remove(itemId);
      _rebuild();
    }
  }

  ShoppingEntry? _entry(String itemId) {
    final current = _state;
    if (current is! ShoppingListLoaded) return null;
    for (final e in current.entries) {
      if (e.item.id == itemId) return e;
    }
    return null;
  }

  void _onItemUpdated(Item item) {
    if (_state is! ShoppingListLoaded) return;
    _allItems = {..._allItems, item.id: item};
    _rebuild();
  }

  /// Recomputes the list from [_allItems] and [_allOrders].
  void _rebuild() {
    final openOrders = {
      for (final o in _allOrders)
        if (o.isOpen) o.itemId: o,
    };
    final entries = [
      for (final item in _allItems.values)
        if (item.isLowStock)
          ShoppingEntry(item: item, openOrder: openOrders[item.id]),
    ]..sort(_mostUrgentFirst);
    _setState(ShoppingListLoaded(List.unmodifiable(entries)));
  }

  /// Out of stock first, then the furthest below the reorder level, then by
  /// name.
  static int _mostUrgentFirst(ShoppingEntry a, ShoppingEntry b) {
    final out = (b.item.isOutOfStock ? 1 : 0) - (a.item.isOutOfStock ? 1 : 0);
    if (out != 0) return out;
    final gap = (a.item.quantity - a.item.lowStockThreshold).compareTo(
      b.item.quantity - b.item.lowStockThreshold,
    );
    if (gap != 0) return gap;
    return a.item.name.compareTo(b.item.name);
  }

  void _setState(ShoppingListState state) {
    _state = state;
    _notify();
  }

  void _notify() {
    // An async call may finish after the screen was closed.
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _subscription.cancel();
    super.dispose();
  }
}
