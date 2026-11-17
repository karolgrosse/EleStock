import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../domain/models/item.dart';
import '../core/category_ui.dart';
import '../core/widgets/empty_state.dart';
import '../core/widgets/error_view.dart';
import '../core/widgets/stock_badge.dart';
import '../history/history_screen.dart';
import '../item_details/item_details_screen.dart';
import '../item_form/item_form_screen.dart';
import '../scanner/scanner_screen.dart';
import '../shopping_list/shopping_list_screen.dart';
import 'inventory_view_model.dart';

/// The main page: every part and tool in the workshop.
///
/// On wide windows (a tablet mounted in the workshop) it is a master–detail
/// layout; on phones tapping an item pushes [ItemDetailsScreen]. All data and
/// the search, filter and selection come from [InventoryViewModel].
class InventoryScreen extends StatelessWidget {
  const InventoryScreen({super.key});

  static const wideBreakpoint = 840.0;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => InventoryViewModel.of(context)..load(),
      child: const _InventoryScaffold(),
    );
  }
}

class _InventoryScaffold extends StatelessWidget {
  const _InventoryScaffold();

  /// Opens the item form. A new or edited item reaches the list through
  /// `itemUpdates`; here it is only selected and confirmed.
  Future<void> _openForm(BuildContext context, {String? itemId}) async {
    final vm = context.read<InventoryViewModel>();
    final messenger = ScaffoldMessenger.of(context);
    final saved = await Navigator.of(context).push<Item>(
      MaterialPageRoute(builder: (_) => ItemFormScreen(itemId: itemId)),
    );
    if (saved == null) return;
    vm.select(saved.id);
    messenger.showSnackBar(
      SnackBar(
        content: Text(itemId == null ? 'Added ${saved.name}' : 'Saved changes'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<InventoryViewModel>();
    final selectedId = vm.selectedId;
    // On phones the details screen has its own Edit button; on wide windows
    // the details pane has none, so it lives here.
    final wide =
        MediaQuery.sizeOf(context).width >= InventoryScreen.wideBreakpoint;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Inventory'),
        actions: [
          if (wide && selectedId != null)
            IconButton(
              tooltip: 'Edit item',
              icon: const Icon(Icons.edit_outlined),
              onPressed: () => _openForm(context, itemId: selectedId),
            ),
          IconButton(
            tooltip: 'Scan QR label',
            icon: const Icon(Icons.qr_code_scanner),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(builder: (_) => const ScannerScreen()),
            ),
          ),
          IconButton(
            tooltip: 'History',
            icon: const Icon(Icons.history),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(builder: (_) => const HistoryScreen()),
            ),
          ),
          IconButton(
            tooltip: 'Shopping list',
            icon: const Icon(Icons.shopping_cart_outlined),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => const ShoppingListScreen(),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        tooltip: 'Add item',
        onPressed: () => _openForm(context),
        child: const Icon(Icons.add),
      ),
      body: switch (vm.state) {
        InventoryLoading() => const Center(child: CircularProgressIndicator()),
        InventoryError(:final message) => ErrorView(
          message: message,
          onRetry: vm.load,
        ),
        InventoryLoaded(:final items) when items.isEmpty => const EmptyState(
          icon: Icons.inventory_2_outlined,
          message: 'No items yet. Add the first one with +',
        ),
        InventoryLoaded() => const _InventoryLayout(),
      },
    );
  }
}

/// The list alone on phones, the list next to the details on wide windows.
class _InventoryLayout extends StatelessWidget {
  const _InventoryLayout();

  @override
  Widget build(BuildContext context) {
    final selectedId = context.select<InventoryViewModel, String?>(
      (vm) => vm.selectedId,
    );
    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= InventoryScreen.wideBreakpoint;
        final list = _ItemList(wide: wide);
        if (!wide) return list;

        return Row(
          children: [
            SizedBox(width: 380, child: list),
            const VerticalDivider(width: 1),
            Expanded(
              child: selectedId == null
                  ? const EmptyState(
                      icon: Icons.touch_app_outlined,
                      message: 'Select an item to see its details',
                    )
                  : ItemDetailsView(
                      key: ValueKey(selectedId),
                      itemId: selectedId,
                    ),
            ),
          ],
        );
      },
    );
  }
}

class _ItemList extends StatelessWidget {
  const _ItemList({required this.wide});

  final bool wide;

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<InventoryViewModel>();
    final items = vm.visibleItems;
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          child: SearchBar(
            hintText: 'Search parts and tools',
            leading: const Icon(Icons.search),
            onChanged: vm.search,
          ),
        ),
        SizedBox(
          height: 56,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            children: [
              for (final category in ItemCategory.values)
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(category.label),
                    selected: vm.category == category,
                    onSelected: (on) => vm.filterBy(on ? category : null),
                  ),
                ),
            ],
          ),
        ),
        Expanded(
          child: items.isEmpty
              ? const EmptyState(
                  icon: Icons.search_off,
                  message: 'No items match your search',
                )
              : ListView.builder(
                  itemCount: items.length,
                  itemBuilder: (context, i) =>
                      _ItemTile(item: items[i], wide: wide),
                ),
        ),
      ],
    );
  }
}

class _ItemTile extends StatelessWidget {
  const _ItemTile({required this.item, required this.wide});

  final Item item;
  final bool wide;

  @override
  Widget build(BuildContext context) {
    final vm = context.read<InventoryViewModel>();
    return ListTile(
      selected: wide && item.id == vm.selectedId,
      leading: Icon(item.category.icon),
      title: Text(item.name, maxLines: 2, overflow: TextOverflow.ellipsis),
      subtitle: Text(
        item.location,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: StockBadge(item: item),
      onTap: () {
        if (wide) {
          vm.select(item.id);
        } else {
          Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => ItemDetailsScreen(itemId: item.id),
            ),
          );
        }
      },
    );
  }
}
