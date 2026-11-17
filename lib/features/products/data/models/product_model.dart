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

  factory ProductModel.fromJson(
    Map<String, dynamic> json, {
    required String categoryName,
    String? supplierName,
  }) {
    return ProductModel(
      id: json['id'] as String,
      code: json['code'] as String,
      name: json['name'] as String,
      price: (json['price'] as num).toDouble(),
      unit: json['unit'] as String,
      categoryId: json['category_id'] as String,
      categoryName: categoryName,
      supplierId: json['supplier_id'] as String?,
      supplierName: supplierName,
      minimumStock: (json['minimum_stock'] as num).toInt(),
      currentStock: (json['current_stock'] as num).toInt(),
    );
  }

  Map<String, dynamic> toWriteJson() {
    return {
      'code': code,
      'name': name,
      'price': price,
      'unit': unit,
      'category_id': categoryId,
      'supplier_id': supplierId,
      'minimum_stock': minimumStock,
    };
  }
}
