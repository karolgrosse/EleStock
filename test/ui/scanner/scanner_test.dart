import 'package:elestock/ui/item_details/item_details_screen.dart';
import 'package:elestock/ui/scanner/scanner_screen.dart';
import 'package:elestock/ui/scanner/scanner_view_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/repositories.dart';

void main() {
  group('ScannerViewModel.parseCode', () {
    test('accepts a plain id', () {
      expect(ScannerViewModel.parseCode('  dt-crimp-16 '), 'dt-crimp-16');
    });

    test('reads the id from a label link', () {
      expect(ScannerViewModel.parseCode('elestock://items/tps'), 'tps');
      expect(
        ScannerViewModel.parseCode('https://elestock.app/items/m6-bolt'),
        'm6-bolt',
      );
    });

    test('rejects empty codes and foreign links', () {
      expect(ScannerViewModel.parseCode('   '), isNull);
      expect(ScannerViewModel.parseCode('https://example.com/a'), isNull);
    });
  });

  group('ScannerViewModel.lookUp', () {
    test('returns the id of a known item', () async {
      final vm = ScannerViewModel(instantRepository());

      expect(await vm.lookUp('tps'), 'tps');
      expect(vm.state, isA<ScannerIdle>());
    });

    test('says "not found" for an unknown code', () async {
      final vm = ScannerViewModel(instantRepository());

      expect(await vm.lookUp('flux-capacitor'), isNull);
      expect(vm.state, isA<ScannerNotFound>());
    });

    test('shows an error when the repository fails', () async {
      final vm = ScannerViewModel(instantRepository(failureRate: 1));

      expect(await vm.lookUp('tps'), isNull);
      expect(vm.state, isA<ScannerError>());
    });
  });

  group('ScannerScreen', () {
    Future<void> pumpScanner(WidgetTester tester) async {
      tester.view.physicalSize = const Size(600, 1400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        withRepository(const MaterialApp(home: ScannerScreen())),
      );
    }

    testWidgets('an unknown id shows an error', (tester) async {
      await pumpScanner(tester);

      await tester.enterText(
        find.byKey(const Key('item-id-field')),
        'flux-capacitor',
      );
      await tester.tap(find.text('Open item'));
      await tester.pumpAndSettle();

      expect(find.text('No item with the id "flux-capacitor"'), findsOneWidget);
      expect(find.byType(ItemDetailsScreen), findsNothing);
    });

    testWidgets('a known id opens the item details', (tester) async {
      await pumpScanner(tester);

      await tester.enterText(find.byKey(const Key('item-id-field')), 'tps');
      await tester.tap(find.text('Open item'));
      await tester.pumpAndSettle();

      expect(find.byType(ItemDetailsScreen), findsOneWidget);
      expect(find.text('Shelf B / Box 3'), findsOneWidget);
    });
  });
}
