import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';

import '../../data/repositories/item_repository.dart';
import '../../data/repositories/transaction_repository.dart';
import '../../domain/models/item.dart';
import '../../domain/models/stock_transaction.dart';

/// One row of the global history: the transaction plus what the screen needs
/// to show about its item.
class HistoryEntry {
  const HistoryEntry({
    required this.transaction,
    required this.itemName,
    required this.unit,
  });

  final StockTransaction transaction;

  /// The item's name, or its id if the item no longer exists.
  final String itemName;
  final String unit;
}

/// What the history screen can show. Exactly one at a time.
sealed class HistoryState {
  const HistoryState();
}

final class HistoryLoading extends HistoryState {
  const HistoryLoading();
}

final class HistoryLoaded extends HistoryState {
  const HistoryLoaded(this.entries);

  /// Every stock movement, newest first, before the type filter.
  final List<HistoryEntry> entries;
}

final class HistoryError extends HistoryState {
  const HistoryError(this.message);

  final String message;
}

/// Every stock movement in the workshop, newest first, with a filter by
/// transaction type.
///
/// Listens to [ItemRepository.itemUpdates]: when someone takes or puts back
/// stock on another screen, the new transaction shows up here without a
/// manual refresh.
class HistoryViewModel extends ChangeNotifier {
  HistoryViewModel({required this._items, required this._transactions}) {
    _subscription = _items.itemUpdates.listen((_) => refresh());
  }

  /// Creates the view model from the repositories provided in `main.dart`,
  /// so that the screen never imports anything from `data/`.
  factory HistoryViewModel.of(BuildContext context) => HistoryViewModel(
    items: context.read<ItemRepository>(),
    transactions: context.read<TransactionRepository>(),
  );

  final ItemRepository _items;
  final TransactionRepository _transactions;
  late final StreamSubscription<Item> _subscription;

  HistoryState _state = const HistoryLoading();
  HistoryState get state => _state;

  TransactionType? _typeFilter;

  /// Only transactions of this type are shown; `null` shows all of them.
  TransactionType? get typeFilter => _typeFilter;

  bool _disposed = false;

  /// The entries to show: the loaded history after the type filter. Empty
  /// while loading or after an error.
  List<HistoryEntry> get visibleEntries {
    final current = _state;
    if (current is! HistoryLoaded) return const [];
    final filter = _typeFilter;
    if (filter == null) return current.entries;
    return current.entries
        .where((e) => e.transaction.type == filter)
        .toList(growable: false);
  }

  /// Loads the history, showing the spinner first.
  Future<void> load() async {
    _setState(const HistoryLoading());
    try {
      _setState(HistoryLoaded(await _fetch()));
    } catch (_) {
      _setState(const HistoryError('Could not load the history.'));
    }
  }

  /// Reloads without the spinner (pull to refresh, or a change made on
  /// another screen). If it fails, the list already on screen stays.
  Future<void> refresh() async {
    if (_state is! HistoryLoaded) return load();
    try {
      _setState(HistoryLoaded(await _fetch()));
    } catch (_) {
      // Keep showing the previous history.
    }
  }

  /// Shows only [type], or everything when [type] is `null`.
  void setTypeFilter(TransactionType? type) {
    if (type == _typeFilter) return;
    _typeFilter = type;
    _notify();
  }

  Future<List<HistoryEntry>> _fetch() async {
    final (items, transactions) = await (
      _items.fetchItems(),
      _transactions.fetchTransactions(),
    ).wait;
    final byId = {for (final item in items) item.id: item};
    return [
      for (final t in newestFirst(transactions))
        HistoryEntry(
          transaction: t,
          itemName: byId[t.itemId]?.name ?? t.itemId,
          unit: byId[t.itemId]?.unit ?? '',
        ),
    ];
  }

  void _setState(HistoryState state) {
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
