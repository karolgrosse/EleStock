import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';

import '../../data/repositories/item_repository.dart';
import '../../domain/models/item.dart';

/// What the item form can show. Exactly one at a time.
sealed class ItemFormState {
  const ItemFormState();
}

/// Editing: the item is being loaded.
final class ItemFormLoading extends ItemFormState {
  const ItemFormLoading();
}

/// The form can be filled in. [initial] is the item being edited, or `null`
/// when a new item is created.
final class ItemFormReady extends ItemFormState {
  const ItemFormReady(this.initial);

  final Item? initial;
}

/// Editing: no item has this id (it was deleted in the meantime).
final class ItemFormNotFound extends ItemFormState {
  const ItemFormNotFound(this.itemId);

  final String itemId;
}

final class ItemFormError extends ItemFormState {
  const ItemFormError(this.message);

  final String message;
}

/// The validated values of the form, already trimmed and parsed.
typedef ItemDraft = ({
  String name,
  ItemCategory category,
  String location,
  int quantity,
  String unit,
  int lowStockThreshold,
  String? partNumber,
  String? notes,
});

/// Creates a new item, or edits the item with [itemId].
class ItemFormViewModel extends ChangeNotifier {
  ItemFormViewModel({this.itemId, required this._items})
    : _state = itemId == null
          ? const ItemFormReady(null)
          : const ItemFormLoading();

  /// Creates the view model from the repository provided in `main.dart`.
  /// Screens use this so that they never import anything from `data/`.
  factory ItemFormViewModel.of(BuildContext context, {String? itemId}) =>
      ItemFormViewModel(itemId: itemId, items: context.read<ItemRepository>());

  /// The item being edited, or `null` when creating a new one.
  final String? itemId;

  final ItemRepository _items;

  bool get isEditing => itemId != null;

  ItemFormState _state;
  ItemFormState get state => _state;

  bool _saving = false;

  /// True while saving. The Save button is disabled, so a double tap doesn't
  /// create the item twice.
  bool get isSaving => _saving;

  bool _disposed = false;

  /// Loads the item being edited. Does nothing when creating a new item.
  Future<void> load() async {
    final id = itemId;
    if (id == null) return;
    _setState(const ItemFormLoading());
    try {
      final item = await _items.fetchItem(id);
      _setState(item == null ? ItemFormNotFound(id) : ItemFormReady(item));
    } catch (_) {
      _setState(const ItemFormError('Could not load this item.'));
    }
  }

  /// Saves [draft] and returns the saved item, or `null` if saving failed.
  /// The form stays filled in after a failure, so the user can try again.
  Future<Item?> save(ItemDraft draft) async {
    final current = _state;
    if (current is! ItemFormReady || _saving) return null;

    // A new Item instead of copyWith: copyWith cannot clear the optional
    // fields, e.g. when the user deletes the notes.
    final item = Item(
      id: current.initial?.id ?? '',
      name: draft.name,
      category: draft.category,
      location: draft.location,
      // Editing never changes the stock; the repository keeps the stored one.
      quantity: current.initial?.quantity ?? draft.quantity,
      unit: draft.unit,
      lowStockThreshold: draft.lowStockThreshold,
      partNumber: draft.partNumber,
      notes: draft.notes,
    );

    _saving = true;
    _notify();
    try {
      return isEditing
          ? await _items.updateItem(item)
          : await _items.createItem(item);
    } catch (_) {
      return null;
    } finally {
      _saving = false;
      _notify();
    }
  }

  void _setState(ItemFormState state) {
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
    super.dispose();
  }
}
