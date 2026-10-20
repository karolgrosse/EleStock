import 'package:elestock/domain/models/item.dart';
import 'package:elestock/ui/core/widgets/stock_badge.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Item _item(int quantity) => Item(
  id: 'x',
  name: 'Test',
  category: ItemCategory.fasteners,
  location: 'Shelf A',
  quantity: quantity,
  unit: 'pcs',
  lowStockThreshold: 5,
);

Future<void> _pump(WidgetTester tester, Item item) => tester.pumpWidget(
  MaterialApp(
    home: Scaffold(body: StockBadge(item: item)),
  ),
);

void main() {
  testWidgets('shows quantity and unit', (tester) async {
    await _pump(tester, _item(12));
    expect(find.text('12 pcs'), findsOneWidget);
  });

  testWidgets('tells screen readers when stock is low', (tester) async {
    final handle = tester.ensureSemantics();
    await _pump(tester, _item(3));

    expect(find.bySemanticsLabel('3 pcs, low stock'), findsOneWidget);
    handle.dispose();
  });
}
