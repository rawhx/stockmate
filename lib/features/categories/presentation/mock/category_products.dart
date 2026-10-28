import 'package:flutter/foundation.dart';

@immutable
class CategoryProduct {
  final String code;
  final String name;
  final double price;
  final String? imageUrl;

  const CategoryProduct({
    required this.code,
    required this.name,
    required this.price,
    this.imageUrl = '',
  });
}

class CategoryProductMockStore extends ChangeNotifier {
  CategoryProductMockStore._();

  static final CategoryProductMockStore instance = CategoryProductMockStore._();

  final Map<String, List<CategoryProduct>> _products = {
    // Kategori induk menampilkan produk melalui subkategorinya.
    'CAT001': <CategoryProduct>[], // ATK
    'CAT002': <CategoryProduct>[], // Elektronik
    'CAT003': [
      const CategoryProduct(
        code: 'BRG006',
        name: 'Kursi Lipat',
        price: 95000,
        imageUrl:
            'https://images.unsplash.com/photo-1505843490701-5a442a4b4f64?w=160&q=80',
      ),
      const CategoryProduct(
        code: 'BRG007',
        name: 'Kotak Penyimpanan',
        price: 25000,
        imageUrl:
            'https://images.unsplash.com/photo-1558997519-83ea9252edf8?w=160&q=80',
      ),
    ],
    'CAT004': [
      const CategoryProduct(
        code: 'BRG001',
        name: 'Pensil 2B',
        price: 3000,
        imageUrl:
            'https://images.unsplash.com/photo-1583485088034-697b5bc54ccd?w=160&q=80',
      ),
      const CategoryProduct(
        code: 'BRG002',
        name: 'Pulpen Hitam',
        price: 4000,
        imageUrl:
            'https://images.unsplash.com/photo-1585336261022-680e295ce3fe?w=160&q=80',
      ),
      const CategoryProduct(
        code: 'BRG003',
        name: 'Buku Tulis',
        price: 6000,
        imageUrl:
            'https://images.unsplash.com/photo-1544947950-fa07a98d237f?w=160&q=80',
      ),
    ],
    'CAT005': [
      const CategoryProduct(
        code: 'BRG004',
        name: 'Mouse Wireless',
        price: 85000,
        imageUrl:
            'https://images.unsplash.com/photo-1527814050087-3793815479db?w=160&q=80',
      ),
      const CategoryProduct(
        code: 'BRG005',
        name: 'Keyboard',
        price: 125000,
        imageUrl:
            'https://images.unsplash.com/photo-1587829741301-dc798b83add3?w=160&q=80',
      ),
    ],
  };

  List<CategoryProduct> productsFor(String categoryId) =>
      List.unmodifiable(_products[categoryId] ?? const <CategoryProduct>[]);

  void addProduct(String categoryId, CategoryProduct product) {
    _products.putIfAbsent(categoryId, () => []).add(product);
    notifyListeners();
  }
}
