import 'package:elestock/data/repositories/fake_inventory_repository.dart';
import 'package:elestock/domain/models/item.dart';
import 'package:elestock/ui/core/widgets/error_view.dart';
import 'package:elestock/ui/core/widgets/transaction_tile.dart';
import 'package:elestock/ui/item_details/item_details_screen.dart';
import 'package:elestock/ui/item_details/quantity_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/repositories.dart';

/// Fails to load until [fail] is set to false, to test Retry.
class _FlakyRepository extends FakeInventoryRepository {
  _FlakyRepository() : super(delay: Duration.zero);

  bool fail = true;

  @override
  Future<Item?> fetchItem(String id) async {
    if (fail) throw Exception('offline');
    return super.fetchItem(id);
  }
}

Future<void> _pumpDetails(
  WidgetTester tester,
  String itemId, {
  FakeInventoryRepository? repository,
}) async {
  // Tall enough that the history at the bottom is built without scrolling.
  tester.view.physicalSize = const Size(600, 2000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    withRepository(
      MaterialApp(home: ItemDetailsScreen(itemId: itemId)),
      repository: repository,
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('history is listed newest first', (tester) async {
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

  testWidgets('shows the error state, and Retry loads the item', (
    tester,
  ) async {
    final repo = _FlakyRepository();
    await _pumpDetails(tester, 'dt-crimp-16', repository: repo);

    expect(find.byType(ErrorView), findsOneWidget);
    expect(find.text('Could not load this item.'), findsOneWidget);

    repo.fail = false;
    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();

    expect(find.byType(ErrorView), findsNothing);
    expect(find.text('Shelf A / Box 1'), findsOneWidget);
  });

  testWidgets('Take 4 lowers the stock shown on the screen', (tester) async {
    await _pumpDetails(tester, 'dt-crimp-16');
    expect(find.text('6 pcs'), findsOneWidget);

    await tester.tap(find.widgetWithText(FilledButton, 'Take'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('quantity-field')), '4');
    await tester.tap(
      find.descendant(
        of: find.byType(AlertDialog),
        matching: find.text('Take'),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('2 pcs'), findsOneWidget);
    expect(find.text('Took 4 pcs'), findsOneWidget);
  });

  testWidgets('the dialog refuses more than is in stock', (tester) async {
    await _pumpDetails(tester, 'dt-crimp-16');

    await tester.tap(find.widgetWithText(FilledButton, 'Take'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('quantity-field')), '10');
    await tester.tap(
      find.descendant(
        of: find.byType(AlertDialog),
        matching: find.text('Take'),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Only 6 left'), findsOneWidget);
    expect(find.byType(AlertDialog), findsOneWidget);
  });

  group('validateQuantity', () {
    test('accepts a number within the stock', () {
      expect(validateQuantity('4', max: 6), isNull);
    });

    test('rejects text, zero and too many', () {
      expect(validateQuantity('abc'), isNotNull);
      expect(validateQuantity('0'), isNotNull);
      expect(validateQuantity('7', max: 6), 'Only 6 left');
    });
  });
}
