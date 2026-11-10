import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:stockmate/app/providers/theme_provider.dart';
import 'package:stockmate/features/auth/presentation/providers/auth_provider.dart';

class ProductListAppBar extends StatelessWidget implements PreferredSizeWidget {
  const ProductListAppBar({required this.showActions, super.key});

  final bool showActions;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Products'),
          Text(
            'Manage your inventory',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w400),
          ),
        ],
      ),
      actions: showActions
          ? [
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
