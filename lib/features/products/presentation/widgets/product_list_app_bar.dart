import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:stockmate/app/providers/theme_provider.dart';
import 'package:stockmate/app/router/app_routes.dart';
import 'package:stockmate/features/auth/presentation/providers/auth_provider.dart';

class ProductListAppBar extends StatelessWidget implements PreferredSizeWidget {
  const ProductListAppBar({
    required this.showActions,
    this.title = 'Products',
    this.subtitle = 'Manage your inventory',
    this.additionalActions = const [],
    super.key,
  });

  final bool showActions;
  final String title;
  final String subtitle;
  final List<Widget> additionalActions;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title),
          Text(
            subtitle,
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w400),
          ),
        ],
      ),
      actions: showActions
          ? [
              ...additionalActions,
              IconButton(
                onPressed: () => context.push('/categories'),
                tooltip: 'Buka Categories',
                icon: const Icon(Icons.category_outlined),
              ),
              IconButton(
                onPressed: () => context.push(AppRoutes.suppliers),
                tooltip: 'Pemasok',
                icon: const Icon(Icons.store_outlined),
              ),
              IconButton(
                onPressed: () => context.push(AppRoutes.stockTransactions),
                tooltip: 'Transaksi Stok',
                icon: const Icon(Icons.swap_horiz_outlined),
              ),
              IconButton(
                onPressed: context.read<ThemeProvider>().toggleTheme,
                tooltip: 'Change theme',
                icon: const Icon(Icons.brightness_6_outlined),
              ),
              IconButton(
                onPressed:
                    context.select<AuthProvider, bool>(
                      (provider) => provider.isLoading,
                    )
                    ? null
                    : () => _signOut(context),
                tooltip: 'Sign out',
                icon: const Icon(Icons.logout_outlined),
              ),
              const SizedBox(width: 8),
            ]
          : null,
    );
  }

  Future<void> _signOut(BuildContext context) async {
    final provider = context.read<AuthProvider>();
    final success = await provider.signOut();
    if (!success && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(provider.errorMessage ?? 'Unable to sign out.')),
      );
    }
  }
}
