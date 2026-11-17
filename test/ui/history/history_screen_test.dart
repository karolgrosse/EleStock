import 'package:elestock/data/repositories/fake_inventory_repository.dart';
import 'package:elestock/domain/models/stock_transaction.dart';
import 'package:elestock/ui/core/widgets/error_view.dart';
import 'package:elestock/ui/core/widgets/transaction_tile.dart';
import 'package:elestock/ui/history/history_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/repositories.dart';

/// Fails to load until [fail] is set to false, to test Retry.
class _FlakyRepository extends FakeInventoryRepository {
  _FlakyRepository() : super(delay: Duration.zero);

  bool fail = true;

  @override
  Future<List<StockTransaction>> fetchTransactions({String? itemId}) async {
    if (fail) throw Exception('offline');
    return super.fetchTransactions(itemId: itemId);
  }
}

Future<void> _pumpHistory(
  WidgetTester tester, {
  FakeInventoryRepository? repository,
}) async {
  tester.view.physicalSize = const Size(600, 2000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    withRepository(
      const MaterialApp(home: HistoryScreen()),
      repository: repository,
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('lists every movement, newest first', (tester) async {
    await _pumpHistory(tester);

    final tiles = tester
        .widgetList<TransactionTile>(find.byType(TransactionTile))
        .toList();
    expect(tiles, hasLength(6));
    expect(tiles.first.transaction.id, 't4');
    expect(tiles.first.title, 'Throttle position sensor');
  });

  testWidgets('shows the error with Retry, and Retry loads the history', (
    tester,
  ) async {
    final repo = _FlakyRepository();
    await _pumpHistory(tester, repository: repo);

    expect(find.byType(ErrorView), findsOneWidget);
    expect(find.byType(TransactionTile), findsNothing);

    repo.fail = false;
    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();

    expect(find.byType(ErrorView), findsNothing);
    expect(find.byType(TransactionTile), findsNWidgets(6));
  });

  testWidgets('shows the empty state when nothing has moved yet', (
    tester,
  ) async {
    await _pumpHistory(
      tester,
      repository: FakeInventoryRepository(
        delay: Duration.zero,
        transactions: const [],
      ),
    );

    expect(find.text('No stock movements yet'), findsOneWidget);
  });

  testWidgets('a filter chip leaves only that type', (tester) async {
    await _pumpHistory(tester);

    await tester.tap(find.widgetWithText(FilterChip, 'Restocked'));
    await tester.pumpAndSettle();

    final tiles = tester.widgetList<TransactionTile>(
      find.byType(TransactionTile),
    );
    expect(tiles.map((t) => t.transaction.id), ['t2']);
  });
}
