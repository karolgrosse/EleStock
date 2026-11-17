// Validators for the item form. Each returns an error message, or `null`
// when the value is fine. Top-level functions so that they can be
// unit-tested without building the form.

const maxNameLength = 80;
const maxShortTextLength = 40;

/// Large enough for any box in the workshop, small enough to catch typos
/// like an extra zero.
const maxStock = 100000;

String? validateName(String? value) {
  final name = value?.trim() ?? '';
  if (name.isEmpty) return 'Enter a name';
  if (name.length > maxNameLength) {
    return 'Use at most $maxNameLength characters';
  }
  return null;
}

/// For the required short fields: location and unit.
String? validateRequiredShort(String? value, {required String field}) {
  final text = value?.trim() ?? '';
  if (text.isEmpty) return 'Enter the $field';
  return validateOptionalShort(text);
}

/// For the optional short fields, e.g. the part number.
String? validateOptionalShort(String? value) {
  final text = value?.trim() ?? '';
  if (text.length > maxShortTextLength) {
    return 'Use at most $maxShortTextLength characters';
  }
  return null;
}

/// For the starting stock and the reorder threshold: a whole number from 0.
String? validateCount(String? value) {
  final text = value?.trim() ?? '';
  if (text.isEmpty) return 'Enter a number';
  final n = int.tryParse(text);
  if (n == null) return 'Enter a whole number';
  if (n < 0) return 'Cannot be negative';
  if (n > maxStock) return 'Must be at most $maxStock';
  return null;
}
