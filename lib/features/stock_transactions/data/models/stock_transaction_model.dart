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

  factory StockTransactionModel.fromJson(
    Map<String, dynamic> json, {
    String? productName,
    String? productCode,
  }) {
    final productData = json['products'] as Map<String, dynamic>?;
    final resolvedName = productName ??
        productData?['name'] as String? ??
        json['product_name'] as String? ??
        '';
    final resolvedCode = productCode ??
        productData?['code'] as String? ??
        json['product_code'] as String? ??
        '';

    final dateStr = (json['transaction_date'] ?? json['date']) as String;
    final notesVal = (json['note'] ?? json['notes']) as String?;

    return StockTransactionModel(
      id: json['id'] as String,
      productId: json['product_id'] as String,
      productName: resolvedName,
      productCode: resolvedCode,
      type: TransactionType.fromString(json['type'] as String),
      quantity: (json['quantity'] as num).toInt(),
      date: DateTime.parse(dateStr),
      notes: notesVal,
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
      'transaction_date': date.toIso8601String(),
      'date': date.toIso8601String(),
      'note': notes,
      'notes': notes,
      'created_at': createdAt.toIso8601String(),
    };
  }

  Map<String, dynamic> toWriteJson() {
    return {
      if (id.isNotEmpty && !id.startsWith('tx-')) 'id': id,
      'product_id': productId,
      'type': type == TransactionType.inStock ? 'IN' : 'OUT',
      'quantity': quantity,
      'transaction_date': date.toIso8601String(),
      if (notes != null) 'note': notes,
    };
  }
}
