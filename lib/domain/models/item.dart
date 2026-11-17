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

  /// Returns a copy with the given fields replaced. Items are immutable, so
  /// this is how stock changes: `item.copyWith(quantity: item.quantity - 4)`.
  Item copyWith({
    String? id,
    String? name,
    ItemCategory? category,
    String? location,
    int? quantity,
    String? unit,
    int? lowStockThreshold,
    String? partNumber,
    String? notes,
  }) => Item(
    id: id ?? this.id,
    name: name ?? this.name,
    category: category ?? this.category,
    location: location ?? this.location,
    quantity: quantity ?? this.quantity,
    unit: unit ?? this.unit,
    lowStockThreshold: lowStockThreshold ?? this.lowStockThreshold,
    partNumber: partNumber ?? this.partNumber,
    notes: notes ?? this.notes,
  );

  @override
  bool operator ==(Object other) =>
      other is Item &&
      other.id == id &&
      other.name == name &&
      other.category == category &&
      other.location == location &&
      other.quantity == quantity &&
      other.unit == unit &&
      other.lowStockThreshold == lowStockThreshold &&
      other.partNumber == partNumber &&
      other.notes == notes;

  @override
  int get hashCode => Object.hash(
    id,
    name,
    category,
    location,
    quantity,
    unit,
    lowStockThreshold,
    partNumber,
    notes,
  );

  @override
  String toString() => 'Item($id, $quantity $unit)';
}
