import '../entities/product.dart';
import '../repositories/product_repository.dart';

class GetProduct {
  const GetProduct(this.repository);

  final ProductRepository repository;

  Future<Product?> call(String id) {
    return repository.getProduct(id);
  }
}
