import 'package:flutter/material.dart';

import '../../../domain/models/stock_transaction.dart';

/// One entry of the inventory history: what moved, by whom and when.
class TransactionTile extends StatelessWidget {
  const TransactionTile({
    super.key,
    required this.transaction,
    required this.title,
    required this.unit,
    this.showMember = true,
  });

  final StockTransaction transaction;

  /// Main line: the item name in the global history, the member name on the
  /// item details screen.
  final String title;
  final String unit;

  /// Whether to repeat the member's name in the subtitle.
  final bool showMember;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final t = transaction;
    final delta = t.delta;
    final sign = delta > 0 ? '+' : (delta < 0 ? '−' : '');
    final deltaText = '$sign${delta.abs()} $unit';
    final subtitle = [
      if (showMember) t.memberName,
      '${_typeLabel(t.type)} · ${_dateTime(t.timestamp)}',
      if (t.note != null) t.note!,
    ].join('\n');

    return ListTile(
      leading: Icon(_typeIcon(t.type)),
      title: Text(title, maxLines: 2, overflow: TextOverflow.ellipsis),
      subtitle: Text(subtitle, maxLines: 3, overflow: TextOverflow.ellipsis),
      isThreeLine: showMember || t.note != null,
      trailing: Text(
        deltaText,
        style: theme.textTheme.titleMedium?.copyWith(
          color: delta < 0
              ? theme.colorScheme.error
              : theme.colorScheme.primary,
        ),
      ),
    );
  }

  static String _typeLabel(TransactionType type) => switch (type) {
    TransactionType.take => 'Took',
    TransactionType.putBack => 'Put back',
    TransactionType.restock => 'Restocked',
    TransactionType.adjust => 'Stock count',
  };

  static IconData _typeIcon(TransactionType type) => switch (type) {
    TransactionType.take => Icons.remove_circle_outline,
    TransactionType.putBack => Icons.undo,
    TransactionType.restock => Icons.local_shipping_outlined,
    TransactionType.adjust => Icons.fact_check_outlined,
  };

  static String _dateTime(DateTime d) {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(d.day)}.${two(d.month)} ${two(d.hour)}:${two(d.minute)}';
  }
}
