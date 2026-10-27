import '../models/product_model.dart';

class ProductMockDataSource {
  final List<ProductModel> _products = [
    const ProductModel(
      id: '1',
      code: 'PRD-001',
      name: 'Beras Premium',
      price: 75000,
      unit: 'bag',
      categoryId: 'cat-1',
      categoryName: 'Food',
      supplierId: 'sup-1',
      supplierName: 'PT Sumber Pangan',
      minimumStock: 10,
      currentStock: 25,
    ),
    const ProductModel(
      id: '2',
      code: 'PRD-002',
      name: 'Mineral Water 600ml',
      price: 5000,
      unit: 'bottle',
      categoryId: 'cat-2',
      categoryName: 'Beverage',
      supplierId: 'sup-2',
      supplierName: 'CV Tirta Sejahtera',
      minimumStock: 20,
      currentStock: 12,
    ),
    const ProductModel(
      id: '3',
      code: 'PRD-003',
      name: 'Cooking Oil 1L',
      price: 18000,
      unit: 'bottle',
      categoryId: 'cat-1',
      categoryName: 'Food',
      supplierId: 'sup-1',
      supplierName: 'PT Sumber Pangan',
      minimumStock: 15,
      currentStock: 30,
    ),
  ];

  Future<List<ProductModel>> getProducts() async {
    await Future<void>.delayed(const Duration(milliseconds: 300));

    return List.unmodifiable(_products);
  }

  Future<ProductModel?> getProduct(String id) async {
    await Future<void>.delayed(const Duration(milliseconds: 150));

    for (final product in _products) {
      if (product.id == id) {
        return product;
      }
    }

    return null;
  }

  Future<void> createProduct(ProductModel product) async {
    await Future<void>.delayed(const Duration(milliseconds: 200));

    _products.add(product);
  }

  Future<void> updateProduct(ProductModel product) async {
    await Future<void>.delayed(const Duration(milliseconds: 200));

    final index = _products.indexWhere((item) => item.id == product.id);

    if (index == -1) {
      throw StateError('Product not found.');
    }

    _products[index] = product;
  }

  Future<void> deleteProduct(String id) async {
    await Future<void>.delayed(const Duration(milliseconds: 200));

    _products.removeWhere((product) => product.id == id);
  }
}
