import 'package:flutter_test/flutter_test.dart';
import 'package:stockmate/features/products/data/models/product_model.dart';

void main() {
  test('maps stock summary and related names into product', () {
    final product = ProductModel.fromJson(
      {
        'id': 'product-1',
        'code': 'PRD-001',
        'name': 'Beras Premium',
        'price': 75000,
        'unit': 'bag',
        'category_id': 'category-1',
        'supplier_id': 'supplier-1',
        'minimum_stock': 10,
        'current_stock': 25,
      },
      categoryName: 'Food',
      supplierName: 'PT Sumber Pangan',
    );

    expect(product.unit, 'bag');
    expect(product.categoryName, 'Food');
    expect(product.supplierId, 'supplier-1');
    expect(product.supplierName, 'PT Sumber Pangan');
    expect(product.price, 75000.0);
    expect(product.currentStock, 25);
  });
}
