import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:stockmate/features/products/data/datasources/product_remote_data_source.dart';
import 'package:stockmate/features/products/data/models/product_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

const _owner = '11111111-1111-4111-8111-111111111111';
const _id = '22222222-2222-4222-8222-222222222222';
const _category = '33333333-3333-4333-8333-333333333333';
const _supplier = '44444444-4444-4444-8444-444444444444';

Map<String, dynamic> _row({
  String id = _id,
  String? supplierId,
  int stock = 0,
}) => {
  'id': id,
  'owner_id': _owner,
  'code': 'PRD-001',
  'name': 'Rice',
  'price': 75000,
  'unit': 'bag',
  'category_id': _category,
  'supplier_id': supplierId,
  'minimum_stock': 10,
  'current_stock': stock,
};

ProductModel _product({int stock = 0, String? supplierId}) =>
    ProductModel.fromJson(
      _row(stock: stock, supplierId: supplierId),
      categoryName: 'Food',
    );

http.Response _json(Object body, [int status = 200]) => http.Response(
  jsonEncode(body),
  status,
  headers: {'content-type': 'application/json'},
);

// Match PostgREST's object/list responses rather than mocking SDK methods.
http.Response _rows(http.Request request, List<Map<String, dynamic>> rows) {
  if (request.headers['accept']?.contains('object+json') ?? false) {
    if (rows.length == 1) return _json(rows.single);
    return _json({
      'code': 'PGRST116',
      'message': 'Expected one row',
      'details': 'The result contains ${rows.length} rows',
      'hint': null,
    }, 406);
  }
  return _json(rows);
}

String _token(String owner) {
  String encode(Object value) =>
      base64Url.encode(utf8.encode(jsonEncode(value))).replaceAll('=', '');
  return '${encode({'alg': 'HS256', 'typ': 'JWT'})}.${encode({'sub': owner, 'role': 'authenticated', 'exp': DateTime.now().millisecondsSinceEpoch ~/ 1000 + 3600})}.test-signature';
}

void main() {
  late SupabaseClient client;
  late ProductRemoteDataSource source;
  late List<http.Request> requests;
  late FutureOr<http.Response> Function(http.Request) handler;

  Future<void> signIn([String owner = _owner]) async {
    await client.auth.signInWithPassword(
      email: '$owner@example.com',
      password: 'test-password',
    );
  }

  setUp(() async {
    requests = [];
    handler = (request) {
      final table = request.url.pathSegments.last;
      if (request.method != 'GET') {
        return _rows(request, [
          {'id': _id},
        ]);
      }
      if (table == 'categories') {
        return _rows(request, [
          {'id': _category, 'name': 'Food'},
        ]);
      }
      if (table == 'suppliers') {
        return _rows(request, [
          {'id': _supplier, 'name': 'Supplier'},
        ]);
      }
      return _rows(request, [_row()]);
    };
    client = SupabaseClient(
      'https://inventory.example.com',
      'test-anon-key',
      authOptions: const AuthClientOptions(autoRefreshToken: false),
      httpClient: MockClient((request) async {
        if (request.url.path.startsWith('/auth/')) {
          final owner = (jsonDecode(request.body)['email'] as String)
              .split('@')
              .first;
          return _json({
            'access_token': _token(owner),
            'refresh_token': 'test-refresh',
            'token_type': 'bearer',
            'expires_in': 3600,
            'user': {
              'id': owner,
              'aud': 'authenticated',
              'role': 'authenticated',
              'email': '$owner@example.com',
              'app_metadata': {},
              'user_metadata': {},
              'created_at': '2026-01-01T00:00:00Z',
            },
          });
        }
        requests.add(request);
        final response = await handler(request);
        return http.Response(
          response.body,
          response.statusCode,
          headers: response.headers,
          request: request,
        );
      }),
    );
    source = ProductRemoteDataSource(client);
    addTearDown(client.dispose);
    await signIn();
  });

  test(
    'moving products validates ownership and patches only category_id',
    () async {
      final missingId = '55555555-5555-4555-8555-555555555555';
      final moved = await source.changeCategory({_id, missingId}, _category);
      expect(moved, {_id});
      expect(requests, hasLength(2));
      expect(requests.first.url.pathSegments.last, 'categories');
      expect(requests.first.url.queryParameters['owner_id'], 'eq.$_owner');
      final patch = requests.last;
      expect(patch.method, 'PATCH');
      expect(patch.url.pathSegments.last, 'products');
      expect(patch.url.queryParameters['owner_id'], 'eq.$_owner');
      final ids = patch.url.queryParameters['id'];
      expect(ids, contains(_id));
      expect(ids, contains(missingId));
      expect(jsonDecode(patch.body), {'category_id': _category});
    },
  );

  test(
    'reads stock summary and tolerates a product without supplier',
    () async {
      final products = await source.getProducts();
      expect(products.single.unit, 'bag');
      expect(products.single.categoryName, 'Food');
      expect(products.single.supplierId, isNull);
      expect(products.single.supplierName, isNull);
      expect(
        requests.any((request) => request.url.path.endsWith('/suppliers')),
        isFalse,
      );
      for (final request in requests) {
        expect(request.url.queryParameters['owner_id'], 'eq.$_owner');
        expect(request.headers['authorization'], startsWith('Bearer '));
      }
    },
  );

  test('enriches supplier names and reads a single product', () async {
    final previous = handler;
    handler = (request) => request.url.path.endsWith('/product_stock_summary')
        ? _rows(request, [_row(supplierId: _supplier, stock: 7)])
        : previous(request);
    final product = await source.getProduct(_id);
    expect(product!.supplierName, 'Supplier');
    expect(product.currentStock, 7);
    expect(requests.first.url.queryParameters['id'], 'eq.$_id');
  });

  test('returns null for missing single product and skips lookups', () async {
    handler = (request) => _rows(request, []);
    expect(await source.getProduct(_id), isNull);
    expect(requests, hasLength(1));
  });

  test(
    'reads all inventory pages instead of truncating the first page',
    () async {
      final previous = handler;
      handler = (request) {
        if (!request.url.path.endsWith('/product_stock_summary')) {
          return previous(request);
        }
        final offset = int.parse(request.url.queryParameters['offset'] ?? '0');
        return _rows(
          request,
          offset == 0
              ? List.generate(200, (index) => _row(id: 'product-$index'))
              : [_row(id: 'last-product')],
        );
      };
      final products = await source.getProducts();
      expect(products, hasLength(201));
      final pages = requests
          .where(
            (request) => request.url.path.endsWith('/product_stock_summary'),
          )
          .toList();
      expect(pages, hasLength(2));
      expect(pages.last.url.queryParameters['offset'], '200');
    },
  );

  test('loads category and supplier options with real identifiers', () async {
    final options = await source.getFormOptions();
    expect(options.categories.single.id, _category);
    expect(options.suppliers.single.id, _supplier);
  });

  test(
    'insert sends only writable columns and explicit account ownership',
    () async {
      await source.createProduct(_product());
      final request = requests.singleWhere(
        (request) => request.method == 'POST',
      );
      final body = jsonDecode(request.body) as Map<String, dynamic>;
      expect(request.url.path, '/rest/v1/products');
      expect(body['owner_id'], _owner);
      expect(body['category_id'], _category);
      expect(body['supplier_id'], isNull);
      for (final column in [
        'id',
        'current_stock',
        'category_name',
        'supplier_name',
        'ownerId',
      ]) {
        expect(body.containsKey(column), isFalse);
      }
    },
  );

  test('rejects nonzero initial stock before making any request', () async {
    await expectLater(
      source.createProduct(_product(stock: 5)),
      throwsStateError,
    );
    expect(requests, isEmpty);
  });

  test(
    'rejects references unavailable to the current account before writing',
    () async {
      handler = (request) => _rows(request, []);
      await expectLater(source.createProduct(_product()), throwsStateError);
      expect(requests.any((request) => request.method == 'POST'), isFalse);
    },
  );

  test(
    'metadata update can clear supplier without writing calculated stock',
    () async {
      await source.updateProduct(_product());
      final request = requests.singleWhere(
        (request) => request.method == 'PATCH',
      );
      final body = jsonDecode(request.body) as Map<String, dynamic>;
      expect(body.containsKey('supplier_id'), isTrue);
      expect(body['supplier_id'], isNull);
      expect(body.containsKey('current_stock'), isFalse);
      expect(body.containsKey('owner_id'), isFalse);
      expect(request.url.queryParameters['owner_id'], 'eq.$_owner');
      expect(request.url.queryParameters['id'], 'eq.$_id');
    },
  );

  test(
    'changed stock rejects update instead of reporting a false stock sync',
    () async {
      await expectLater(
        source.updateProduct(_product(stock: 5)),
        throwsStateError,
      );
      expect(requests.any((request) => request.method == 'PATCH'), isFalse);
    },
  );

  test('zero-row update is not reported as success', () async {
    final previous = handler;
    handler = (request) =>
        request.method == 'PATCH' ? _rows(request, []) : previous(request);
    await expectLater(source.updateProduct(_product()), throwsStateError);
  });

  test(
    'deletion filters by product and account and verifies the result',
    () async {
      await source.deleteProduct(_id);
      expect(requests.single.method, 'DELETE');
      expect(requests.single.url.queryParameters['id'], 'eq.$_id');
      expect(requests.single.url.queryParameters['owner_id'], 'eq.$_owner');
    },
  );

  test('deletion with no accessible row fails', () async {
    handler = (request) => _rows(request, []);
    await expectLater(source.deleteProduct(_id), throwsStateError);
  });

  test('foreign key restrict error becomes a useful inventory error', () async {
    handler = (_) => _json({
      'code': '23503',
      'message': 'foreign key violation',
      'details': null,
      'hint': null,
    }, 409);
    await expectLater(
      source.deleteProduct(_id),
      throwsA(
        isA<StateError>().having(
          (error) => error.message,
          'message',
          contains('transaksi'),
        ),
      ),
    );
  });

  test('duplicate product code is reported clearly', () async {
    final previous = handler;
    handler = (request) => request.method == 'POST'
        ? _json({
            'code': '23505',
            'message': 'duplicate key',
            'details': null,
            'hint': null,
          }, 409)
        : previous(request);
    await expectLater(
      source.createProduct(_product()),
      throwsA(
        isA<StateError>().having(
          (error) => error.message,
          'message',
          contains('Kode produk'),
        ),
      ),
    );
  });

  test(
    'all operations reject a signed-out session without data requests',
    () async {
      final signedOut = SupabaseClient(
        'https://inventory.example.com',
        'test-key',
        authOptions: const AuthClientOptions(autoRefreshToken: false),
        httpClient: MockClient(
          (_) => throw StateError('Unexpected network request'),
        ),
      );
      addTearDown(signedOut.dispose);
      final dataSource = ProductRemoteDataSource(signedOut);
      for (final action in <Future<Object?> Function()>[
        dataSource.getProducts,
        () => dataSource.getProduct(_id),
        dataSource.getFormOptions,
        () => dataSource.createProduct(_product()),
        () => dataSource.updateProduct(_product()),
        () => dataSource.deleteProduct(_id),
      ]) {
        await expectLater(action(), throwsStateError);
      }
    },
  );

  test(
    'account change while a response is in flight discards that response',
    () async {
      final pending = Completer<http.Response>();
      handler = (_) => pending.future;
      final result = source.getProducts();
      final expectation = expectLater(result, throwsStateError);
      await signIn('55555555-5555-4555-8555-555555555555');
      pending.complete(_json([_row()]));
      await expectation;
    },
  );
}
