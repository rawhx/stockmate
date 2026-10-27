import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';
import 'package:stockmate/app/providers/theme_provider.dart';

class AppProviders extends StatelessWidget {
  const AppProviders({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [ChangeNotifierProvider(create: (_) => ThemeProvider())],
      child: child,
    );
  }
}
