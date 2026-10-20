import 'package:elestock/data/fake_inventory.dart';
import 'package:elestock/ui/core/widgets/transaction_tile.dart';
import 'package:elestock/ui/inventory/item_details_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> _pumpDetails(WidgetTester tester, String itemId) =>
    tester.pumpWidget(
      MaterialApp(home: ItemDetailsScreen(item: fakeItemById(itemId)!)),
    );

void main() {
  testWidgets('history is listed newest first', (tester) async {
    // Tall enough that the history at the bottom is built without scrolling.
    tester.view.physicalSize = const Size(600, 2000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await _pumpDetails(tester, 'dt-crimp-16');

    final tiles = tester.widgetList<TransactionTile>(
      find.byType(TransactionTile),
    );
    expect(tiles.map((t) => t.transaction.id), ['t1', 't6']);
  });

  testWidgets('Take is disabled when the item is out of stock', (tester) async {
    await _pumpDetails(tester, 'm5-nyloc');

    final take = find.widgetWithText(FilledButton, 'Take');
    expect(tester.widget<FilledButton>(take).onPressed, isNull);
  });
}
