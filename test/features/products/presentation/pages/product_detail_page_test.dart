import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:stockmate/features/products/data/datasources/product_mock_data_source.dart';
import 'package:stockmate/features/products/data/repositories/product_repository_impl.dart';
import 'package:stockmate/features/products/domain/usecases/create_product.dart';
import 'package:stockmate/features/products/domain/usecases/delete_product.dart';
import 'package:stockmate/features/products/domain/usecases/get_product.dart';
import 'package:stockmate/features/products/domain/usecases/get_products.dart';
import 'package:stockmate/features/products/domain/usecases/update_product.dart';
import 'package:stockmate/features/products/presentation/pages/product_detail_page.dart';
import 'package:stockmate/features/products/presentation/providers/product_provider.dart';

void main() {
  ProductProvider createProvider() {
    final repository = ProductRepositoryImpl(ProductMockDataSource());
    return ProductProvider(
      getProducts: GetProducts(repository),
      getProduct: GetProduct(repository),
      createProduct: CreateProduct(repository),
      updateProduct: UpdateProduct(repository),
      deleteProduct: DeleteProduct(repository),
    );
  }

  Future<void> pumpPage(
    WidgetTester tester, {
    required String productId,
    required Size size,
  }) async {
    await tester.binding.setSurfaceSize(size);
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => createProvider(),
        child: MaterialApp(home: ProductDetailPage(productId: productId)),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('shows a low-stock product on a mobile viewport', (tester) async {
    await pumpPage(tester, productId: '2', size: const Size(390, 844));

    expect(find.text('Product details'), findsOneWidget);
    expect(find.text('Mineral Water 600ml'), findsOneWidget);
    expect(find.text('Rp 5.000'), findsOneWidget);
    expect(find.text('Product information'), findsOneWidget);
    expect(find.text('Stock overview'), findsOneWidget);
    expect(
      find.text('Stock is at or below the minimum level.'),
      findsOneWidget,
    );
  });

  testWidgets('shows not-found state for an unknown product', (tester) async {
    await pumpPage(tester, productId: 'missing', size: const Size(1280, 800));

    expect(find.text('Product not found'), findsOneWidget);
    expect(find.text('Refresh'), findsOneWidget);
  });
}
