import 'package:flutter/widgets.dart';
import 'package:stockmate/app/app.dart';
import 'package:stockmate/app/providers/app_providers.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const AppProviders(child: StockMateApp()));
}
