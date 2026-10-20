import 'package:flutter_test/flutter_test.dart';
import 'package:elestock/domain/models/item.dart';
import 'package:elestock/domain/models/stock_transaction.dart';

Item _item({required int quantity, int threshold = 5}) => Item(
  id: 'x',
  name: 'Test',
  category: ItemCategory.fasteners,
  location: 'Shelf A',
  quantity: quantity,
  unit: 'pcs',
  lowStockThreshold: threshold,
);

void main() {
  group('Item stock', () {
    test('is low at the threshold', () {
      expect(_item(quantity: 5).isLowStock, isTrue);
    });

    test('is not low above the threshold', () {
      expect(_item(quantity: 6).isLowStock, isFalse);
    });

    test('is out of stock at zero', () {
      expect(_item(quantity: 0).isOutOfStock, isTrue);
    });
  });

  group('StockTransaction', () {
    StockTransaction tx(TransactionType type, int quantity, DateTime at) =>
        StockTransaction(
          id: '$type-$at',
          itemId: 'x',
          memberName: 'A',
          type: type,
          quantity: quantity,
          timestamp: at,
        );
    final at = DateTime(2026, 10, 20);

    test('taking lowers the stock', () {
      expect(tx(TransactionType.take, 4, at).delta, -4);
    });

    test('putting back and restocking raise the stock', () {
      expect(tx(TransactionType.putBack, 2, at).delta, 2);
      expect(tx(TransactionType.restock, 100, at).delta, 100);
    });

    test('an adjustment keeps its sign', () {
      expect(tx(TransactionType.adjust, -3, at).delta, -3);
    });

    test('newestFirst sorts by timestamp descending', () {
      final old = tx(TransactionType.take, 1, DateTime(2026, 10, 1));
      final mid = tx(TransactionType.take, 1, DateTime(2026, 10, 10));
      final recent = tx(TransactionType.take, 1, DateTime(2026, 10, 19));

      final sorted = newestFirst([mid, old, recent]);

      expect(sorted, [recent, mid, old]);
    });
  });
}
