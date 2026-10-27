import 'package:flutter/foundation.dart';

@immutable
class CategoryProduct {
  final String code;
  final String name;
  final double price;

  const CategoryProduct({
    required this.code,
    required this.name,
    required this.price,
  });
}

class CategoryProductMockStore extends ChangeNotifier {
  CategoryProductMockStore._();

  static final CategoryProductMockStore instance = CategoryProductMockStore._();

  final Map<String, List<CategoryProduct>> _products = {
    'CAT001': [
      const CategoryProduct(code: 'BRG001', name: 'Pensil 2B', price: 3000),
      const CategoryProduct(code: 'BRG002', name: 'Buku Tulis', price: 6000),
    ],
    'CAT002': [
      const CategoryProduct(
        code: 'BRG003',
        name: 'Mouse Wireless',
        price: 85000,
      ),
      const CategoryProduct(code: 'BRG004', name: 'Keyboard', price: 125000),
    ],
    'CAT003': [
      const CategoryProduct(code: 'BRG005', name: 'Kursi Lipat', price: 95000),
      const CategoryProduct(
        code: 'BRG006',
        name: 'Kotak Penyimpanan',
        price: 25000,
      ),
    ],
    'CAT004': [
      const CategoryProduct(code: 'BRG007', name: 'Pulpen Hitam', price: 4000),
      const CategoryProduct(
        code: 'BRG008',
        name: 'Pensil Mekanik',
        price: 12000,
      ),
    ],
    'CAT005': [
      const CategoryProduct(
        code: 'BRG009',
        name: 'Mouse Wireless',
        price: 85000,
      ),
      const CategoryProduct(code: 'BRG010', name: 'Keyboard', price: 125000),
    ],
  };

  List<CategoryProduct> productsFor(String categoryId) =>
      List.unmodifiable(_products[categoryId] ?? const <CategoryProduct>[]);

  void addProduct(String categoryId, CategoryProduct product) {
    _products.putIfAbsent(categoryId, () => []).add(product);
    notifyListeners();
  }
}
