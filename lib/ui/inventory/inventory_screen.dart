import 'package:flutter/material.dart';

import '../../data/fake_inventory.dart';
import '../../domain/models/item.dart';
import '../core/category_ui.dart';
import '../core/widgets/coming_soon.dart';
import '../core/widgets/empty_state.dart';
import '../core/widgets/stock_badge.dart';
import 'item_details_screen.dart';

/// The main page: every part and tool in the workshop.
///
/// On wide windows (a tablet mounted in the workshop) it is a master–detail
/// layout; on phones tapping an item pushes [ItemDetailsScreen].
///
/// It is a StatefulWidget only because of the search text, the category
/// filter and the selected item. In lab 2 that state moves to a view model.
class InventoryScreen extends StatefulWidget {
  const InventoryScreen({super.key});

  static const wideBreakpoint = 840.0;

  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> {
  String _query = '';
  ItemCategory? _category;
  String? _selectedId;

  List<Item> get _visibleItems => fakeItems.where((item) {
    final matchesQuery = item.name.toLowerCase().contains(_query.toLowerCase());
    final matchesCategory = _category == null || item.category == _category;
    return matchesQuery && matchesCategory;
  }).toList();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Inventory'),
        actions: [
          IconButton(
            tooltip: 'Scan QR label',
            icon: const Icon(Icons.qr_code_scanner),
            onPressed: () => showComingSoon(context, 'QR scanner'),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        tooltip: 'Add item',
        onPressed: () => showComingSoon(context, 'Add item'),
        child: const Icon(Icons.add),
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final wide = constraints.maxWidth >= InventoryScreen.wideBreakpoint;
          final list = _buildList(context, wide: wide);
          if (!wide) return list;

          final selected = _selectedId == null
              ? null
              : fakeItemById(_selectedId!);
          return Row(
            children: [
              SizedBox(width: 380, child: list),
              const VerticalDivider(width: 1),
              Expanded(
                child: selected == null
                    ? const EmptyState(
                        icon: Icons.touch_app_outlined,
                        message: 'Select an item to see its details',
                      )
                    : ItemDetailsView(
                        key: ValueKey(selected.id),
                        item: selected,
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildList(BuildContext context, {required bool wide}) {
    final items = _visibleItems;
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          child: SearchBar(
            hintText: 'Search parts and tools',
            leading: const Icon(Icons.search),
            onChanged: (value) => setState(() => _query = value),
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
                    selected: _category == category,
                    onSelected: (on) =>
                        setState(() => _category = on ? category : null),
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
                  itemBuilder: (context, i) {
                    final item = items[i];
                    return ListTile(
                      selected: wide && item.id == _selectedId,
                      leading: Icon(item.category.icon),
                      title: Text(
                        item.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      subtitle: Text(
                        item.location,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      trailing: StockBadge(item: item),
                      onTap: () {
                        if (wide) {
                          setState(() => _selectedId = item.id);
                        } else {
                          Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) => ItemDetailsScreen(item: item),
                            ),
                          );
                        }
                      },
                    );
                  },
                ),
        ),
      ],
    );
  }
}
