import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/testing.dart';
import 'package:provider/provider.dart';
import 'package:stockmate/app/providers/app_providers.dart';
import 'package:stockmate/features/auth/domain/entities/auth_user.dart';
import 'package:stockmate/features/products/data/datasources/product_remote_data_source.dart';
import 'package:stockmate/features/products/data/repositories/product_repository_impl.dart';
import 'package:stockmate/features/stock_transactions/domain/entities/stock_transaction.dart';
import 'package:stockmate/features/stock_transactions/domain/entities/transaction_type.dart';
import 'package:stockmate/features/stock_transactions/presentation/providers/stock_transaction_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart'
    show SupabaseClient, AuthClientOptions;

import '../../helpers/fake_auth_repository.dart';

void main() {
  late FakeAuthRepository auth;
  late SupabaseClient client;

  setUp(() {
    auth = FakeAuthRepository(
      currentUser: const AuthUser(id: 'account-a', email: 'a@example.com'),
    );
    client = SupabaseClient(
      'https://inventory.example.com',
      'test-key',
      authOptions: const AuthClientOptions(autoRefreshToken: false),
      httpClient: MockClient(
        (_) => throw StateError('Unexpected HTTP request'),
      ),
    );
    addTearDown(auth.dispose);
    addTearDown(client.dispose);
  });

  testWidgets(
    'mock stock mutations cannot claim to synchronize live products',
    (tester) async {
      late StockTransactionProvider stock;
      await tester.pumpWidget(
        AppProviders(
          authRepository: auth,
          productRepository: ProductRepositoryImpl(
            ProductRemoteDataSource(client),
          ),
          child: Builder(
            builder: (context) {
              stock = context.read<StockTransactionProvider>();
              return const SizedBox();
            },
          ),
        ),
      );
      await tester.pump();
      final success = await stock.addTransaction(
        StockTransaction(
          id: 'new-tx',
          productId: 'real-product',
          productName: 'Rice',
          productCode: 'PRD-001',
          type: TransactionType.inStock,
          quantity: 5,
          date: DateTime(2026, 11, 18),
          createdAt: DateTime(2026, 11, 18),
        ),
      );
      expect(success, isFalse);
      expect(stock.errorMessage, contains('belum tersedia'));
      expect(stock.transactions, isEmpty);
    },
    timeout: const Timeout(Duration(seconds: 15)),
  );
}
