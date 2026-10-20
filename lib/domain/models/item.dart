/// Categories used to group items on the shelves.
enum ItemCategory {
  connectors,
  electronics,
  fasteners,
  sensors,
  tools,
  consumables,
}

/// A single kind of part or tool kept in the workshop.
class Item {
  const Item({
    required this.id,
    required this.name,
    required this.category,
    required this.location,
    required this.quantity,
    required this.unit,
    required this.lowStockThreshold,
    this.partNumber,
    this.notes,
  });

  final String id;
  final String name;
  final ItemCategory category;

  /// Shelf and box, e.g. "Shelf B / Box 3".
  final String location;
  final int quantity;

  /// Unit shown next to the quantity, e.g. "pcs" or "m".
  final String unit;

  /// When [quantity] is at or below this value, the item goes on the
  /// shopping list.
  final int lowStockThreshold;
  final String? partNumber;
  final String? notes;

  bool get isLowStock => quantity <= lowStockThreshold;
  bool get isOutOfStock => quantity <= 0;
}
