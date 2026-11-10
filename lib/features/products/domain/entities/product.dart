class Product {
  const Product({
    required this.id,
    required this.code,
    required this.name,
    required this.price,
    required this.unit,
    required this.categoryId,
    required this.categoryName,
    this.supplierId,
    this.supplierName,
    required this.minimumStock,
    required this.currentStock,
  });

  final String id;
  final String code;
  final String name;
  final double price;
  final String unit;
  final String categoryId;
  final String categoryName;
  final String? supplierId;
  final String? supplierName;
  final int minimumStock;
  final int currentStock;

  bool get isLowStock => currentStock <= minimumStock;

  Product copyWith({
    String? id,
    String? code,
    String? name,
    double? price,
    String? unit,
    String? categoryId,
    String? categoryName,
    String? supplierId,
    String? supplierName,
    int? minimumStock,
    int? currentStock,
  }) {
    return Product(
      id: id ?? this.id,
      code: code ?? this.code,
      name: name ?? this.name,
      price: price ?? this.price,
      unit: unit ?? this.unit,
      categoryId: categoryId ?? this.categoryId,
      categoryName: categoryName ?? this.categoryName,
      supplierId: supplierId ?? this.supplierId,
      supplierName: supplierName ?? this.supplierName,
      minimumStock: minimumStock ?? this.minimumStock,
      currentStock: currentStock ?? this.currentStock,
    );
  }
}
