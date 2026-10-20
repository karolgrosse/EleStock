import 'package:elestock/main.dart';
import 'package:elestock/ui/inventory/item_details_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void setScreenSize(WidgetTester tester, Size size) {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}

void main() {
  testWidgets('phone: tapping an item opens its details screen', (
    tester,
  ) async {
    setScreenSize(tester, const Size(390, 844));
    await tester.pumpWidget(const EleStockApp());

    await tester.tap(find.text('M6×20 bolt, 12.9, black oxide'));
    await tester.pumpAndSettle();

    expect(find.byType(ItemDetailsScreen), findsOneWidget);
    expect(find.text('Shelf C / Drawer 4'), findsOneWidget);
  });

  testWidgets('wide window: details appear next to the list', (tester) async {
    setScreenSize(tester, const Size(1280, 800));
    await tester.pumpWidget(const EleStockApp());

    expect(find.text('Select an item to see its details'), findsOneWidget);

    await tester.tap(find.text('M6×20 bolt, 12.9, black oxide'));
    await tester.pumpAndSettle();

    // No new screen was pushed: the details are shown in the right pane.
    expect(find.byType(ItemDetailsScreen), findsNothing);
    expect(find.byType(ItemDetailsView), findsOneWidget);
  });

  testWidgets('search with no match shows the empty state', (tester) async {
    setScreenSize(tester, const Size(390, 844));
    await tester.pumpWidget(const EleStockApp());

    await tester.enterText(find.byType(SearchBar), 'flux capacitor');
    await tester.pump();

    expect(find.text('No items match your search'), findsOneWidget);
  });
}
