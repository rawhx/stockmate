import '../entities/product.dart';
import '../repositories/product_repository.dart';

class UpdateProduct {
  const UpdateProduct(this.repository);

  final ProductRepository repository;

  Future<void> call(Product product) {
    return repository.updateProduct(product);
  }
}
