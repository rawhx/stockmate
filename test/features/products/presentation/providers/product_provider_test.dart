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

  test('write failure is surfaced and not reported as success', () async {
    repository.create = (_) async =>
        throw StateError('Product code already exists');
    expect(await provider.addProduct(_product), isFalse);
    expect(provider.errorMessage, 'Product code already exists');
    expect(provider.isSaving, isFalse);
  });

  test(
    'refresh error after successful save does not invite duplicate creation',
    () async {
      var saves = 0;
      repository.create = (_) async {
        saves++;
      };
      repository.fetch = () async => throw StateError('Refresh failed');
      expect(await provider.addProduct(_product), isTrue);
      expect(saves, 1);
      expect(provider.errorMessage, 'Refresh failed');
      expect(provider.isSaving, isFalse);
    },
  );

  test('simultaneous save attempts perform only one write', () async {
    final pending = Completer<void>();
    var saves = 0;
    repository.create = (_) {
      saves++;
      return pending.future;
    };
    final first = provider.addProduct(_product);
    expect(await provider.addProduct(_product), isFalse);
    pending.complete();
    expect(await first, isTrue);
    expect(saves, 1);
  });

  test('save refreshes again after a previously pending read', () async {
    final pending = Completer<List<Product>>();
    var reads = 0;
    repository.fetch = () => ++reads == 1
        ? pending.future
        : Future.value([_product.copyWith(name: 'Saved product')]);
    final oldRead = provider.fetchProducts();
    final save = provider.addProduct(_product);
    pending.complete([_product]);
    await oldRead;
    expect(await save, isTrue);
    expect(reads, 2);
    expect(provider.products.single.name, 'Saved product');
  });

  test(
    'old-account deletion completion cannot modify new-account inventory',
    () async {
      final pending = Completer<void>();
      repository.remove = (_) => pending.future;
      provider.setOwner('a');
      final removal = provider.removeProduct('1');
      provider.setOwner('b');
      await provider.fetchProducts();
      pending.complete();
      expect(await removal, isFalse);
      expect(provider.products.single.id, '1');
    },
  );

  test('failed delete keeps cached product available', () async {
    await provider.fetchProducts();
    repository.remove = (_) async =>
        throw StateError('Product has transactions');
    expect(await provider.removeProduct('1'), isFalse);
    expect(provider.products, hasLength(1));
    expect(provider.errorMessage, 'Product has transactions');
  });

  test(
    'successful delete removes cached product even if refresh fails',
    () async {
      await provider.fetchProducts();
      repository.fetch = () async => throw StateError('Refresh failed');
      expect(await provider.removeProduct('1'), isTrue);
      expect(provider.products, isEmpty);
      expect(provider.errorMessage, 'Refresh failed');
    },
  );
}
