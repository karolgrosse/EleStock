import 'package:elestock/data/repositories/fake_inventory_repository.dart';
import 'package:elestock/domain/models/item.dart';
import 'package:elestock/main.dart';
import 'package:elestock/ui/item_form/item_form_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/repositories.dart';

/// Loads fine, but every save fails (e.g. the connection dropped).
class _SaveFailsRepository extends FakeInventoryRepository {
  _SaveFailsRepository() : super(delay: Duration.zero);

  @override
  Future<Item> createItem(Item item) async => throw Exception('offline');
}

void _setScreenSize(WidgetTester tester, Size size) {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}

Future<void> _pumpForm(
  WidgetTester tester, {
  String? itemId,
  FakeInventoryRepository? repository,
}) async {
  _setScreenSize(tester, const Size(600, 1400));
  await tester.pumpWidget(
    withRepository(
      MaterialApp(home: ItemFormScreen(itemId: itemId)),
      repository: repository,
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _fillNewItem(WidgetTester tester) async {
  await tester.enterText(
    find.byKey(const Key('name-field')),
    'M3 brass standoff',
  );
  await tester.enterText(
    find.byKey(const Key('location-field')),
    'Shelf C / Drawer 6',
  );
  await tester.enterText(find.byKey(const Key('quantity-field')), '50');
  await tester.enterText(find.byKey(const Key('threshold-field')), '10');
}

void main() {
  testWidgets('an empty form shows the validation errors', (tester) async {
    await _pumpForm(tester);

    await tester.enterText(find.byKey(const Key('quantity-field')), '-3');
    await tester.tap(find.text('Add item'));
    await tester.pump();

    expect(find.text('Enter a name'), findsOneWidget);
    expect(find.text('Enter the location'), findsOneWidget);
    expect(find.text('Cannot be negative'), findsOneWidget);
  });

  testWidgets('a failed save keeps the form and shows a message', (
    tester,
  ) async {
    await _pumpForm(tester, repository: _SaveFailsRepository());

    await _fillNewItem(tester);
    await tester.tap(find.text('Add item'));
    await tester.pumpAndSettle();

    expect(find.text('Could not save the item. Try again.'), findsOneWidget);
    expect(find.byType(ItemFormScreen), findsOneWidget);
    expect(find.text('M3 brass standoff'), findsOneWidget);
  });

  testWidgets('editing shows the stock as text, not as a field', (
    tester,
  ) async {
    await _pumpForm(tester, itemId: 'dt-crimp-16');

    expect(find.byKey(const Key('quantity-field')), findsNothing);
    expect(find.textContaining('Stock: 6 pcs'), findsOneWidget);
    expect(
      find.widgetWithText(
        TextFormField,
        'Deutsch DT crimp contacts, size 16, '
        'nickel',
      ),
      findsOneWidget,
    );
  });

  testWidgets('a new item from the inventory appears in the list', (
    tester,
  ) async {
    _setScreenSize(tester, const Size(390, 1400));
    await tester.pumpWidget(withRepository(const EleStockApp()));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Add item'));
    await tester.pumpAndSettle();
    await _fillNewItem(tester);
    await tester.tap(find.text('Add item'));
    await tester.pumpAndSettle();

    expect(find.byType(ItemFormScreen), findsNothing);
    expect(find.text('Added M3 brass standoff'), findsOneWidget);
    await tester.enterText(find.byType(SearchBar), 'standoff');
    await tester.pumpAndSettle();
    expect(find.widgetWithText(ListTile, 'M3 brass standoff'), findsOneWidget);
  });

  testWidgets('editing from the details screen updates the details', (
    tester,
  ) async {
    _setScreenSize(tester, const Size(390, 1400));
    await tester.pumpWidget(withRepository(const EleStockApp()));
    await tester.pumpAndSettle();
    await tester.tap(find.text('M6×20 bolt, 12.9, black oxide'));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Edit item'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('location-field')),
      'Shelf D / Drawer 1',
    );
    await tester.tap(find.text('Save changes'));
    await tester.pumpAndSettle();

    // Back on the details screen, which picked the change up.
    expect(find.byType(ItemFormScreen), findsNothing);
    expect(find.text('Shelf D / Drawer 1'), findsOneWidget);
  });
}
