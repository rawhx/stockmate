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
import 'package:stockmate/features/products/presentation/pages/product_list_page.dart';
import 'package:stockmate/features/products/presentation/providers/product_provider.dart';
import 'package:stockmate/features/products/presentation/widgets/product_card.dart';

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

  Future<void> pumpPage(WidgetTester tester, Size size) async {
    await tester.binding.setSurfaceSize(size);
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => createProvider(),
        child: const MaterialApp(home: ProductListPage(showAppActions: false)),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('shows product inventory on a mobile viewport', (tester) async {
    await pumpPage(tester, const Size(390, 844));

    expect(find.text('Products'), findsOneWidget);
    expect(find.text('3 items'), findsOneWidget);
    expect(find.byType(ProductCard), findsWidgets);
    expect(find.text('Beras Premium'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('filters products by search on a desktop viewport', (
    tester,
  ) async {
    await pumpPage(tester, const Size(1280, 800));

    await tester.enterText(find.byKey(const Key('product_search')), 'water');
    await tester.pump();

    expect(find.text('1 item'), findsOneWidget);
    expect(find.text('Mineral Water 600ml'), findsOneWidget);
    expect(find.text('Beras Premium'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
