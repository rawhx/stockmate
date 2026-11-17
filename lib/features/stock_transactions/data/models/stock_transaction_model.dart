import '../../domain/entities/stock_transaction.dart';
import '../../domain/entities/transaction_type.dart';

class StockTransactionModel extends StockTransaction {
  const StockTransactionModel({
    required super.id,
    required super.productId,
    required super.productName,
    required super.productCode,
    required super.type,
    required super.quantity,
    required super.date,
    super.notes,
    required super.createdAt,
  });

  factory StockTransactionModel.fromEntity(StockTransaction entity) {
    return StockTransactionModel(
      id: entity.id,
      productId: entity.productId,
      productName: entity.productName,
      productCode: entity.productCode,
      type: entity.type,
      quantity: entity.quantity,
      date: entity.date,
      notes: entity.notes,
      createdAt: entity.createdAt,
    );
  }

  factory StockTransactionModel.fromJson(Map<String, dynamic> json) {
    return StockTransactionModel(
      id: json['id'] as String,
      productId: json['product_id'] as String,
      productName: json['product_name'] as String,
      productCode: json['product_code'] as String,
      type: TransactionType.fromString(json['type'] as String),
      quantity: (json['quantity'] as num).toInt(),
      date: DateTime.parse(json['date'] as String),
      notes: json['notes'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'product_id': productId,
      'product_name': productName,
      'product_code': productCode,
      'type': type == TransactionType.inStock ? 'IN' : 'OUT',
      'quantity': quantity,
      'date': date.toIso8601String(),
      'notes': notes,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
