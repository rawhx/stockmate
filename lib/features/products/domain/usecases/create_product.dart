import '../entities/product.dart';
import '../repositories/product_repository.dart';

class CreateProduct {
  const CreateProduct(this.repository);

  final ProductRepository repository;

  Future<void> call(Product product) {
    return repository.createProduct(product);
  }
}
