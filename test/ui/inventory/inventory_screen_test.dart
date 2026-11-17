import 'package:elestock/data/repositories/fake_inventory_repository.dart';
import 'package:elestock/domain/models/item.dart';
import 'package:elestock/main.dart';
import 'package:elestock/ui/item_details/item_details_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/repositories.dart';

void setScreenSize(WidgetTester tester, Size size) {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}

/// Fails to load the list until [fail] is set to false, to test Retry.
class _FlakyRepository extends FakeInventoryRepository {
  _FlakyRepository() : super(delay: Duration.zero);

  bool fail = true;

  @override
  Future<List<Item>> fetchItems() async {
    if (fail) throw Exception('offline');
    return super.fetchItems();
  }
}

/// The stock badge in the list row of the item called [name].
Finder _badgeInRow(String name, String badge) => find.descendant(
  of: find.widgetWithText(ListTile, name),
  matching: find.text(badge),
);

void main() {
  testWidgets('phone: tapping an item opens its details screen', (
    tester,
  ) async {
    setScreenSize(tester, const Size(390, 844));
    await tester.pumpWidget(withRepository(const EleStockApp()));
    await tester.pumpAndSettle(); // the list loads asynchronously

    await tester.tap(find.text('M6×20 bolt, 12.9, black oxide'));
    await tester.pumpAndSettle();

    expect(find.byType(ItemDetailsScreen), findsOneWidget);
    expect(find.text('Shelf C / Drawer 4'), findsOneWidget);
  });

  testWidgets('wide window: details appear next to the list', (tester) async {
    setScreenSize(tester, const Size(1280, 800));
    await tester.pumpWidget(withRepository(const EleStockApp()));
    await tester.pumpAndSettle(); // the list loads asynchronously

    expect(find.text('Select an item to see its details'), findsOneWidget);

    await tester.tap(find.text('M6×20 bolt, 12.9, black oxide'));
    await tester.pumpAndSettle();

    // No new screen was pushed: the details are shown in the right pane.
    expect(find.byType(ItemDetailsScreen), findsNothing);
    expect(find.byType(ItemDetailsView), findsOneWidget);
  });

  testWidgets('very narrow window still lays out without errors', (
    tester,
  ) async {
    setScreenSize(tester, const Size(390, 600));
    await tester.pumpWidget(withRepository(const EleStockApp()));
    await tester.pumpAndSettle(); // the list loads asynchronously

    // Shrink the window step by step, like dragging its edge.
    for (final width in [150.0, 60.0, 1.0]) {
      tester.view.physicalSize = Size(width, 600);
      await tester.pump();
      expect(tester.takeException(), isNull, reason: 'list at $width px');
    }

    tester.view.physicalSize = const Size(390, 600);
    await tester.pump();
    await tester.tap(find.text('M6×20 bolt, 12.9, black oxide'));
    await tester.pumpAndSettle();

    tester.view.physicalSize = const Size(60, 600);
    await tester.pump();
    expect(tester.takeException(), isNull, reason: 'details at 60 px');
    expect(find.byType(ItemDetailsScreen), findsOneWidget);
  });

  testWidgets('search with no match shows the empty state', (tester) async {
    setScreenSize(tester, const Size(390, 844));
    await tester.pumpWidget(withRepository(const EleStockApp()));
    await tester.pumpAndSettle(); // the list loads asynchronously

    await tester.enterText(find.byType(SearchBar), 'flux capacitor');
    await tester.pump();

    expect(find.text('No items match your search'), findsOneWidget);
  });

  testWidgets('shows the error state, and Retry loads the list', (
    tester,
  ) async {
    setScreenSize(tester, const Size(390, 844));
    final repo = _FlakyRepository();
    await tester.pumpWidget(
      withRepository(const EleStockApp(), repository: repo),
    );
    await tester.pumpAndSettle();

    expect(find.text('Could not load the inventory.'), findsOneWidget);
    expect(find.byType(ListTile), findsNothing);

    repo.fail = false;
    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();

    expect(find.text('M6×20 bolt, 12.9, black oxide'), findsOneWidget);
  });

  testWidgets('an empty workshop shows the empty state', (tester) async {
    setScreenSize(tester, const Size(390, 844));
    await tester.pumpWidget(
      withRepository(
        const EleStockApp(),
        repository: FakeInventoryRepository(items: [], delay: Duration.zero),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('No items yet. Add the first one with +'), findsOneWidget);
  });

  testWidgets('wide window: Take in the details pane updates the list', (
    tester,
  ) async {
    const name = 'Deutsch DT crimp contacts, size 16, nickel';
    setScreenSize(tester, const Size(1280, 1600));
    await tester.pumpWidget(withRepository(const EleStockApp()));
    await tester.pumpAndSettle();
    await tester.tap(find.text(name));
    await tester.pumpAndSettle();
    expect(_badgeInRow(name, '6 pcs'), findsOneWidget);

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

    // Shared state: the list row follows the change made in the other pane.
    expect(_badgeInRow(name, '2 pcs'), findsOneWidget);
  });
}
