import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../domain/models/stock_transaction.dart';
import '../core/widgets/empty_state.dart';
import '../core/widgets/error_view.dart';
import '../core/widgets/transaction_tile.dart';
import '../item_details/item_details_screen.dart';
import 'history_view_model.dart';

/// Every stock movement in the workshop (take, put back, restock, stock
/// count), newest first. Answers "who took the last crimp contacts?".
class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => HistoryViewModel.of(context)..load(),
      child: Scaffold(
        appBar: AppBar(title: const Text('History')),
        body: const HistoryBody(),
      ),
    );
  }
}

/// Switches over the view model state. Needs a [HistoryViewModel] above it
/// in the tree.
class HistoryBody extends StatelessWidget {
  const HistoryBody({super.key});

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<HistoryViewModel>();
    return switch (vm.state) {
      HistoryLoading() => const Center(child: CircularProgressIndicator()),
      HistoryError(:final message) => ErrorView(
        message: message,
        onRetry: vm.load,
      ),
      HistoryLoaded(:final entries) when entries.isEmpty => const EmptyState(
        icon: Icons.history,
        message: 'No stock movements yet',
      ),
      HistoryLoaded() => Column(
        children: [
          _TypeFilterBar(selected: vm.typeFilter),
          Expanded(child: _HistoryList(entries: vm.visibleEntries)),
        ],
      ),
    };
  }
}

class _TypeFilterBar extends StatelessWidget {
  const _TypeFilterBar({required this.selected});

  final TransactionType? selected;

  @override
  Widget build(BuildContext context) {
    final vm = context.read<HistoryViewModel>();
    return SizedBox(
      height: 56,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        children: [
          for (final type in TransactionType.values)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: FilterChip(
                label: Text(type.filterLabel),
                selected: selected == type,
                onSelected: (on) => vm.setTypeFilter(on ? type : null),
              ),
            ),
        ],
      ),
    );
  }
}

class _HistoryList extends StatelessWidget {
  const _HistoryList({required this.entries});

  final List<HistoryEntry> entries;

  @override
  Widget build(BuildContext context) {
    final vm = context.read<HistoryViewModel>();
    if (entries.isEmpty) {
      return const EmptyState(
        icon: Icons.filter_alt_off_outlined,
        message: 'No movements of this type',
      );
    }
    return RefreshIndicator(
      onRefresh: vm.refresh,
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: entries.length,
        itemBuilder: (context, i) {
          final entry = entries[i];
          return InkWell(
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) =>
                    ItemDetailsScreen(itemId: entry.transaction.itemId),
              ),
            ),
            child: TransactionTile(
              transaction: entry.transaction,
              title: entry.itemName,
              unit: entry.unit,
            ),
          );
        },
      ),
    );
  }
}

extension on TransactionType {
  String get filterLabel => switch (this) {
    TransactionType.take => 'Taken',
    TransactionType.putBack => 'Put back',
    TransactionType.restock => 'Restocked',
    TransactionType.adjust => 'Stock counts',
  };
}
