import '../../domain/entities/product.dart';

class ProductModel extends Product {
  const ProductModel({
    required super.id,
    required super.code,
    required super.name,
    required super.price,
    required super.unit,
    required super.categoryId,
    required super.categoryName,
    super.supplierId,
    super.supplierName,
    required super.minimumStock,
    required super.currentStock,
  });

  factory ProductModel.fromMap(Map<String, dynamic> map) {
    return ProductModel(
      id: map['id'] as String,
      code: map['code'] as String,
      name: map['name'] as String,
      price: (map['price'] as num).toDouble(),
      unit: map['unit'] as String,
      categoryId: map['category_id'] as String,
      categoryName: _relationName(map['categories']),
      supplierId: map['supplier_id'] as String?,
      supplierName: _relationName(map['suppliers']),
      minimumStock: (map['minimum_stock'] as num?)?.toInt() ?? 0,
      currentStock: (map['current_stock'] as num?)?.toInt() ?? 0,
    );
  }

  factory ProductModel.fromEntity(Product product) {
    return ProductModel(
      id: product.id,
      code: product.code,
      name: product.name,
      price: product.price,
      unit: product.unit,
      categoryId: product.categoryId,
      categoryName: product.categoryName,
      supplierId: product.supplierId,
      supplierName: product.supplierName,
      minimumStock: product.minimumStock,
      currentStock: product.currentStock,
    );
  }
}

String _relationName(dynamic relation) {
  if (relation is Map<String, dynamic>) {
    return relation['name'] as String? ?? '';
  }
  if (relation is List && relation.isNotEmpty) {
    final first = relation.first;
    if (first is Map<String, dynamic>) {
      return first['name'] as String? ?? '';
    }
  }
  return '';
}
