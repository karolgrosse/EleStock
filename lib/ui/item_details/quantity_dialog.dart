import 'package:flutter/material.dart';

/// What the user entered in [showQuantityDialog].
typedef QuantityInput = ({int quantity, String? note});

/// Asks how many units to take or put back, with validation.
///
/// [max] limits the quantity (the current stock when taking); `null` means
/// no upper limit. Returns `null` when the dialog is cancelled.
Future<QuantityInput?> showQuantityDialog(
  BuildContext context, {
  required String title,
  required String confirmLabel,
  required String unit,
  int? max,
}) => showDialog<QuantityInput>(
  context: context,
  builder: (_) => _QuantityDialog(
    title: title,
    confirmLabel: confirmLabel,
    unit: unit,
    max: max,
  ),
);

/// Validates the quantity field. Public so that it can be unit-tested.
String? validateQuantity(String? value, {int? max}) {
  final n = int.tryParse(value?.trim() ?? '');
  if (n == null) return 'Enter a whole number';
  if (n < 1) return 'Enter at least 1';
  if (max != null && n > max) return 'Only $max left';
  return null;
}

class _QuantityDialog extends StatefulWidget {
  const _QuantityDialog({
    required this.title,
    required this.confirmLabel,
    required this.unit,
    required this.max,
  });

  final String title;
  final String confirmLabel;
  final String unit;
  final int? max;

  @override
  State<_QuantityDialog> createState() => _QuantityDialogState();
}

class _QuantityDialogState extends State<_QuantityDialog> {
  final _formKey = GlobalKey<FormState>();
  final _quantity = TextEditingController(text: '1');
  final _note = TextEditingController();

  @override
  void dispose() {
    _quantity.dispose();
    _note.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.of(context).pop<QuantityInput>((
      quantity: int.parse(_quantity.text.trim()),
      note: _note.text.trim().isEmpty ? null : _note.text.trim(),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              key: const Key('quantity-field'),
              controller: _quantity,
              autofocus: true,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Quantity',
                suffixText: widget.unit,
                helperText: widget.max == null
                    ? null
                    : '${widget.max} ${widget.unit} in stock',
              ),
              validator: (v) => validateQuantity(v, max: widget.max),
              onFieldSubmitted: (_) => _submit(),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _note,
              decoration: const InputDecoration(
                labelText: 'Note (optional)',
                hintText: 'e.g. steering wheel harness',
              ),
              textInputAction: TextInputAction.done,
              onFieldSubmitted: (_) => _submit(),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(onPressed: _submit, child: Text(widget.confirmLabel)),
      ],
    );
  }
}
