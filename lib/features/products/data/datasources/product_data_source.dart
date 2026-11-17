import 'package:stockmate/features/products/data/models/product_model.dart';


abstract interface class ProductDataSource {
  Future<List<ProductModel>> getProducts();

  Future<ProductModel?> getProduct(String id);

  Future<void> createProduct(ProductModel product);

  Future<void> updateProduct(ProductModel product);

  Future<void> deleteProduct(String id);
}
