import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:stockmate/app/providers/theme_provider.dart';
import 'package:stockmate/app/router/app_routes.dart';

abstract final class AppRouter {
  static final GoRouter router = GoRouter(
    initialLocation: AppRoutes.root,
    routes: [
      GoRoute(
        path: AppRoutes.root,
        builder: (context, state) => const _AppPlaceholderPage(),
      ),
    ],
    errorBuilder: (context, state) => _RouterErrorPage(error: state.error),
  );
}

class _AppPlaceholderPage extends StatelessWidget {
  const _AppPlaceholderPage();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('StockMate'),
        actions: [
          IconButton(
            onPressed: context.read<ThemeProvider>().toggleTheme,
            tooltip: 'Ganti tema',
            icon: const Icon(Icons.brightness_6_outlined),
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
                'Boilerplate aplikasi siap',
                style: Theme.of(context).textTheme.headlineSmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              const Text(
                'Tambahkan halaman feature kelompok melalui AppRouter.',
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
