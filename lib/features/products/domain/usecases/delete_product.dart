import '../repositories/product_repository.dart';

class DeleteProduct {
  const DeleteProduct(this.repository);

  final ProductRepository repository;

  Future<void> call(String id) {
    return repository.deleteProduct(id);
  }
}
