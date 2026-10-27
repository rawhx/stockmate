import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:stockmate/app/router/app_routes.dart';
import 'package:stockmate/features/auth/presentation/providers/auth_provider.dart';
import 'package:stockmate/features/auth/presentation/routes/auth_routes.dart';
import 'package:stockmate/features/categories/presentation/routes/category_routes.dart';
import 'package:stockmate/features/products/presentation/pages/product_list_page.dart';
import 'package:stockmate/features/products/presentation/routes/product_routes.dart';
import 'package:stockmate/features/stock_transactions/presentation/routes/stock_transaction_routes.dart';
import 'package:stockmate/features/suppliers/presentation/routes/supplier_routes.dart';

abstract final class AppRouter {
  static GoRouter create(AuthProvider authProvider) {
    return GoRouter(
      initialLocation: AppRoutes.root,
      refreshListenable: authProvider,
      redirect: (context, state) {
        if (!authProvider.isInitialized) return null;

        final isAuthRoute =
            state.matchedLocation == AppRoutes.login ||
            state.matchedLocation == AppRoutes.register;

        if (!authProvider.isAuthenticated) {
          return isAuthRoute ? null : AppRoutes.login;
        }

        return isAuthRoute ? AppRoutes.root : null;
      },
      routes: [
        GoRoute(
          path: AppRoutes.root,
          builder: (context, state) => const ProductListPage(),
        ),
        ...authRoutes,
        ...productRoutes,
        ...categoryRoutes,
        ...supplierRoutes,
        ...stockTransactionRoutes,
      ],
      errorBuilder: (context, state) => _RouterErrorPage(error: state.error),
    );
  }
}

class _RouterErrorPage extends StatelessWidget {
  const _RouterErrorPage({this.error});

  final Exception? error;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Halaman tidak ditemukan')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            error?.toString() ?? 'Rute yang diminta tidak tersedia.',
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}
