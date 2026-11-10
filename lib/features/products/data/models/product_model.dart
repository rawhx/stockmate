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
}
