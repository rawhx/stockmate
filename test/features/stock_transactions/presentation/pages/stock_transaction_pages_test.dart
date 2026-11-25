import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:stockmate/features/products/data/datasources/product_mock_data_source.dart';
import 'package:stockmate/features/products/data/repositories/product_repository_impl.dart';
import 'package:stockmate/features/products/domain/usecases/create_product.dart';
import 'package:stockmate/features/products/domain/usecases/delete_product.dart';
import 'package:stockmate/features/products/domain/usecases/get_product.dart';
import 'package:stockmate/features/products/domain/usecases/get_product_form_options.dart';
import 'package:stockmate/features/products/domain/usecases/get_products.dart';
import 'package:stockmate/features/products/domain/usecases/update_product.dart';
import 'package:stockmate/features/products/presentation/providers/product_provider.dart';
import 'package:stockmate/features/stock_transactions/data/datasources/stock_transaction_mock_data_source.dart';
import 'package:stockmate/features/stock_transactions/data/repositories/stock_transaction_repository_impl.dart';
import 'package:stockmate/features/stock_transactions/domain/usecases/create_stock_transaction.dart';
import 'package:stockmate/features/stock_transactions/domain/usecases/delete_stock_transaction.dart';
import 'package:stockmate/features/stock_transactions/domain/usecases/get_stock_transaction.dart';
import 'package:stockmate/features/stock_transactions/domain/usecases/get_stock_transactions.dart';
import 'package:stockmate/features/stock_transactions/domain/usecases/update_stock_transaction.dart';
import 'package:stockmate/features/stock_transactions/presentation/pages/stock_transaction_detail_page.dart';
import 'package:stockmate/features/stock_transactions/presentation/pages/stock_transaction_list_page.dart';
import 'package:stockmate/features/stock_transactions/presentation/providers/stock_transaction_provider.dart';

void main() {
  late StockTransactionProvider txProvider;
  late ProductProvider productProvider;
  late StockTransactionMockDataSource txDataSource;

  setUp(() {
    final prodRepo = ProductRepositoryImpl(ProductMockDataSource());
    productProvider = ProductProvider(
      getProducts: GetProducts(prodRepo),
      getFormOptions: GetProductFormOptions(prodRepo),
      getProduct: GetProduct(prodRepo),
      createProduct: CreateProduct(prodRepo),
      updateProduct: UpdateProduct(prodRepo),
      deleteProduct: DeleteProduct(prodRepo),
    );

    txDataSource = StockTransactionMockDataSource();
    final txRepo = StockTransactionRepositoryImpl(txDataSource);

    txProvider = StockTransactionProvider(
      getStockTransactions: GetStockTransactions(txRepo),
      getStockTransaction: GetStockTransaction(txRepo),
      createStockTransaction: CreateStockTransaction(txRepo),
      updateStockTransaction: UpdateStockTransaction(txRepo),
      deleteStockTransaction: DeleteStockTransaction(txRepo),
      onGetProduct: productProvider.getProductById,
      onUpdateProduct: productProvider.editProduct,
    );
  });

  Widget buildTestableWidget(Widget child) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<ProductProvider>.value(value: productProvider),
        ChangeNotifierProvider<StockTransactionProvider>.value(
          value: txProvider,
        ),
      ],
      child: MaterialApp(home: child),
    );
  }

  testWidgets(
    'StockTransactionListPage renders title, FAB, and transaction cards',
    (tester) async {
      await tester.pumpWidget(
        buildTestableWidget(const StockTransactionListPage()),
      );
      await tester.pumpAndSettle();

      expect(find.text('Manajemen Transaksi Stok'), findsOneWidget);
      expect(find.byKey(const Key('add_transaction_fab')), findsOneWidget);
      expect(find.text('Beras Premium'), findsWidgets);
      expect(find.text('Semua'), findsOneWidget);
      expect(find.text('Masuk'), findsWidgets);
      expect(find.text('Keluar'), findsWidgets);
    },
  );

  testWidgets(
    'StockTransactionDetailPage renders complete transaction information',
    (tester) async {
      await tester.pumpWidget(
        buildTestableWidget(
          const StockTransactionDetailPage(transactionId: 'tx-1'),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Detail Transaksi Stok'), findsOneWidget);
      expect(find.text('Beras Premium'), findsOneWidget);
      expect(find.text('Kode Barang: PRD-001'), findsOneWidget);
      expect(find.text('+30 Unit'), findsOneWidget);
      expect(find.text('Edit Transaksi'), findsOneWidget);
      expect(find.text('Hapus Transaksi'), findsOneWidget);
    },
  );
}
