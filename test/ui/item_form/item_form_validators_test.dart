import 'package:elestock/ui/item_form/item_form_validators.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('name is required and limited in length', () {
    expect(validateName(null), isNotNull);
    expect(validateName('   '), isNotNull);
    expect(validateName('x' * (maxNameLength + 1)), isNotNull);
    expect(validateName('  M5 nyloc nut  '), isNull);
  });

  test('location and unit are required, part number is optional', () {
    expect(validateRequiredShort('', field: 'location'), 'Enter the location');
    expect(validateRequiredShort('Shelf B / Box 3', field: 'location'), isNull);
    expect(validateOptionalShort(''), isNull);
    expect(validateOptionalShort('x' * (maxShortTextLength + 1)), isNotNull);
  });

  test('counts are whole numbers from 0 up to the maximum', () {
    expect(validateCount(''), 'Enter a number');
    expect(validateCount('2.5'), 'Enter a whole number');
    expect(validateCount('abc'), 'Enter a whole number');
    expect(validateCount('-1'), 'Cannot be negative');
    expect(validateCount('${maxStock + 1}'), isNotNull);
    expect(validateCount(' 0 '), isNull);
    expect(validateCount('40'), isNull);
  });
}
