import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:stockmate/features/products/data/datasources/product_mock_data_source.dart';
import 'package:stockmate/features/products/data/repositories/product_repository_impl.dart';
import 'package:stockmate/features/products/domain/entities/product.dart';
import 'package:stockmate/features/products/domain/usecases/create_product.dart';
import 'package:stockmate/features/products/domain/usecases/delete_product.dart';
import 'package:stockmate/features/products/domain/usecases/get_product.dart';
import 'package:stockmate/features/products/domain/usecases/get_product_form_options.dart';
import 'package:stockmate/features/products/domain/usecases/get_products.dart';
import 'package:stockmate/features/products/domain/usecases/update_product.dart';
import 'package:stockmate/features/products/presentation/providers/product_provider.dart';

const _product = Product(
  id: '1',
  code: 'PRD-001',
  name: 'Rice',
  price: 10,
  unit: 'bag',
  categoryId: 'cat-1',
  categoryName: 'Food',
  minimumStock: 0,
  currentStock: 0,
);

class _Repository extends ProductRepositoryImpl {
  _Repository() : super(ProductMockDataSource());

  Future<List<Product>> Function() fetch = () async => [_product];
  Future<void> Function(Product) create = (_) async {};
  Future<void> Function(String) remove = (_) async {};
  Future<Product?> Function(String) detail = (_) async => _product;

  @override
  Future<List<Product>> getProducts() => fetch();
  @override
  Future<Product?> getProduct(String id) => detail(id);
  @override
  Future<void> createProduct(Product product) => create(product);
  @override
  Future<void> deleteProduct(String id) => remove(id);
}

void main() {
  late _Repository repository;
  late ProductProvider provider;

  setUp(() {
    repository = _Repository();
    provider = ProductProvider(
      getProducts: GetProducts(repository),
      getProduct: GetProduct(repository),
      getFormOptions: GetProductFormOptions(repository),
      createProduct: CreateProduct(repository),
      updateProduct: UpdateProduct(repository),
      deleteProduct: DeleteProduct(repository),
    );
    addTearDown(provider.dispose);
  });

  test('account switch immediately clears visible data', () async {
    provider.setOwner('account-a');
    await provider.fetchProducts();
    expect(provider.products, hasLength(1));
    provider.setOwner('account-b');
    expect(provider.products, isEmpty);
    expect(provider.errorMessage, isNull);
    expect(provider.isLoading, isFalse);
  });

  test(
    'response for previous account cannot replace current inventory',
    () async {
      final pending = Completer<List<Product>>();
      provider.setOwner('account-a');
      repository.fetch = () => pending.future;
      final oldRequest = provider.fetchProducts();
      provider.setOwner('account-b');
      repository.fetch = () async => [
        _product.copyWith(id: 'b', name: 'Account B'),
      ];
      await provider.fetchProducts();
      pending.complete([_product]);
      await oldRequest;
      expect(provider.products.single.name, 'Account B');
    },
  );

  test('detail response from previous account is discarded', () async {
    final pending = Completer<Product?>();
    repository.detail = (_) => pending.future;
    provider.setOwner('a');
    final request = provider.getProductById('1');
    provider.setOwner('b');
    pending.complete(_product);
    expect(await request, isNull);
  });
}
