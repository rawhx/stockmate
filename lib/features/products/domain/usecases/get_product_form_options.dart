import '../entities/product_form_options.dart';
import '../repositories/product_repository.dart';

class GetProductFormOptions {
  const GetProductFormOptions(this._repository);

  final ProductRepository _repository;

  Future<ProductFormOptions> call() => _repository.getFormOptions();
}
