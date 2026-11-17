import '../entities/category_entity.dart';
import '../repositories/category_repository.dart';

class GetCategoryById {
  final CategoryRepository repository;

  const GetCategoryById(this.repository);

  Future<CategoryEntity?> call(String id) {
    return repository.getCategoryById(id);
  }
}
