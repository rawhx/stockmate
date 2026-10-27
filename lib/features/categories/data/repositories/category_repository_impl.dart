import '../../domain/entities/category_entity.dart';
import '../../domain/repositories/category_repository.dart';
import '../datasources/category_mock_datasource.dart';
import '../models/category_model.dart';

class CategoryRepositoryImpl implements CategoryRepository {
  final CategoryMockDataSource dataSource;

  CategoryRepositoryImpl(this.dataSource);

  @override
  Future<List<CategoryEntity>> getCategories() {
    return dataSource.getCategories();
  }

  @override
  Future<CategoryEntity?> getCategoryById(String id) {
    return dataSource.getCategoryById(id);
  }

  CategoryModel _toModel(CategoryEntity category) {
    return CategoryModel(
      id: category.id,
      ownerId: category.ownerId,
      name: category.name,
      description: category.description,
      parentId: category.parentId,
      createdAt: category.createdAt,
      updatedAt: category.updatedAt,
    );
  }

  @override
  Future<void> addCategory(CategoryEntity category) {
    return dataSource.addCategory(_toModel(category));
  }

  @override
  Future<void> updateCategory(CategoryEntity category) {
    return dataSource.updateCategory(_toModel(category));
  }

  @override
  Future<void> deleteCategory(String id) {
    return dataSource.deleteCategory(id);
  }
}
