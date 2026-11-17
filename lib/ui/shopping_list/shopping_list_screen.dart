import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/category_ui.dart';
import '../core/widgets/empty_state.dart';
import '../core/widgets/error_view.dart';
import '../core/widgets/stock_badge.dart';
import '../item_details/item_details_screen.dart';
import 'shopping_list_view_model.dart';

/// Every item at or below its reorder level: what still has to be ordered,
/// and what is already on its way.
class ShoppingListScreen extends StatelessWidget {
  const ShoppingListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => ShoppingListViewModel.of(context)..load(),
      child: Scaffold(
        appBar: AppBar(title: const Text('Shopping list')),
        body: const ShoppingListBody(),
      ),
    );
  }
}

/// Switches over the view model state. Needs a [ShoppingListViewModel] above
/// it in the tree.
class ShoppingListBody extends StatelessWidget {
  const ShoppingListBody({super.key});

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<ShoppingListViewModel>();
    return switch (vm.state) {
      ShoppingListLoading() => const Center(child: CircularProgressIndicator()),
      ShoppingListError(:final message) => ErrorView(
        message: message,
        onRetry: vm.load,
      ),
      ShoppingListLoaded(:final entries) when entries.isEmpty =>
        const EmptyState(
          icon: Icons.shopping_cart_checkout,
          message: 'Nothing to buy. Every item is above its reorder level.',
        ),
      ShoppingListLoaded(:final toOrder, :final ordered) => RefreshIndicator(
        onRefresh: vm.load,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            if (toOrder.isNotEmpty) ...[
              _SectionHeader('To order (${toOrder.length})'),
              for (final entry in toOrder) _ShoppingTile(entry: entry),
            ],
            if (ordered.isNotEmpty) ...[
              _SectionHeader('Ordered (${ordered.length})'),
              for (final entry in ordered) _ShoppingTile(entry: entry),
            ],
          ],
        ),
      ),
    };
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader(this.title);

  final String title;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Text(
        title,
        style: theme.textTheme.titleSmall?.copyWith(
          color: theme.colorScheme.primary,
        ),
      ),
    );
  }
}

class _ShoppingTile extends StatelessWidget {
  const _ShoppingTile({required this.entry});

  final ShoppingEntry entry;

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<ShoppingListViewModel>();
    final item = entry.item;
    final order = entry.openOrder;
    final busy = vm.isBusy(item.id);

    final details = order == null
        ? 'Reorder at ${item.lowStockThreshold} ${item.unit} · ${item.location}'
        : 'Ordered ${order.quantity} ${item.unit} · '
              '${order.memberName}, ${_date(order.orderedAt)}';

    return ListTile(
      leading: Icon(item.category.icon),
      title: Text(item.name, maxLines: 2, overflow: TextOverflow.ellipsis),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(details, maxLines: 2, overflow: TextOverflow.ellipsis),
          const SizedBox(height: 6),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              StockBadge(item: item),
              if (order == null)
                FilledButton.tonalIcon(
                  onPressed: busy ? null : () => _order(context),
                  icon: const Icon(Icons.add_shopping_cart, size: 18),
                  label: Text('Order ${entry.suggestedQuantity} ${item.unit}'),
                )
              else
                OutlinedButton.icon(
                  onPressed: busy ? null : () => _receive(context),
                  icon: const Icon(Icons.inventory_outlined, size: 18),
                  label: const Text('Received'),
                ),
            ],
          ),
        ],
      ),
      isThreeLine: true,
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => ItemDetailsScreen(itemId: item.id),
        ),
      ),
    );
  }

  Future<void> _order(BuildContext context) async {
    // Read before the await: the tile may be gone when the answer arrives.
    final messenger = ScaffoldMessenger.of(context);
    final vm = context.read<ShoppingListViewModel>();
    final result = await vm.markOrdered(entry.item.id);
    messenger.showSnackBar(
      SnackBar(
        content: Text(switch (result) {
          ShoppingActionResult.saved =>
            'Ordered ${entry.suggestedQuantity} ${entry.item.unit}',
          ShoppingActionResult.failed => 'Could not save the order. Try again.',
        }),
      ),
    );
  }

  Future<void> _receive(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    final vm = context.read<ShoppingListViewModel>();
    final result = await vm.markReceived(entry.item.id);
    messenger.showSnackBar(
      SnackBar(
        content: Text(switch (result) {
          ShoppingActionResult.saved => 'Put on the shelf',
          ShoppingActionResult.failed =>
            'Could not save the delivery. Try again.',
        }),
      ),
    );
  }

  static String _date(DateTime d) {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(d.day)}.${two(d.month)}';
  }
}
