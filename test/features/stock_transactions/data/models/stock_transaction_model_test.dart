import 'package:flutter_test/flutter_test.dart';
import 'package:stockmate/features/stock_transactions/data/models/stock_transaction_model.dart';
import 'package:stockmate/features/stock_transactions/domain/entities/transaction_type.dart';

void main() {
  test('editing can preserve, replace or explicitly clear a note', () {
    final transaction = StockTransactionModel(
      id: 'tx-1',
      productId: 'product-1',
      productName: 'Beras',
      productCode: 'BR-1',
      type: TransactionType.inStock,
      quantity: 4,
      date: DateTime.utc(2026),
      createdAt: DateTime.utc(2026),
      notes: 'Catatan lama',
    );
    expect(transaction.copyWith(quantity: 5).notes, 'Catatan lama');
    expect(transaction.copyWith(notes: 'Baru').notes, 'Baru');
    final cleared = StockTransactionModel.fromEntity(
      transaction.copyWith(clearNotes: true),
    );
    expect(cleared.toWriteJson(), containsPair('note', null));
  });

  test('StockTransactionModel.fromJson parses direct fields', () {
    final json = {
      'id': 'tx-123',
      'product_id': 'prod-456',
      'product_name': 'Minyak Goreng',
      'product_code': 'PRD-003',
      'type': 'IN',
      'quantity': 25,
      'date': '2026-11-25T10:00:00.000Z',
      'notes': 'Restock batch 1',
      'created_at': '2026-11-25T10:00:00.000Z',
    };

    final model = StockTransactionModel.fromJson(json);

    expect(model.id, 'tx-123');
    expect(model.productId, 'prod-456');
    expect(model.productName, 'Minyak Goreng');
    expect(model.productCode, 'PRD-003');
    expect(model.type, TransactionType.inStock);
    expect(model.quantity, 25);
    expect(model.notes, 'Restock batch 1');
  });

  test('StockTransactionModel.fromJson parses joined products relation', () {
    final json = {
      'id': 'tx-789',
      'product_id': 'prod-999',
      'type': 'OUT',
      'quantity': 5,
      'date': '2026-11-25T11:00:00.000Z',
      'notes': 'Penjualan retail',
      'created_at': '2026-11-25T11:00:00.000Z',
      'products': {
        'name': 'Beras Premium',
        'code': 'PRD-001',
      },
    };

    final model = StockTransactionModel.fromJson(json);

    expect(model.id, 'tx-789');
    expect(model.productId, 'prod-999');
    expect(model.productName, 'Beras Premium');
    expect(model.productCode, 'PRD-001');
    expect(model.type, TransactionType.outStock);
    expect(model.quantity, 5);
  });

  test('StockTransactionModel.toWriteJson omits local dummy ID and includes database columns', () {
    final model = StockTransactionModel(
      id: 'tx-123456789',
      productId: 'prod-456',
      productName: 'Minyak',
      productCode: 'PRD-003',
      type: TransactionType.inStock,
      quantity: 10,
      date: DateTime.parse('2026-11-25T12:00:00.000Z'),
      notes: 'catatan',
      createdAt: DateTime.now(),
    );

    final writeJson = model.toWriteJson();

    expect(writeJson.containsKey('id'), isFalse);
    expect(writeJson['product_id'], 'prod-456');
    expect(writeJson['type'], 'IN');
    expect(writeJson['quantity'], 10);
    expect(writeJson['transaction_date'], '2026-11-25T12:00:00.000Z');
    expect(writeJson['note'], 'catatan');
  });

  test('StockTransactionModel.toWriteJson preserves real UUID', () {
    const realUuid = '550e8400-e29b-41d4-a716-446655440000';
    final model = StockTransactionModel(
      id: realUuid,
      productId: 'prod-456',
      productName: 'Minyak',
      productCode: 'PRD-003',
      type: TransactionType.outStock,
      quantity: 2,
      date: DateTime.parse('2026-11-25T12:00:00.000Z'),
      createdAt: DateTime.now(),
    );

    final writeJson = model.toWriteJson();

    expect(writeJson['id'], realUuid);
    expect(writeJson['type'], 'OUT');
  });
}
