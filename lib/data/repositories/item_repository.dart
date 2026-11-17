import '../../domain/models/item.dart';

/// Where items come from. The app depends on this contract only; the fake
/// implementation is picked in `main.dart`, and in lab 3 a drift/Supabase
/// implementation replaces it.
abstract interface class ItemRepository {
  /// Every item in the workshop.
  Future<List<Item>> fetchItems();

  /// One item, or `null` when no item has this [id] (e.g. a QR code from
  /// another team's box).
  Future<Item?> fetchItem(String id);

  /// Emits an item every time it changes (for example after someone takes
  /// stock), so that every screen showing it can update: the inventory list,
  /// the details pane and later the shopping list.
  Stream<Item> get itemUpdates;
}
