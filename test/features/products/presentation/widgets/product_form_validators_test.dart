import 'package:flutter_test/flutter_test.dart';
import 'package:stockmate/features/products/presentation/widgets/product_form_validators.dart';

void main() {
  test('rejects non-finite prices including overflowing digit input', () {
    for (final value in ['NaN', 'Infinity', '-Infinity', '9' * 400]) {
      expect(
        ProductFormValidators.positivePrice(value),
        isNotNull,
        reason: value,
      );
    }
  });

  test(
    'accepts positive finite prices and rejects zero or negative prices',
    () {
      for (final value in ['1', '75000', '1234.50']) {
        expect(ProductFormValidators.positivePrice(value), isNull);
      }
      for (final value in ['0', '-1', 'invalid', '']) {
        expect(ProductFormValidators.positivePrice(value), isNotNull);
      }
    },
  );
}
