import 'transaction_type.dart';

class StockTransaction {
  const StockTransaction({
    required this.id,
    required this.productId,
    required this.productName,
    required this.productCode,
    required this.type,
    required this.quantity,
    required this.date,
    this.notes,
    required this.createdAt,
  });

  final String id;
  final String productId;
  final String productName;
  final String productCode;
  final TransactionType type;
  final int quantity;
  final DateTime date;
  final String? notes;
  final DateTime createdAt;

  int get signedQuantity => type.isIn ? quantity : -quantity;

  /// Net change to apply to each affected product.
  static Map<String, int> stockDeltas({
    StockTransaction? previous,
    StockTransaction? next,
  }) {
    final deltas = <String, int>{
      if (previous != null) previous.productId: -previous.signedQuantity,
    };
    if (next != null) {
      deltas.update(
        next.productId,
        (delta) => delta + next.signedQuantity,
        ifAbsent: () => next.signedQuantity,
      );
    }
    return deltas;
  }

  StockTransaction copyWith({
    String? id,
    String? productId,
    String? productName,
    String? productCode,
    TransactionType? type,
    int? quantity,
    DateTime? date,
    String? notes,
    bool clearNotes = false,
    DateTime? createdAt,
  }) {
    return StockTransaction(
      id: id ?? this.id,
      productId: productId ?? this.productId,
      productName: productName ?? this.productName,
      productCode: productCode ?? this.productCode,
      type: type ?? this.type,
      quantity: quantity ?? this.quantity,
      date: date ?? this.date,
      notes: clearNotes ? null : notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
