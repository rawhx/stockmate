import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';
import 'package:stockmate/app/router/app_routes.dart';

import '../pages/stock_transaction_detail_page.dart';
import '../pages/stock_transaction_form_page.dart';
import '../pages/stock_transaction_list_page.dart';

/// Routes owned by the stock transactions feature.
final List<RouteBase> stockTransactionRoutes = <RouteBase>[
  GoRoute(
    path: AppRoutes.stockTransactions,
    builder: (context, state) => const StockTransactionListPage(),
  ),
  GoRoute(
    path: '/stock-transactions/new',
    builder: (context, state) => const StockTransactionFormPage(),
  ),
  GoRoute(
    path: '/stock-transactions/:id',
    builder: (context, state) {
      final id = state.pathParameters['id']!;
      return StockTransactionDetailPage(key: ValueKey(id), transactionId: id);
    },
  ),
  GoRoute(
    path: '/stock-transactions/:id/edit',
    builder: (context, state) {
      final id = state.pathParameters['id']!;
      return StockTransactionFormPage(key: ValueKey(id), transactionId: id);
    },
  ),
];
