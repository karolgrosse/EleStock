import 'package:flutter/material.dart';

import '../../../domain/models/item.dart';

/// Shows the current stock of an item, e.g. "6 pcs".
/// Red when the item is out of stock, highlighted when it is low.
class StockBadge extends StatelessWidget {
  const StockBadge({super.key, required this.item});

  final Item item;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    Color background = colors.secondaryContainer;
    Color foreground = colors.onSecondaryContainer;
    if (item.isOutOfStock) {
      background = colors.error;
      foreground = colors.onError;
    } else if (item.isLowStock) {
      background = colors.tertiaryContainer;
      foreground = colors.onTertiaryContainer;
    }

    final label = '${item.quantity} ${item.unit}';

    // Screen readers hear "6 pcs, low stock" instead of only the number,
    // because the colour alone carries no meaning for them.
    return Semantics(
      label: item.isLowStock ? '$label, low stock' : label,
      excludeSemantics: true,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          label,
          style: Theme.of(context).textTheme.labelLarge
              ?.copyWith(color: foreground),
        ),
      ),
    );
  }
}
