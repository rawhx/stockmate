import '../entities/product.dart';

abstract interface class ProductRepository {
  Future<List<Product>> getProducts();

  Future<Product?> getProduct(String id);

  Future<void> createProduct(Product product);

  Future<void> updateProduct(Product product);

  Future<void> deleteProduct(String id);
}
