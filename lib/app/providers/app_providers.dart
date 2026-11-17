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
import 'package:stockmate/features/stock_transactions/presentation/providers/stock_transaction_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AppProviders extends StatelessWidget {
  const AppProviders({
    required this.child,
    this.authRepository,
    this.stockTransactionProvider,
    super.key,
  });

  final Widget child;
  final AuthRepository? authRepository;
  final StockTransactionProvider? stockTransactionProvider;

  @override
  Widget build(BuildContext context) {
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
        ChangeNotifierProvider(
          create: (_) {
            final repository = ProductRepositoryImpl(ProductMockDataSource());
            return ProductProvider(
              getProducts: GetProducts(repository),
              getProduct: GetProduct(repository),
              getFormOptions: GetProductFormOptions(repository),
              createProduct: CreateProduct(repository),
              updateProduct: UpdateProduct(repository),
              deleteProduct: DeleteProduct(repository),
            );
          },
        ),
        ChangeNotifierProxyProvider<ProductProvider, StockTransactionProvider>(
          create: (context) {
            if (stockTransactionProvider != null) {
              return stockTransactionProvider!;
            }
            final ds = StockTransactionMockDataSource();
            final repo = StockTransactionRepositoryImpl(ds);
            final productProvider = context.read<ProductProvider>();
            return StockTransactionProvider(
              getStockTransactions: GetStockTransactions(repo),
              getStockTransaction: GetStockTransaction(repo),
              createStockTransaction: CreateStockTransaction(repo),
              updateStockTransaction: UpdateStockTransaction(repo),
              deleteStockTransaction: DeleteStockTransaction(repo),
              onGetProduct: productProvider.getProductById,
              onUpdateProduct: productProvider.editProduct,
            );
          },
          update: (context, productProvider, currentStockTxProvider) {
            if (currentStockTxProvider != null) {
              currentStockTxProvider.onGetProduct =
                  productProvider.getProductById;
              currentStockTxProvider.onUpdateProduct =
                  productProvider.editProduct;
            }
            return currentStockTxProvider!;
          },
        ),
      ],
      child: child,
    );
  }
}
