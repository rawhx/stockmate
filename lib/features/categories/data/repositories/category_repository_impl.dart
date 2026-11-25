import '../../domain/entities/category_entity.dart';
import '../../domain/repositories/category_repository.dart';
import '../datasources/category_supabase_datasource.dart';
import '../models/category_model.dart';

class CategoryRepositoryImpl implements CategoryRepository {
  final CategorySupabaseDataSource dataSource;

  CategoryRepositoryImpl(this.dataSource);

  @override
  Future<List<CategoryEntity>> getCategories() async {
    return dataSource.getCategories();
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
  Future<void> addCategory(CategoryEntity category) async {
    await dataSource.addCategory(_toModel(category));
  }

  @override
  Future<void> updateCategory(CategoryEntity category) async {
    await dataSource.updateCategory(_toModel(category));
  }

  @override
  Future<void> deleteCategory(String id) {
    return dataSource.deleteCategory(id);
  }
}
