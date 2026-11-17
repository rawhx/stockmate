import '../../domain/entities/product.dart';
import '../../domain/repositories/product_repository.dart';
import '../datasources/product_mock_data_source.dart';
import '../models/product_model.dart';

class ProductRepositoryImpl implements ProductRepository {
  ProductRepositoryImpl(this.dataSource);

  final ProductMockDataSource dataSource;

  @override
  Future<List<Product>> getProducts() {
    return dataSource.getProducts();
  }

  @override
  Future<Product?> getProduct(String id) {
    return dataSource.getProduct(id);
  }

  @override
  Future<void> createProduct(Product product) {
    return dataSource.createProduct(ProductModel.fromEntity(product));
  }

  @override
  Future<void> updateProduct(Product product) {
    return dataSource.updateProduct(ProductModel.fromEntity(product));
  }

  @override
  Future<void> deleteProduct(String id) {
    return dataSource.deleteProduct(id);
  }
}
