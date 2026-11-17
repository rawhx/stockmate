import 'package:flutter_test/flutter_test.dart';
import 'package:stockmate/features/products/domain/entities/product.dart';
import 'package:stockmate/features/stock_transactions/data/datasources/stock_transaction_mock_data_source.dart';
import 'package:stockmate/features/stock_transactions/data/repositories/stock_transaction_repository_impl.dart';
import 'package:stockmate/features/stock_transactions/domain/entities/stock_transaction.dart';
import 'package:stockmate/features/stock_transactions/domain/entities/transaction_type.dart';
import 'package:stockmate/features/stock_transactions/domain/usecases/create_stock_transaction.dart';
import 'package:stockmate/features/stock_transactions/domain/usecases/delete_stock_transaction.dart';
import 'package:stockmate/features/stock_transactions/domain/usecases/get_stock_transaction.dart';
import 'package:stockmate/features/stock_transactions/domain/usecases/get_stock_transactions.dart';
import 'package:stockmate/features/stock_transactions/domain/usecases/update_stock_transaction.dart';
import 'package:stockmate/features/stock_transactions/presentation/providers/stock_transaction_provider.dart';

void main() {
  late StockTransactionMockDataSource dataSource;
  late StockTransactionRepositoryImpl repository;
  late StockTransactionProvider provider;
  late Product testProduct;

  setUp(() {
    dataSource = StockTransactionMockDataSource();
    repository = StockTransactionRepositoryImpl(dataSource);

    testProduct = const Product(
      id: 'prod-100',
      code: 'PRD-100',
      name: 'Item Uji',
      price: 10000,
      unit: 'pcs',
      categoryId: 'c-1',
      categoryName: 'Uji',
      minimumStock: 5,
      currentStock: 20,
    );

    provider = StockTransactionProvider(
      getStockTransactions: GetStockTransactions(repository),
      getStockTransaction: GetStockTransaction(repository),
      createStockTransaction: CreateStockTransaction(repository),
      updateStockTransaction: UpdateStockTransaction(repository),
      deleteStockTransaction: DeleteStockTransaction(repository),
      onGetProduct: (id) async {
        if (id == testProduct.id) return testProduct;
        return null;
      },
      onUpdateProduct: (updated) async {
        if (updated.id == testProduct.id) {
          testProduct = updated;
          return true;
        }
        return false;
      },
    );
  });

  test(
    'fetchTransactions loads initial transactions and calculates totals',
    () async {
      await provider.fetchTransactions();

      expect(provider.transactions.isNotEmpty, true);
      expect(provider.totalInStockCount, greaterThan(0));
      expect(provider.totalOutStockCount, greaterThan(0));
      expect(provider.errorMessage, isNull);
    },
  );

  test('addTransaction with inStock increases product stock', () async {
    final initialStock = testProduct.currentStock;
    final tx = StockTransaction(
      id: 'tx-new-in',
      productId: testProduct.id,
      productName: testProduct.name,
      productCode: testProduct.code,
      type: TransactionType.inStock,
      quantity: 15,
      date: DateTime.now(),
      notes: 'Stok masuk tambahan',
      createdAt: DateTime.now(),
    );

    final success = await provider.addTransaction(tx);

    expect(success, isTrue);
    expect(testProduct.currentStock, equals(initialStock + 15));
    expect(provider.transactions.any((t) => t.id == 'tx-new-in'), isTrue);
  });

  test('addTransaction with outStock decreases product stock', () async {
    final initialStock = testProduct.currentStock; // 20
    final tx = StockTransaction(
      id: 'tx-new-out',
      productId: testProduct.id,
      productName: testProduct.name,
      productCode: testProduct.code,
      type: TransactionType.outStock,
      quantity: 8,
      date: DateTime.now(),
      notes: 'Penjualan',
      createdAt: DateTime.now(),
    );

    final success = await provider.addTransaction(tx);

    expect(success, isTrue);
    expect(testProduct.currentStock, equals(initialStock - 8));
  });

  test(
    'addTransaction with outStock exceeding stock is rejected with error',
    () async {
      final initialStock = testProduct.currentStock; // 20
      final tx = StockTransaction(
        id: 'tx-excess',
        productId: testProduct.id,
        productName: testProduct.name,
        productCode: testProduct.code,
        type: TransactionType.outStock,
        quantity: 25, // melebihi 20
        date: DateTime.now(),
        notes: 'Minta lebih dari stok',
        createdAt: DateTime.now(),
      );

      final success = await provider.addTransaction(tx);

      expect(success, isFalse);
      expect(
        testProduct.currentStock,
        equals(initialStock),
      ); // Stok tidak berubah
      expect(provider.errorMessage, contains('Stok tidak mencukupi'));
    },
  );

  test('editTransaction correctly updates stock differences', () async {
    // Buat transaksi keluar awal 5 unit -> sisa stok 15
    final tx = StockTransaction(
      id: 'tx-edit-test',
      productId: testProduct.id,
      productName: testProduct.name,
      productCode: testProduct.code,
      type: TransactionType.outStock,
      quantity: 5,
      date: DateTime.now(),
      createdAt: DateTime.now(),
    );
    await provider.addTransaction(tx);
    expect(testProduct.currentStock, equals(15));

    // Edit transaksi menjadi keluar 10 unit -> sisa stok seharusnya 10
    final updated = tx.copyWith(quantity: 10);
    final success = await provider.editTransaction(updated);

    expect(success, isTrue);
    expect(testProduct.currentStock, equals(10));
  });

  test('removeTransaction reverts stock effect', () async {
    // Catat keluar 6 unit -> sisa stok 14
    final tx = StockTransaction(
      id: 'tx-del-test',
      productId: testProduct.id,
      productName: testProduct.name,
      productCode: testProduct.code,
      type: TransactionType.outStock,
      quantity: 6,
      date: DateTime.now(),
      createdAt: DateTime.now(),
    );
    await provider.addTransaction(tx);
    expect(testProduct.currentStock, equals(14));

    // Hapus transaksi -> stok kembali ke 20
    final success = await provider.removeTransaction(tx.id);

    expect(success, isTrue);
    expect(testProduct.currentStock, equals(20));
  });

  test('filtering and search filter transactions accurately', () async {
    await provider.fetchTransactions();

    provider.setFilter(TransactionFilter.inStock);
    for (final tx in provider.filteredTransactions) {
      expect(tx.type, equals(TransactionType.inStock));
    }

    provider.setFilter(TransactionFilter.outStock);
    for (final tx in provider.filteredTransactions) {
      expect(tx.type, equals(TransactionType.outStock));
    }

    provider.setFilter(TransactionFilter.all);
    provider.setSearchQuery('PRD-001');
    for (final tx in provider.filteredTransactions) {
      expect(tx.productCode, contains('PRD-001'));
    }
  });
}
