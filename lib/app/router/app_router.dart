import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:stockmate/app/providers/theme_provider.dart';
import 'package:stockmate/app/router/app_routes.dart';
import 'package:stockmate/features/auth/presentation/providers/auth_provider.dart';
import 'package:stockmate/features/auth/presentation/routes/auth_routes.dart';
import 'package:stockmate/features/categories/presentation/routes/category_routes.dart';
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
          builder: (context, state) => const _AppPlaceholderPage(),
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

class _AppPlaceholderPage extends StatelessWidget {
  const _AppPlaceholderPage();

  @override
  Widget build(BuildContext context) {
    final isLoading = context.select<AuthProvider, bool>(
      (provider) => provider.isLoading,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('StockMate'),
        actions: [
          IconButton(
            onPressed: context.read<ThemeProvider>().toggleTheme,
            tooltip: 'Change theme',
            icon: const Icon(Icons.brightness_6_outlined),
          ),
          IconButton(
            onPressed: isLoading
                ? null
                : () async {
                    final provider = context.read<AuthProvider>();
                    final success = await provider.signOut();
                    if (!success && context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            provider.errorMessage ?? 'Unable to sign out.',
                          ),
                        ),
                      );
                    }
                  },
            tooltip: 'Sign out',
            icon: const Icon(Icons.logout_outlined),
          ),
        ],
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.inventory_2_outlined,
                size: 72,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(height: 20),
              Text(
                'StockMate is ready',
                style: Theme.of(context).textTheme.headlineSmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              const Text(
                'Your authenticated workspace is ready for features.',
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
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
