import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../domain/models/item.dart';
import '../core/category_ui.dart';
import '../core/widgets/empty_state.dart';
import '../core/widgets/error_view.dart';
import 'item_form_validators.dart';
import 'item_form_view_model.dart';

/// Creates a new item (`/items/new`) or edits the item with [itemId]
/// (`/items/:id/edit`, lab 3). Pops with the saved [Item], or with `null`
/// when the user leaves without saving.
class ItemFormScreen extends StatelessWidget {
  const ItemFormScreen({super.key, this.itemId});

  final String? itemId;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) =>
          ItemFormViewModel.of(context, itemId: itemId)..load(),
      child: const _ItemFormScaffold(),
    );
  }
}

class _ItemFormScaffold extends StatelessWidget {
  const _ItemFormScaffold();

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<ItemFormViewModel>();
    return Scaffold(
      appBar: AppBar(title: Text(vm.isEditing ? 'Edit item' : 'New item')),
      body: switch (vm.state) {
        ItemFormLoading() => const Center(child: CircularProgressIndicator()),
        ItemFormError(:final message) => ErrorView(
          message: message,
          onRetry: vm.load,
        ),
        ItemFormNotFound() => const EmptyState(
          icon: Icons.help_outline,
          message: 'This item no longer exists',
        ),
        ItemFormReady(:final initial) => _ItemForm(initial: initial),
      },
    );
  }
}

class _ItemForm extends StatefulWidget {
  const _ItemForm({required this.initial});

  /// The item being edited, or `null` for a new item.
  final Item? initial;

  @override
  State<_ItemForm> createState() => _ItemFormState();
}

class _ItemFormState extends State<_ItemForm> {
  final _formKey = GlobalKey<FormState>();
  late final _name = TextEditingController(text: widget.initial?.name);
  late final _location = TextEditingController(text: widget.initial?.location);
  late final _quantity = TextEditingController(text: '0');
  late final _unit = TextEditingController(text: widget.initial?.unit ?? 'pcs');
  late final _threshold = TextEditingController(
    text: '${widget.initial?.lowStockThreshold ?? 0}',
  );
  late final _partNumber = TextEditingController(
    text: widget.initial?.partNumber,
  );
  late final _notes = TextEditingController(text: widget.initial?.notes);
  late ItemCategory _category =
      widget.initial?.category ?? ItemCategory.values.first;

  bool get _isNew => widget.initial == null;

  @override
  void dispose() {
    for (final c in [
      _name,
      _location,
      _quantity,
      _unit,
      _threshold,
      _partNumber,
      _notes,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  static String? _optional(TextEditingController c) =>
      c.text.trim().isEmpty ? null : c.text.trim();

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    // Read these before the await: the context may be gone afterwards.
    final vm = context.read<ItemFormViewModel>();
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);

    final saved = await vm.save((
      name: _name.text.trim(),
      category: _category,
      location: _location.text.trim(),
      quantity: int.parse(_quantity.text.trim()),
      unit: _unit.text.trim(),
      lowStockThreshold: int.parse(_threshold.text.trim()),
      partNumber: _optional(_partNumber),
      notes: _optional(_notes),
    ));

    if (saved == null) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Could not save the item. Try again.')),
      );
    } else {
      navigator.pop(saved);
    }
  }

  @override
  Widget build(BuildContext context) {
    final saving = context.select<ItemFormViewModel, bool>((vm) => vm.isSaving);
    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextFormField(
            key: const Key('name-field'),
            controller: _name,
            autofocus: _isNew,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(
              labelText: 'Name',
              hintText: 'e.g. M6×20 bolt, 12.9',
            ),
            validator: validateName,
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<ItemCategory>(
            key: const Key('category-field'),
            initialValue: _category,
            decoration: const InputDecoration(labelText: 'Category'),
            items: [
              for (final category in ItemCategory.values)
                DropdownMenuItem(
                  value: category,
                  child: Row(
                    children: [
                      Icon(category.icon, size: 20),
                      const SizedBox(width: 12),
                      Text(category.label),
                    ],
                  ),
                ),
            ],
            onChanged: (value) {
              if (value != null) setState(() => _category = value);
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            key: const Key('location-field'),
            controller: _location,
            decoration: const InputDecoration(
              labelText: 'Location',
              hintText: 'e.g. Shelf B / Box 3',
            ),
            validator: (v) => validateRequiredShort(v, field: 'location'),
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (_isNew) ...[
                Expanded(
                  child: TextFormField(
                    key: const Key('quantity-field'),
                    controller: _quantity,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Starting stock',
                    ),
                    validator: validateCount,
                  ),
                ),
                const SizedBox(width: 16),
              ],
              Expanded(
                child: TextFormField(
                  key: const Key('unit-field'),
                  controller: _unit,
                  decoration: const InputDecoration(
                    labelText: 'Unit',
                    hintText: 'pcs, m, g',
                  ),
                  validator: (v) => validateRequiredShort(v, field: 'unit'),
                ),
              ),
            ],
          ),
          if (!_isNew)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                'Stock: ${widget.initial!.quantity} ${widget.initial!.unit}. '
                'Change it with Take or Put back, so the history stays '
                'complete.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
          const SizedBox(height: 16),
          TextFormField(
            key: const Key('threshold-field'),
            controller: _threshold,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Reorder at or below',
              helperText: 'The item goes on the shopping list at this stock',
            ),
            validator: validateCount,
          ),
          const SizedBox(height: 16),
          TextFormField(
            key: const Key('part-number-field'),
            controller: _partNumber,
            decoration: const InputDecoration(
              labelText: 'Part number (optional)',
            ),
            validator: validateOptionalShort,
          ),
          const SizedBox(height: 16),
          TextFormField(
            key: const Key('notes-field'),
            controller: _notes,
            minLines: 2,
            maxLines: 5,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(labelText: 'Notes (optional)'),
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: saving ? null : _save,
            icon: saving
                ? const SizedBox.square(
                    dimension: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.check),
            label: Text(_isNew ? 'Add item' : 'Save changes'),
          ),
        ],
      ),
    );
  }
}
