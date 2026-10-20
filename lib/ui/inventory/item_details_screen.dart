import 'package:flutter/material.dart';

import '../../data/fake_inventory.dart';
import '../../domain/models/item.dart';
import '../../domain/models/stock_transaction.dart';
import '../core/category_ui.dart';
import '../core/widgets/coming_soon.dart';
import '../core/widgets/empty_state.dart';
import '../core/widgets/stock_badge.dart';
import '../core/widgets/transaction_tile.dart';

/// Full-screen item details, opened from the inventory on phones.
class ItemDetailsScreen extends StatelessWidget {
  const ItemDetailsScreen({super.key, required this.item});

  final Item item;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(item.name, maxLines: 1, overflow: TextOverflow.ellipsis),
        actions: [
          IconButton(
            tooltip: 'Edit item',
            icon: const Icon(Icons.edit_outlined),
            onPressed: () => showComingSoon(context, 'Edit item'),
          ),
        ],
      ),
      body: ItemDetailsView(item: item),
    );
  }
}

/// The details content without a Scaffold, so the inventory screen can show
/// it in the right-hand pane on wide windows.
class ItemDetailsView extends StatelessWidget {
  const ItemDetailsView({super.key, required this.item});

  final Item item;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final history = newestFirst(
      fakeTransactions.where((t) => t.itemId == item.id),
    );

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // 1. What is it and how many are left.
        Text(item.name, style: text.headlineSmall),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            StockBadge(item: item),
            Chip(
              avatar: Icon(item.category.icon, size: 18),
              label: Text(item.category.label),
            ),
          ],
        ),
        const SizedBox(height: 8),

        // 2. Where it is and when to reorder.
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.place_outlined),
          title: Text(item.location),
          subtitle: const Text('Location'),
        ),
        if (item.partNumber != null)
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.tag),
            title: Text(item.partNumber!),
            subtitle: const Text('Part number'),
          ),
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.low_priority),
          title: Text('${item.lowStockThreshold} ${item.unit}'),
          subtitle: const Text('Reorder at or below'),
        ),
        if (item.notes != null)
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.notes),
            title: Text(item.notes!),
          ),
        const SizedBox(height: 8),

        // 3. The main action of the app.
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            FilledButton.icon(
              onPressed: item.isOutOfStock
                  ? null
                  : () => showComingSoon(context, 'Take'),
              icon: const Icon(Icons.remove_circle_outline),
              label: const Text('Take'),
            ),
            OutlinedButton.icon(
              onPressed: () => showComingSoon(context, 'Put back / restock'),
              icon: const Icon(Icons.add_circle_outline),
              label: const Text('Put back / restock'),
            ),
          ],
        ),
        const SizedBox(height: 24),

        // 4. Who took what from this box, newest first.
        Text('History', style: text.titleMedium),
        if (history.isEmpty)
          const EmptyState(
            icon: Icons.history,
            message: 'No stock movements yet',
          ),
        for (final t in history)
          TransactionTile(
            transaction: t,
            title: t.memberName,
            unit: item.unit,
            showMember: false,
          ),
      ],
    );
  }
}
