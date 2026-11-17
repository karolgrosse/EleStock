import 'package:elestock/data/repositories/fake_inventory_repository.dart';
import 'package:elestock/domain/models/item.dart';
import 'package:elestock/ui/item_form/item_form_view_model.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/repositories.dart';

/// Loads fine, but every save fails (e.g. the connection dropped).
class _SaveFailsRepository extends FakeInventoryRepository {
  _SaveFailsRepository() : super(delay: Duration.zero);

  @override
  Future<Item> createItem(Item item) async => throw Exception('offline');

  @override
  Future<Item> updateItem(Item item) async => throw Exception('offline');
}

const ItemDraft _draft = (
  name: 'M3 brass standoff, 10 mm',
  category: ItemCategory.fasteners,
  location: 'Shelf C / Drawer 6',
  quantity: 50,
  unit: 'pcs',
  lowStockThreshold: 10,
  partNumber: null,
  notes: null,
);

void main() {
  group('new item', () {
    test('is ready at once, without loading', () async {
      final vm = ItemFormViewModel(items: instantRepository());

      expect(vm.isEditing, isFalse);
      expect(vm.state, isA<ItemFormReady>());
      await vm.load();
      expect((vm.state as ItemFormReady).initial, isNull);
    });

    test('save creates the item and announces it to other screens', () async {
      final repo = instantRepository();
      final vm = ItemFormViewModel(items: repo);
      final announced = repo.itemUpdates.first;

      final saved = await vm.save(_draft);

      expect(saved, isNotNull);
      expect(saved!.id, isNotEmpty);
      expect(saved.name, _draft.name);
      expect(saved.quantity, 50);
      expect(await announced, saved);
      expect(await repo.fetchItem(saved.id), saved);
      expect(vm.isSaving, isFalse);
    });

    test('save returns null when the repository fails', () async {
      final vm = ItemFormViewModel(items: _SaveFailsRepository());

      final saved = await vm.save(_draft);

      expect(saved, isNull);
      expect(vm.isSaving, isFalse);
      expect(vm.state, isA<ItemFormReady>(), reason: 'the form stays usable');
    });
  });

  group('edit item', () {
    test('loads the item being edited', () async {
      final vm = ItemFormViewModel(
        itemId: 'm6-bolt',
        items: instantRepository(),
      );
      expect(vm.state, isA<ItemFormLoading>());

      await vm.load();

      expect((vm.state as ItemFormReady).initial!.id, 'm6-bolt');
    });

    test(
      'shows not found for an unknown id, and an error when loading fails',
      () async {
        final missing = ItemFormViewModel(
          itemId: 'no-such-item',
          items: instantRepository(),
        );
        await missing.load();
        expect(missing.state, isA<ItemFormNotFound>());

        final failing = ItemFormViewModel(
          itemId: 'm6-bolt',
          items: instantRepository(failureRate: 1),
        );
        await failing.load();
        expect(failing.state, isA<ItemFormError>());
      },
    );

    test('save changes the details but never the stock', () async {
      final repo = instantRepository();
      final vm = ItemFormViewModel(itemId: 'dt-crimp-16', items: repo);
      await vm.load();

      final saved = await vm.save((
        name: 'DT crimp contacts, size 16',
        category: ItemCategory.connectors,
        location: 'Shelf A / Box 9',
        quantity: 999, // ignored when editing
        unit: 'pcs',
        lowStockThreshold: 30,
        partNumber: null, // cleared
        notes: null,
      ));

      expect(saved!.id, 'dt-crimp-16');
      expect(saved.location, 'Shelf A / Box 9');
      expect(saved.lowStockThreshold, 30);
      expect(saved.partNumber, isNull);
      expect(saved.quantity, 6);
    });
  });
}
