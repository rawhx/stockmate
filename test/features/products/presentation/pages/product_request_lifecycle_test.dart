import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:stockmate/features/products/data/datasources/product_mock_data_source.dart';
import 'package:stockmate/features/products/data/models/product_model.dart';
import 'package:stockmate/features/products/data/repositories/product_repository_impl.dart';
import 'package:stockmate/features/products/domain/entities/product_form_options.dart';
import 'package:stockmate/features/products/domain/usecases/create_product.dart';
import 'package:stockmate/features/products/domain/usecases/delete_product.dart';
import 'package:stockmate/features/products/domain/usecases/get_product.dart';
import 'package:stockmate/features/products/domain/usecases/get_product_form_options.dart';
import 'package:stockmate/features/products/domain/usecases/get_products.dart';
import 'package:stockmate/features/products/domain/usecases/update_product.dart';
import 'package:stockmate/features/products/presentation/pages/product_detail_page.dart';
import 'package:stockmate/features/products/presentation/pages/product_form_page.dart';
import 'package:stockmate/features/products/presentation/providers/product_provider.dart';

const _first = ProductModel(
  id: 'first',
  code: 'PRD-001',
  name: 'First product',
  price: 1000,
  unit: 'bag',
  categoryId: 'cat-1',
  categoryName: 'Food',
  supplierId: 'sup-1',
  supplierName: 'Supplier',
  minimumStock: 2,
  currentStock: 10,
);
const _second = ProductModel(
  id: 'second',
  code: 'PRD-002',
  name: 'Second product',
  price: 2000,
  unit: 'bottle',
  categoryId: 'cat-1',
  categoryName: 'Food',
  minimumStock: 0,
  currentStock: 5,
);

class _Source extends ProductMockDataSource {
  final details = <String, Completer<ProductModel?>>{};
  final options = <Completer<ProductFormOptions>>[];
  Completer<void>? pendingUpdate;

  @override
  Future<List<ProductModel>> getProducts() async => [_first, _second];

  @override
  Future<ProductModel?> getProduct(String id) =>
      (details[id] ??= Completer<ProductModel?>()).future;

  @override
  Future<ProductFormOptions> getFormOptions() {
    final request = Completer<ProductFormOptions>();
    options.add(request);
    return request.future;
  }

  @override
  Future<void> updateProduct(ProductModel product) async {
    if (pendingUpdate != null) await pendingUpdate!.future;
  }
}

const _options = ProductFormOptions(
  categories: [ProductOption(id: 'cat-1', name: 'Food')],
  suppliers: [ProductOption(id: 'sup-1', name: 'Supplier')],
);

void main() {
  late _Source source;
  late ProductProvider provider;

  setUp(() {
    source = _Source();
    final repository = ProductRepositoryImpl(source);
    provider = ProductProvider(
      getProducts: GetProducts(repository),
      getProduct: GetProduct(repository),
      getFormOptions: GetProductFormOptions(repository),
      createProduct: CreateProduct(repository),
      updateProduct: UpdateProduct(repository),
      deleteProduct: DeleteProduct(repository),
    );
  });

  tearDown(() => provider.dispose());

  Future<void> show(WidgetTester tester, Widget page) async {
    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: provider,
        child: MaterialApp(home: page),
      ),
    );
    await tester.pump();
  }

  String fieldText(WidgetTester tester, String key) =>
      tester.widget<TextFormField>(find.byKey(Key(key))).controller!.text;

  for (final failOldRequest in [false, true]) {
    testWidgets(
      'late detail response cannot replace current product (error: $failOldRequest)',
      (tester) async {
        await show(tester, const ProductDetailPage(productId: 'first'));
        await show(tester, const ProductDetailPage(productId: 'second'));
        source.details['second']!.complete(_second);
        await tester.pumpAndSettle();
        if (failOldRequest) {
          source.details['first']!.completeError(
            StateError('Old request failed'),
          );
        } else {
          source.details['first']!.complete(_first);
        }
        await tester.pumpAndSettle();
        expect(find.text('Second product'), findsOneWidget);
        expect(find.text('First product'), findsNothing);
        expect(
          find.text('The product could not be loaded. Please try again.'),
          findsNothing,
        );
      },
    );
  }

  testWidgets(
    'switching detail clears previous product until next load finishes',
    (tester) async {
      await show(tester, const ProductDetailPage(productId: 'first'));
      source.details['first']!.complete(_first);
      await tester.pumpAndSettle();
      await show(tester, const ProductDetailPage(productId: 'second'));
      expect(find.text('First product'), findsNothing);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      source.details['second']!.complete(_second);
      await tester.pumpAndSettle();
      expect(find.text('Second product'), findsOneWidget);
    },
  );

  testWidgets('late form response cannot overwrite the current edit form', (
    tester,
  ) async {
    await show(tester, const ProductFormPage(productId: 'first'));
    await show(tester, const ProductFormPage(productId: 'second'));
    source.options[1].complete(_options);
    source.details['second']!.complete(_second);
    await tester.pumpAndSettle();
    source.options[0].complete(_options);
    source.details['first']!.complete(_first);
    await tester.pumpAndSettle();
    expect(fieldText(tester, 'product_name'), 'Second product');
    expect(fieldText(tester, 'product_code'), 'PRD-002');
  });

  testWidgets('late create options do not finish loading an edit form', (
    tester,
  ) async {
    await show(tester, const ProductFormPage());
    await show(tester, const ProductFormPage(productId: 'first'));
    source.options[0].complete(_options);
    await tester.pump();
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    source.options[1].complete(_options);
    source.details['first']!.complete(_first);
    await tester.pumpAndSettle();
    expect(fieldText(tester, 'product_name'), 'First product');
    expect(tester.takeException(), isNull);
  });

  testWidgets('switching from editing to creating resets metadata and stock', (
    tester,
  ) async {
    await show(tester, const ProductFormPage(productId: 'first'));
    source.options[0].complete(_options);
    source.details['first']!.complete(_first);
    await tester.pumpAndSettle();
    await show(tester, const ProductFormPage());
    source.options[1].complete(_options);
    await tester.pumpAndSettle();
    for (final key in [
      'product_code',
      'product_name',
      'product_price',
      'product_unit',
    ]) {
      expect(fieldText(tester, key), isEmpty);
    }
    expect(fieldText(tester, 'product_current_stock'), '0');
    expect(fieldText(tester, 'product_minimum_stock'), '0');
    final category = tester.state<FormFieldState<String>>(
      find.byKey(const Key('product_category')),
    );
    final supplier = tester.state<FormFieldState<String>>(
      find.byKey(const Key('product_supplier')),
    );
    expect(category.value, isNull);
    expect(supplier.value, '');
  });

  testWidgets('saving an old form cannot navigate away from the new form', (
    tester,
  ) async {
    await show(tester, const ProductFormPage(productId: 'first'));
    source.options[0].complete(_options);
    source.details['first']!.complete(_first);
    await tester.pumpAndSettle();
    source.pendingUpdate = Completer<void>();
    final submit = find.byKey(const Key('product_submit'));
    await tester.ensureVisible(submit);
    await tester.pumpAndSettle();
    await tester.tap(submit);
    await tester.pump();
    expect(provider.isSaving, isTrue);
    await show(tester, const ProductFormPage(productId: 'second'));
    source.options[1].complete(_options);
    source.details['second']!.complete(_second);
    await tester.pumpAndSettle();
    source.pendingUpdate!.complete();
    await tester.pumpAndSettle();
    expect(fieldText(tester, 'product_name'), 'Second product');
    expect(tester.takeException(), isNull);
  });
}
