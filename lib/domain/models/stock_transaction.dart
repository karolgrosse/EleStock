/// What happened to the stock of an item.
enum TransactionType {
  /// A member took parts out of the box.
  take,

  /// A member put unused parts back.
  putBack,

  /// New stock arrived (an order was delivered).
  restock,

  /// Manual correction after a stock count.
  adjust,
}

/// One entry in the global inventory history.
class StockTransaction {
  const StockTransaction({
    required this.id,
    required this.itemId,
    required this.memberName,
    required this.type,
    required this.quantity,
    required this.timestamp,
    this.note,
  });

  final String id;
  final String itemId;
  final String memberName;
  final TransactionType type;

  /// How many units moved. Always positive, except for [TransactionType.adjust]
  /// where it is the signed correction.
  final int quantity;
  final DateTime timestamp;
  final String? note;

  /// Signed change to the item's stock.
  int get delta => switch (type) {
    TransactionType.take => -quantity,
    TransactionType.putBack || TransactionType.restock => quantity,
    TransactionType.adjust => quantity,
  };

  StockTransaction copyWith({
    String? id,
    String? itemId,
    String? memberName,
    TransactionType? type,
    int? quantity,
    DateTime? timestamp,
    String? note,
  }) => StockTransaction(
    id: id ?? this.id,
    itemId: itemId ?? this.itemId,
    memberName: memberName ?? this.memberName,
    type: type ?? this.type,
    quantity: quantity ?? this.quantity,
    timestamp: timestamp ?? this.timestamp,
    note: note ?? this.note,
  );

  @override
  bool operator ==(Object other) =>
      other is StockTransaction &&
      other.id == id &&
      other.itemId == itemId &&
      other.memberName == memberName &&
      other.type == type &&
      other.quantity == quantity &&
      other.timestamp == timestamp &&
      other.note == note;

  @override
  int get hashCode =>
      Object.hash(id, itemId, memberName, type, quantity, timestamp, note);

  @override
  String toString() => 'StockTransaction($id, $type $quantity of $itemId)';
}

/// Returns a copy of [transactions] with the newest entry first.
List<StockTransaction> newestFirst(Iterable<StockTransaction> transactions) =>
    [...transactions]..sort((a, b) => b.timestamp.compareTo(a.timestamp));
