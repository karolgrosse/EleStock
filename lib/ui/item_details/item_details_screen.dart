import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../domain/models/item.dart';
import '../../domain/models/stock_transaction.dart';
import '../core/category_ui.dart';
import '../core/widgets/coming_soon.dart';
import '../core/widgets/empty_state.dart';
import '../core/widgets/error_view.dart';
import '../core/widgets/stock_badge.dart';
import '../core/widgets/transaction_tile.dart';
import 'item_details_view_model.dart';
import 'quantity_dialog.dart';

/// Full-screen item details, opened from the inventory on phones and from
/// the scanner. It receives only the item id, as a QR code or a deep link
/// (`/items/:id`, lab 3) would.
class ItemDetailsScreen extends StatelessWidget {
  const ItemDetailsScreen({super.key, required this.itemId});

  final String itemId;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => ItemDetailsViewModel.of(context, itemId)..load(),
      child: const _ItemDetailsScaffold(),
    );
  }
}

class _ItemDetailsScaffold extends StatelessWidget {
  const _ItemDetailsScaffold();

  @override
  Widget build(BuildContext context) {
    final state = context.watch<ItemDetailsViewModel>().state;
    return Scaffold(
      appBar: AppBar(
        title: Text(
          state is ItemDetailsLoaded ? state.item.name : 'Item',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
          if (state is ItemDetailsLoaded)
            IconButton(
              tooltip: 'Edit item',
              icon: const Icon(Icons.edit_outlined),
              onPressed: () => showComingSoon(context, 'Edit item'),
            ),
        ],
      ),
      body: const ItemDetailsBody(),
    );
  }
}

/// The details content without a Scaffold, so the inventory screen can show
/// it in the right-hand pane on wide windows. Creates its own view model.
class ItemDetailsView extends StatelessWidget {
  const ItemDetailsView({super.key, required this.itemId});

  final String itemId;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => ItemDetailsViewModel.of(context, itemId)..load(),
      child: const ItemDetailsBody(),
    );
  }
}

/// Switches over the view model state. Needs an [ItemDetailsViewModel] above
/// it in the tree.
class ItemDetailsBody extends StatelessWidget {
  const ItemDetailsBody({super.key});

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<ItemDetailsViewModel>();
    return switch (vm.state) {
      ItemDetailsLoading() => const Center(child: CircularProgressIndicator()),
      ItemDetailsError(:final message) => ErrorView(
        message: message,
        onRetry: vm.load,
      ),
      ItemDetailsNotFound(:final itemId) => EmptyState(
        icon: Icons.help_outline,
        message: 'No item with the id "$itemId".',
      ),
      ItemDetailsLoaded(:final item, :final history) => RefreshIndicator(
        onRefresh: vm.load,
        child: _ItemDetailsContent(
          item: item,
          history: history,
          saving: vm.isSaving,
        ),
      ),
    };
  }
}

class _ItemDetailsContent extends StatelessWidget {
  const _ItemDetailsContent({
    required this.item,
    required this.history,
    required this.saving,
  });

  final Item item;
  final List<StockTransaction> history;
  final bool saving;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;

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
              onPressed: item.isOutOfStock || saving
                  ? null
                  : () => _changeStock(context, item, take: true),
              icon: const Icon(Icons.remove_circle_outline),
              label: const Text('Take'),
            ),
            OutlinedButton.icon(
              onPressed: saving
                  ? null
                  : () => _changeStock(context, item, take: false),
              icon: const Icon(Icons.add_circle_outline),
              label: const Text('Put back'),
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

  Future<void> _changeStock(
    BuildContext context,
    Item item, {
    required bool take,
  }) async {
    // Read everything that needs the context before the first await.
    final vm = context.read<ItemDetailsViewModel>();
    final messenger = ScaffoldMessenger.of(context);

    final input = await showQuantityDialog(
      context,
      title: take ? 'Take from ${item.location}' : 'Put back',
      confirmLabel: take ? 'Take' : 'Put back',
      unit: item.unit,
      max: take ? item.quantity : null,
    );
    if (input == null) return;

    final result = take
        ? await vm.take(input.quantity, note: input.note)
        : await vm.putBack(input.quantity, note: input.note);

    final amount = '${input.quantity} ${item.unit}';
    messenger.showSnackBar(
      SnackBar(
        content: Text(switch (result) {
          StockChangeResult.saved => take ? 'Took $amount' : 'Put back $amount',
          StockChangeResult.notEnoughStock =>
            'Not enough in stock. The number was updated.',
          StockChangeResult.failed => 'Could not save. Stock is unchanged.',
        }),
      ),
    );
  }
}
