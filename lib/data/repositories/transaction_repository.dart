import '../../domain/models/item.dart';
import '../../domain/models/stock_transaction.dart';

/// Thrown when a transaction would make the stock negative, e.g. taking 5
/// when only 3 are left.
class InsufficientStockException implements Exception {
  const InsufficientStockException(this.available);

  final int available;

  @override
  String toString() => 'InsufficientStockException(available: $available)';
}

/// The shared history of stock movements.
abstract interface class TransactionRepository {
  /// All transactions, or only those of [itemId]. Not sorted: callers use
  /// `newestFirst()`.
  Future<List<StockTransaction>> fetchTransactions({String? itemId});

  /// Records [transaction] and applies its delta to the item's stock.
  /// Returns the item with the new quantity.
  ///
  /// Throws [InsufficientStockException] if the stock would drop below zero.
  Future<Item> recordTransaction(StockTransaction transaction);
}
