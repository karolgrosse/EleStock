/// Where an order for an item is.
enum OrderStatus {
  /// Someone ordered it; the parts are on their way.
  ordered,

  /// The parts arrived and were put on the shelf (a restock transaction).
  received,
}

/// One order of a low-stock item from a supplier.
class OrderEntry {
  const OrderEntry({
    required this.id,
    required this.itemId,
    required this.quantity,
    required this.memberName,
    required this.orderedAt,
    this.status = OrderStatus.ordered,
  });

  final String id;
  final String itemId;

  /// How many units were ordered, in the item's unit.
  final int quantity;

  /// Who placed the order.
  final String memberName;
  final DateTime orderedAt;
  final OrderStatus status;

  bool get isOpen => status == OrderStatus.ordered;

  OrderEntry copyWith({
    String? id,
    String? itemId,
    int? quantity,
    String? memberName,
    DateTime? orderedAt,
    OrderStatus? status,
  }) => OrderEntry(
    id: id ?? this.id,
    itemId: itemId ?? this.itemId,
    quantity: quantity ?? this.quantity,
    memberName: memberName ?? this.memberName,
    orderedAt: orderedAt ?? this.orderedAt,
    status: status ?? this.status,
  );

  @override
  bool operator ==(Object other) =>
      other is OrderEntry &&
      other.id == id &&
      other.itemId == itemId &&
      other.quantity == quantity &&
      other.memberName == memberName &&
      other.orderedAt == orderedAt &&
      other.status == status;

  @override
  int get hashCode =>
      Object.hash(id, itemId, quantity, memberName, orderedAt, status);

  @override
  String toString() => 'OrderEntry($id, $quantity of $itemId, $status)';
}
