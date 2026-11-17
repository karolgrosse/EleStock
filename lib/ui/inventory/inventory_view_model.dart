import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';

import '../../data/repositories/item_repository.dart';
import '../../domain/models/item.dart';

/// What the inventory list can show. Exactly one at a time.
sealed class InventoryState {
  const InventoryState();
}

final class InventoryLoading extends InventoryState {
  const InventoryLoading();
}

final class InventoryLoaded extends InventoryState {
  const InventoryLoaded(this.items);

  /// Every item in the workshop, unfiltered.
  final List<Item> items;
}

final class InventoryError extends InventoryState {
  const InventoryError(this.message);

  final String message;
}

/// Loads every item, and holds the search text, the category filter and the
/// item selected in the master–detail layout.
class InventoryViewModel extends ChangeNotifier {
  InventoryViewModel({required this._items}) {
    // Stock changed somewhere else (e.g. "Take 4" in the details pane):
    // update that row without reloading the whole list.
    _subscription = _items.itemUpdates.listen(_onItemUpdated);
  }

  /// Creates the view model from the repository provided in `main.dart`.
  /// Screens use this so that they never import anything from `data/`.
  factory InventoryViewModel.of(BuildContext context) =>
      InventoryViewModel(items: context.read<ItemRepository>());

  final ItemRepository _items;
  late final StreamSubscription<Item> _subscription;

  InventoryState _state = const InventoryLoading();
  InventoryState get state => _state;

  String _query = '';
  String get query => _query;

  ItemCategory? _category;

  /// The selected category chip, or `null` for all categories.
  ItemCategory? get category => _category;

  String? _selectedId;

  /// The item shown in the details pane on wide windows.
  String? get selectedId => _selectedId;

  bool _disposed = false;

  /// The loaded items that match the search text and the category filter.
  /// Empty while loading or after an error.
  List<Item> get visibleItems {
    final current = _state;
    if (current is! InventoryLoaded) return const [];
    final query = _query.trim().toLowerCase();
    return current.items.where((item) {
      final matchesQuery = item.name.toLowerCase().contains(query);
      final matchesCategory = _category == null || item.category == _category;
      return matchesQuery && matchesCategory;
    }).toList();
  }

  Future<void> load() async {
    _setState(const InventoryLoading());
    try {
      _setState(InventoryLoaded(await _items.fetchItems()));
    } catch (_) {
      _setState(const InventoryError('Could not load the inventory.'));
    }
  }

  void search(String query) {
    if (query == _query) return;
    _query = query;
    _notify();
  }

  /// Shows only [category], or every category when it is `null`.
  void filterBy(ItemCategory? category) {
    if (category == _category) return;
    _category = category;
    _notify();
  }

  void select(String itemId) {
    if (itemId == _selectedId) return;
    _selectedId = itemId;
    _notify();
  }

  void _onItemUpdated(Item item) {
    final current = _state;
    if (current is! InventoryLoaded) return;
    // A new list, not an in-place change, so the old state stays intact.
    final items = [...current.items];
    final index = items.indexWhere((i) => i.id == item.id);
    if (index == -1) {
      items.add(item);
    } else {
      items[index] = item;
    }
    _setState(InventoryLoaded(items));
  }

  void _setState(InventoryState state) {
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
