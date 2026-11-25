import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';
import 'package:stockmate/app/providers/theme_provider.dart';
import 'package:stockmate/features/auth/data/datasources/auth_remote_data_source.dart';
import 'package:stockmate/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:stockmate/features/auth/domain/repositories/auth_repository.dart';
import 'package:stockmate/features/auth/domain/usecases/get_current_user.dart';
import 'package:stockmate/features/auth/domain/usecases/sign_in.dart';
import 'package:stockmate/features/auth/domain/usecases/sign_out.dart';
import 'package:stockmate/features/auth/domain/usecases/sign_up.dart';
import 'package:stockmate/features/auth/domain/usecases/watch_auth_state.dart';
import 'package:stockmate/features/auth/presentation/providers/auth_provider.dart';
import 'package:stockmate/features/products/data/datasources/product_remote_data_source.dart';
import 'package:stockmate/features/products/data/repositories/product_repository_impl.dart';
import 'package:stockmate/features/products/domain/repositories/product_repository.dart';
import 'package:stockmate/features/products/domain/usecases/create_product.dart';
import 'package:stockmate/features/products/domain/usecases/delete_product.dart';
import 'package:stockmate/features/products/domain/usecases/get_product.dart';
import 'package:stockmate/features/products/domain/usecases/get_product_form_options.dart';
import 'package:stockmate/features/products/domain/usecases/get_products.dart';
import 'package:stockmate/features/products/domain/usecases/update_product.dart';
import 'package:stockmate/features/products/presentation/providers/product_provider.dart';
import 'package:stockmate/features/stock_transactions/data/datasources/stock_transaction_data_source.dart';
import 'package:stockmate/features/stock_transactions/data/datasources/stock_transaction_mock_data_source.dart';
import 'package:stockmate/features/stock_transactions/data/datasources/stock_transaction_remote_data_source.dart';
import 'package:stockmate/features/stock_transactions/data/repositories/stock_transaction_repository_impl.dart';
import 'package:stockmate/features/stock_transactions/domain/repositories/stock_transaction_repository.dart';
import 'package:stockmate/features/stock_transactions/domain/usecases/create_stock_transaction.dart';
import 'package:stockmate/features/stock_transactions/domain/usecases/delete_stock_transaction.dart';
import 'package:stockmate/features/stock_transactions/domain/usecases/get_stock_transaction.dart';
import 'package:stockmate/features/stock_transactions/domain/usecases/get_stock_transactions.dart';
import 'package:stockmate/features/stock_transactions/domain/usecases/update_stock_transaction.dart';
import 'package:stockmate/features/stock_transactions/presentation/providers/stock_transaction_provider.dart';
import 'package:stockmate/features/suppliers/data/datasources/suppliers_remote_data_source.dart';
import 'package:stockmate/features/suppliers/data/repositories/suppliers_repository_impl.dart';
import 'package:stockmate/features/suppliers/domain/repositories/suppliers_repository.dart';
import 'package:stockmate/features/suppliers/domain/usecases/supplier_usecases.dart';
import 'package:stockmate/features/suppliers/presentation/providers/suppliers_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AppProviders extends StatelessWidget {
  const AppProviders({
    required this.child,
    this.authRepository,
    this.productRepository,
    this.suppliersRepository,
    this.stockTransactionRepository,
    this.stockTransactionProvider,
    super.key,
  });

  final Widget child;
  final AuthRepository? authRepository;
  final ProductRepository? productRepository;
  final SuppliersRepository? suppliersRepository;
  final StockTransactionRepository? stockTransactionRepository;
  final StockTransactionProvider? stockTransactionProvider;

  static StockTransactionDataSource _createStockDataSource(
    bool usesRemoteProducts,
  ) {
    if (!usesRemoteProducts) {
      return StockTransactionMockDataSource();
    }
    try {
      return StockTransactionRemoteDataSource(Supabase.instance.client);
    } on Object catch (_) {
      return StockTransactionMockDataSource();
    }
  }

  @override
  Widget build(BuildContext context) {
    final usesRemoteProducts =
        productRepository == null ||
        (productRepository is ProductRepositoryImpl &&
            (productRepository as ProductRepositoryImpl).dataSource
                is ProductRemoteDataSource);

    final resolvedStockRepo =
        stockTransactionRepository ??
        StockTransactionRepositoryImpl(
          _createStockDataSource(usesRemoteProducts),
        );

    final isMockStockWithRemoteProducts =
        usesRemoteProducts &&
        resolvedStockRepo is StockTransactionRepositoryImpl &&
        resolvedStockRepo.dataSource is StockTransactionMockDataSource;

    Future<Never> blockMockStockMutation(String _) async {
      throw StateError(
        'Transaksi stok belum tersedia untuk inventori akun ini.',
      );
    }

    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        Provider<AuthRepository>(
          create: (_) {
            return authRepository ??
                AuthRepositoryImpl(
                  AuthRemoteDataSource(Supabase.instance.client),
                );
          },
        ),
        ChangeNotifierProvider(
          create: (context) {
            final repository = context.read<AuthRepository>();
            return AuthProvider(
              getCurrentUser: GetCurrentUser(repository),
              watchAuthState: WatchAuthState(repository),
              signIn: SignIn(repository),
              signUp: SignUp(repository),
              signOut: SignOut(repository),
            );
          },
        ),
        Provider<ProductRepository>(
          create: (_) =>
              productRepository ??
              ProductRepositoryImpl(
                ProductRemoteDataSource(Supabase.instance.client),
              ),
        ),
        ChangeNotifierProxyProvider<AuthProvider, ProductProvider>(
          create: _createProductProvider,
          update: (context, auth, previous) =>
              (previous ?? _createProductProvider(context))
                ..setOwner(auth.user?.id),
        ),
        Provider<SuppliersRepository>(
          create: (_) =>
              suppliersRepository ??
              SuppliersRepositoryImpl(
                dataSource: SuppliersRemoteDataSource(Supabase.instance.client),
              ),
        ),
        ChangeNotifierProxyProvider<AuthProvider, SuppliersProvider>(
          create: _createSuppliersProvider,
          update: (context, auth, previous) =>
              (previous ?? _createSuppliersProvider(context))
                ..setOwner(auth.user?.id),
        ),
        Provider<StockTransactionRepository>.value(
          value: resolvedStockRepo,
        ),
        ChangeNotifierProxyProvider2<
          AuthProvider,
          ProductProvider,
          StockTransactionProvider
        >(
          create: (context) {
            if (stockTransactionProvider != null) {
              return stockTransactionProvider!;
            }
            final repo = context.read<StockTransactionRepository>();
            final productProvider = context.read<ProductProvider>();
            return StockTransactionProvider(
              getStockTransactions: GetStockTransactions(repo),
              getStockTransaction: GetStockTransaction(repo),
              createStockTransaction: CreateStockTransaction(repo),
              updateStockTransaction: UpdateStockTransaction(repo),
              deleteStockTransaction: DeleteStockTransaction(repo),
              onGetProduct: isMockStockWithRemoteProducts
                  ? blockMockStockMutation
                  : productProvider.getProductById,
              onUpdateProduct: usesRemoteProducts
                  ? null
                  : productProvider.editProduct,
              onRefreshProducts: productProvider.fetchProducts,
            );
          },
          update: (context, auth, productProvider, currentStockTxProvider) {
            if (currentStockTxProvider != null) {
              currentStockTxProvider.onGetProduct =
                  isMockStockWithRemoteProducts
                      ? blockMockStockMutation
                      : productProvider.getProductById;
              currentStockTxProvider.onUpdateProduct = usesRemoteProducts
                  ? null
                  : productProvider.editProduct;
              currentStockTxProvider.onRefreshProducts =
                  productProvider.fetchProducts;
              currentStockTxProvider.setOwner(auth.user?.id);
            }
            return currentStockTxProvider!;
          },
        ),
      ],
      child: child,
    );
  }

  ProductProvider _createProductProvider(BuildContext context) {
    final repository = context.read<ProductRepository>();
    return ProductProvider(
      getProducts: GetProducts(repository),
      getProduct: GetProduct(repository),
      getFormOptions: GetProductFormOptions(repository),
      createProduct: CreateProduct(repository),
      updateProduct: UpdateProduct(repository),
      deleteProduct: DeleteProduct(repository),
    );
  }

  SuppliersProvider _createSuppliersProvider(BuildContext context) {
    final repository = context.read<SuppliersRepository>();
    return SuppliersProvider(
      getSuppliers: GetSuppliers(repository),
      addSupplier: AddSupplier(repository),
      updateSupplier: UpdateSupplier(repository),
      deleteSupplier: DeleteSupplier(repository),
    );
  }
}
