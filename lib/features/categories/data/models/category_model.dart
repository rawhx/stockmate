import '../../domain/entities/category_entity.dart';

class CategoryModel extends CategoryEntity {
  const CategoryModel({
    required super.id,
    required super.ownerId,
    required super.name,
    super.description,
    super.parentId,
    required super.createdAt,
    required super.updatedAt,
  });
}
