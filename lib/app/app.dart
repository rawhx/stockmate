import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:stockmate/app/providers/theme_provider.dart';
import 'package:stockmate/app/router/app_router.dart';
import 'package:stockmate/app/theme/app_theme.dart';
import 'package:stockmate/features/auth/presentation/providers/auth_provider.dart';

class StockMateApp extends StatefulWidget {
  const StockMateApp({super.key});

  @override
  State<StockMateApp> createState() => _StockMateAppState();
}

class _StockMateAppState extends State<StockMateApp> {
  GoRouter? _router;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _router ??= AppRouter.create(context.read<AuthProvider>());
  }

  @override
  void dispose() {
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
