import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:stockmate/app/providers/theme_provider.dart';
import 'package:stockmate/app/router/app_router.dart';
import 'package:stockmate/app/router/app_routes.dart';
import 'package:stockmate/app/theme/app_theme.dart';
import 'package:stockmate/features/auth/presentation/providers/auth_provider.dart';

class StockMateApp extends StatefulWidget {
  const StockMateApp({super.key});

  @override
  State<StockMateApp> createState() => _StockMateAppState();
}

class _StockMateAppState extends State<StockMateApp> {
  GoRouter? _router;
  AuthProvider? _authProvider;
  String? _userId;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final auth = context.read<AuthProvider>();
    if (_authProvider != auth) {
      _authProvider?.removeListener(_handleAccountChanged);
      _authProvider = auth;
      _userId = auth.user?.id;
      auth.addListener(_handleAccountChanged);
    }
    _router ??= AppRouter.create(auth);
  }

  void _handleAccountChanged() {
    final userId = _authProvider?.user?.id;
    if (_userId == userId) return;
    _userId = userId;
    // Explicit navigation also clears pages pushed imperatively with context.push.
    _router?.go(userId == null ? AppRoutes.login : AppRoutes.root);
  }

  @override
  void dispose() {
    _authProvider?.removeListener(_handleAccountChanged);
    _router?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeMode = context.select<ThemeProvider, ThemeMode>(
      (provider) => provider.themeMode,
    );

    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      title: 'StockMate',
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: themeMode,
      routerConfig: _router!,
    );
  }
}
