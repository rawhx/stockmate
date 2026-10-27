import '../repositories/category_repository.dart';

class DeleteCategory {
  final CategoryRepository repository;

  const DeleteCategory(this.repository);

  Future<void> call(String id) {
    return repository.deleteCategory(id);
  }
}
