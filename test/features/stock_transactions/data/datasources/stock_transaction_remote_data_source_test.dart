import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:stockmate/features/stock_transactions/data/datasources/stock_transaction_remote_data_source.dart';
import 'package:stockmate/features/stock_transactions/data/models/stock_transaction_model.dart';
import 'package:stockmate/features/stock_transactions/domain/entities/transaction_type.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

const _owner = '11111111-1111-4111-8111-111111111111';
const _txId = '22222222-2222-4222-8222-222222222222';
const _productId = '33333333-3333-4333-8333-333333333333';

Map<String, dynamic> _row({
  String id = _txId,
  String type = 'IN',
  int quantity = 10,
}) => {
  'id': id,
  'owner_id': _owner,
  'product_id': _productId,
  'type': type,
  'quantity': quantity,
  'date': '2026-11-25T10:00:00.000Z',
  'notes': 'Stok masuk dari supplier',
  'created_at': '2026-11-25T10:00:00.000Z',
  'products': {
    'name': 'Beras Premium',
    'code': 'PRD-001',
  },
};

http.Response _json(Object body, [int status = 200]) => http.Response(
  jsonEncode(body),
  status,
  headers: {'content-type': 'application/json'},
);

http.Response _rows(http.Request request, List<Map<String, dynamic>> rows) {
  if (request.headers['accept']?.contains('object+json') ?? false) {
    if (rows.length == 1) return _json(rows.single);
    if (rows.isEmpty) {
      return _json({
        'code': 'PGRST116',
        'message': 'JSON object requested, multiple (or no) rows returned',
        'details': 'The result contains 0 rows',
      }, 406);
    }
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
  late StockTransactionRemoteDataSource source;
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
      if (request.method == 'GET') {
        return _rows(request, [_row()]);
      }
      if (request.method == 'POST') {
        final body = jsonDecode(request.body) as Map<String, dynamic>;
        return _rows(request, [
          {
            ..._row(),
            ...body,
            'id': _txId,
          },
        ]);
      }
      if (request.method == 'PATCH') {
        final body = jsonDecode(request.body) as Map<String, dynamic>;
        return _rows(request, [
          {
            ..._row(),
            ...body,
          },
        ]);
      }
      if (request.method == 'DELETE') {
        return _rows(request, []);
      }
      return _rows(request, [_row()]);
    };

    client = SupabaseClient(
      'https://inventory.example.com',
      'test-key',
      authOptions: const AuthClientOptions(autoRefreshToken: false),
      httpClient: MockClient((request) async {
        if (request.url.path.startsWith('/auth/')) {
          if (request.url.path.endsWith('/logout')) {
            return http.Response(
              '{}',
              200,
              headers: {'content-type': 'application/json'},
              request: request,
            );
          }
          final bodyMap = request.body.isNotEmpty
              ? jsonDecode(request.body) as Map<String, dynamic>
              : null;
          final email = (bodyMap?['email'] as String?) ?? 'owner@example.com';
          final owner = email.split('@').first;
          return http.Response(
            jsonEncode({
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
            }),
            200,
            headers: {'content-type': 'application/json'},
            request: request,
          );
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
    addTearDown(client.dispose);

    source = StockTransactionRemoteDataSource(client);
    await signIn();
  });

  test('getTransactions queries stock_transactions with owner filter and joins products', () async {
    final list = await source.getTransactions();

    expect(list.length, 1);
    expect(list.first.id, _txId);
    expect(list.first.productName, 'Beras Premium');
    expect(list.first.productCode, 'PRD-001');
    expect(list.first.quantity, 10);
    expect(list.first.type, TransactionType.inStock);

    final req = requests.firstWhere((r) => r.method == 'GET');
    expect(req.url.pathSegments, contains('stock_transactions'));
    expect(req.url.queryParameters['owner_id'], 'eq.$_owner');
  });

  test('getTransaction fetches single transaction by id', () async {
    final tx = await source.getTransaction(_txId);

    expect(tx, isNotNull);
    expect(tx!.id, _txId);
    expect(tx.productName, 'Beras Premium');
  });

  test('createTransaction sends transaction payload with owner_id', () async {
    final newModel = StockTransactionModel(
      id: '',
      productId: _productId,
      productName: 'Beras Premium',
      productCode: 'PRD-001',
      type: TransactionType.outStock,
      quantity: 4,
      date: DateTime.parse('2026-11-25T11:00:00.000Z'),
      notes: 'Penjualan',
      createdAt: DateTime.now(),
    );

    final result = await source.createTransaction(newModel);

    expect(result.id, _txId);
    final postReq = requests.firstWhere((r) => r.method == 'POST');
    final sentBody = jsonDecode(postReq.body) as Map<String, dynamic>;
    expect(sentBody['owner_id'], _owner);
    expect(sentBody['product_id'], _productId);
    expect(sentBody['type'], 'OUT');
    expect(sentBody['quantity'], 4);
  });

  test('updateTransaction updates transaction record', () async {
    final updateModel = StockTransactionModel(
      id: _txId,
      productId: _productId,
      productName: 'Beras Premium',
      productCode: 'PRD-001',
      type: TransactionType.inStock,
      quantity: 15,
      date: DateTime.parse('2026-11-25T10:00:00.000Z'),
      notes: 'Revisi jumlah stok masuk',
      createdAt: DateTime.now(),
    );

    final result = await source.updateTransaction(updateModel);

    expect(result.quantity, 15);
    final patchReq = requests.firstWhere((r) => r.method == 'PATCH');
    expect(patchReq.url.queryParameters['id'], 'eq.$_txId');
  });

  test('deleteTransaction deletes transaction by id', () async {
    await source.deleteTransaction(_txId);

    final delReq = requests.firstWhere((r) => r.method == 'DELETE');
    expect(delReq.url.queryParameters['id'], 'eq.$_txId');
  });

  test('throws StateError when user is not authenticated', () async {
    await client.auth.signOut();

    expect(
      () => source.getTransactions(),
      throwsA(isA<StateError>().having(
        (e) => e.message,
        'message',
        contains('Silakan login'),
      )),
    );
  });
}
