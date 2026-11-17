import '../entities/product.dart';
import '../entities/product_form_options.dart';

abstract interface class ProductRepository {
  Future<ProductFormOptions> getFormOptions();

  Future<List<Product>> getProducts();

  Future<Product?> getProduct(String id);

  Future<void> createProduct(Product product);

  Future<void> updateProduct(Product product);

  Future<void> deleteProduct(String id);
}
