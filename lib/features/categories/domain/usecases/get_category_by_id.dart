import '../entities/category_entity.dart';
import '../repositories/category_repository.dart';

class GetCategoryById {
  const GetCategoryById(this.repository);

  final CategoryRepository repository;

  Future<CategoryEntity?> call(String id) => repository.getCategory(id);
}
