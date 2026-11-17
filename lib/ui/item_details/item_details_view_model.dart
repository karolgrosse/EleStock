import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';

import '../../data/repositories/item_repository.dart';
import '../../data/repositories/transaction_repository.dart';
import '../../domain/models/item.dart';
import '../../domain/models/stock_transaction.dart';

/// What the item details screen can show. Exactly one at a time.
sealed class ItemDetailsState {
  const ItemDetailsState();
}

final class ItemDetailsLoading extends ItemDetailsState {
  const ItemDetailsLoading();
}

final class ItemDetailsLoaded extends ItemDetailsState {
  const ItemDetailsLoaded(this.item, this.history);

  final Item item;

  /// This item's transactions, newest first.
  final List<StockTransaction> history;
}

/// The id is valid syntax but no item has it (e.g. a scanned foreign label).
final class ItemDetailsNotFound extends ItemDetailsState {
  const ItemDetailsNotFound(this.itemId);

  final String itemId;
}

final class ItemDetailsError extends ItemDetailsState {
  const ItemDetailsError(this.message);

  final String message;
}

/// Result of [ItemDetailsViewModel.take] and [ItemDetailsViewModel.putBack].
enum StockChangeResult { saved, notEnoughStock, failed }

/// Loads one item with its history and changes its stock.
///
/// The screen receives only the item id (a QR code knows nothing else) and
/// asks this view model for everything.
class ItemDetailsViewModel extends ChangeNotifier {
  ItemDetailsViewModel({
    required this.itemId,
    required this._items,
    required this._transactions,
    this.memberName = 'You',
    DateTime Function()? clock,
  }) : _clock = clock ?? DateTime.now {
    // Someone else (another screen, later another device) changed the item:
    // show the new stock without reloading everything.
    _subscription = _items.itemUpdates
        .where((item) => item.id == itemId)
        .listen(_onItemUpdated);
  }

  /// Creates the view model from the repositories provided in `main.dart`.
  /// Screens use this so that they never import anything from `data/`.
  factory ItemDetailsViewModel.of(BuildContext context, String itemId) =>
      ItemDetailsViewModel(
        itemId: itemId,
        items: context.read<ItemRepository>(),
        transactions: context.read<TransactionRepository>(),
      );

  final String itemId;

  /// Who the transactions are recorded under. Replaced by the logged-in
  /// member when Supabase Auth arrives in lab 3.
  final String memberName;

  final ItemRepository _items;
  final TransactionRepository _transactions;
  final DateTime Function() _clock;
  late final StreamSubscription<Item> _subscription;

  ItemDetailsState _state = const ItemDetailsLoading();
  ItemDetailsState get state => _state;

  bool _saving = false;

  /// True while a take / put back is being saved. The buttons are disabled,
  /// so a double tap doesn't take twice.
  bool get isSaving => _saving;

  bool _disposed = false;

  Future<void> load() async {
    _setState(const ItemDetailsLoading());
    try {
      final (item, history) = await (
        _items.fetchItem(itemId),
        _transactions.fetchTransactions(itemId: itemId),
      ).wait;
      _setState(
        item == null
            ? ItemDetailsNotFound(itemId)
            : ItemDetailsLoaded(item, newestFirst(history)),
      );
    } catch (_) {
      _setState(const ItemDetailsError('Could not load this item.'));
    }
  }

  /// Takes [quantity] units out of the box.
  Future<StockChangeResult> take(int quantity, {String? note}) =>
      _change(TransactionType.take, quantity, note);

  /// Puts [quantity] unused units back into the box.
  Future<StockChangeResult> putBack(int quantity, {String? note}) =>
      _change(TransactionType.putBack, quantity, note);

  /// Optimistic update: the new stock and the history row appear at once,
  /// and are rolled back if saving fails.
  Future<StockChangeResult> _change(
    TransactionType type,
    int quantity,
    String? note,
  ) async {
    final before = _state;
    if (before is! ItemDetailsLoaded || _saving) {
      return StockChangeResult.failed;
    }
    if (quantity <= 0) {
      throw ArgumentError.value(quantity, 'quantity', 'must be positive');
    }

    final transaction = StockTransaction(
      id: 'local-${_clock().microsecondsSinceEpoch}',
      itemId: itemId,
      memberName: memberName,
      type: type,
      quantity: quantity,
      timestamp: _clock(),
      note: (note == null || note.trim().isEmpty) ? null : note.trim(),
    );
    final newQuantity = before.item.quantity + transaction.delta;
    if (newQuantity < 0) return StockChangeResult.notEnoughStock;

    _saving = true;
    _setState(
      ItemDetailsLoaded(before.item.copyWith(quantity: newQuantity), [
        transaction,
        ...before.history,
      ]),
    );

    try {
      final saved = await _transactions.recordTransaction(transaction);
      final current = _state;
      if (current is ItemDetailsLoaded) {
        _setState(ItemDetailsLoaded(saved, current.history));
      }
      return StockChangeResult.saved;
    } on InsufficientStockException catch (e) {
      // Someone else took the last pieces in the meantime.
      _setState(
        ItemDetailsLoaded(
          before.item.copyWith(quantity: e.available),
          before.history,
        ),
      );
      return StockChangeResult.notEnoughStock;
    } catch (_) {
      _setState(before);
      return StockChangeResult.failed;
    } finally {
      _saving = false;
      _notify();
    }
  }

  void _onItemUpdated(Item item) {
    final current = _state;
    if (current is ItemDetailsLoaded && current.item != item) {
      _setState(ItemDetailsLoaded(item, current.history));
    }
  }

  void _setState(ItemDetailsState state) {
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
