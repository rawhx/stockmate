import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:stockmate/app/providers/theme_provider.dart';
import 'package:stockmate/app/router/app_router.dart';
import 'package:stockmate/app/theme/app_theme.dart';

class StockMateApp extends StatelessWidget {
  const StockMateApp({super.key});

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
      routerConfig: AppRouter.router,
    );
  }
}
