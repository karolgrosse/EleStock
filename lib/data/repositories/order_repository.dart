import '../../domain/models/item.dart';
import '../../domain/models/order_entry.dart';

/// Orders of low-stock items: what was ordered and whether it has arrived.
abstract interface class OrderRepository {
  /// Every order, open and received. Not sorted.
  Future<List<OrderEntry>> fetchOrders();

  /// Records that [memberName] ordered [quantity] units of [itemId].
  /// Returns the saved order.
  ///
  /// Throws [StateError] if no item has this id.
  Future<OrderEntry> placeOrder({
    required String itemId,
    required int quantity,
    required String memberName,
  });

  /// Marks the order [orderId] as received and puts its quantity on the
  /// shelf as a restock transaction, recorded under [memberName]. The
  /// restock appears in the history and on `ItemRepository.itemUpdates`.
  /// Returns the item with the new quantity.
  ///
  /// Throws [StateError] if the order does not exist or was already
  /// received.
  Future<Item> receiveOrder(String orderId, {required String memberName});
}
