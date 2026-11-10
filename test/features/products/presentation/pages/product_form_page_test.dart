import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:stockmate/features/products/data/datasources/product_mock_data_source.dart';
import 'package:stockmate/features/products/data/repositories/product_repository_impl.dart';
import 'package:stockmate/features/products/domain/usecases/create_product.dart';
import 'package:stockmate/features/products/domain/usecases/delete_product.dart';
import 'package:stockmate/features/products/domain/usecases/get_product.dart';
import 'package:stockmate/features/products/domain/usecases/get_products.dart';
import 'package:stockmate/features/products/domain/usecases/update_product.dart';
import 'package:stockmate/features/products/presentation/pages/product_form_page.dart';
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

  Future<({GoRouter router, ProductProvider provider})> pumpForm(
    WidgetTester tester, {
    String? productId,
    Size size = const Size(390, 844),
  }) async {
    await tester.binding.setSurfaceSize(size);
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final provider = createProvider();
    final formPath = productId == null ? '/form' : '/form/$productId';
    final router = GoRouter(
      initialLocation: formPath,
      routes: [
        GoRoute(
          path: '/',
          builder: (_, _) => const Scaffold(body: Text('Form completed')),
        ),
        GoRoute(path: '/form', builder: (_, _) => const ProductFormPage()),
        GoRoute(
          path: '/form/:id',
          builder: (_, state) =>
              ProductFormPage(productId: state.pathParameters['id']),
        ),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: provider,
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    return (router: router, provider: provider);
  }

  Future<void> enterText(WidgetTester tester, Key key, String value) async {
    final finder = find.byKey(key);
    await tester.ensureVisible(finder);
    await tester.enterText(finder, value);
  }

  Future<void> tapSubmit(WidgetTester tester) async {
    FocusManager.instance.primaryFocus?.unfocus();
    tester.testTextInput.hide();
    await tester.pump();

    final submit = find.byKey(const Key('product_submit'));
    await tester.ensureVisible(submit);
    await tester.pump();
    await tester.drag(
      find.byType(SingleChildScrollView),
      const Offset(0, -100),
    );
    await tester.pump();
    await tester.tap(submit);
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
  }

  testWidgets('creates a product with valid form values', (tester) async {
    final setup = await pumpForm(tester);

    await enterText(tester, const Key('product_code'), 'PRD-004');
    await enterText(tester, const Key('product_name'), 'Brown Sugar');
    await enterText(tester, const Key('product_category'), 'Food');
    await enterText(tester, const Key('product_unit'), 'pack');
    await enterText(tester, const Key('product_price'), '15000');
    await enterText(tester, const Key('product_current_stock'), '20');
    await enterText(tester, const Key('product_minimum_stock'), '5');
    await enterText(tester, const Key('product_supplier'), 'Sweet Supply');

    await tapSubmit(tester);

    expect(setup.provider.products, hasLength(4));
    expect(setup.provider.products.last.name, 'Brown Sugar');
  });

  testWidgets('loads and updates an existing product', (tester) async {
    final setup = await pumpForm(
      tester,
      productId: '1',
      size: const Size(1280, 800),
    );

    expect(find.text('Edit product'), findsOneWidget);
    expect(find.widgetWithText(TextFormField, 'Beras Premium'), findsOneWidget);

    await enterText(tester, const Key('product_name'), 'Beras Organik');
    await tapSubmit(tester);

    final updated = setup.provider.products.firstWhere(
      (product) => product.id == '1',
    );
    expect(updated.name, 'Beras Organik');
  });

  testWidgets('validates required fields before creating a product', (
    tester,
  ) async {
    await pumpForm(tester);

    await tapSubmit(tester);

    expect(find.text('Product code is required.'), findsOneWidget);
    expect(find.text('Product name is required.'), findsOneWidget);
    expect(find.text('Price is required.'), findsOneWidget);
  });
}
