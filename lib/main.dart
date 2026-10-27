import 'package:flutter/widgets.dart';
import 'package:stockmate/app/app.dart';
import 'package:stockmate/app/providers/app_providers.dart';
import 'package:stockmate/core/config/app_config.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  AppConfig.validate();

  await Supabase.initialize(
    url: AppConfig.supabaseUrl,
    publishableKey: AppConfig.supabasePublishableKey,
  );

  runApp(const AppProviders(child: StockMateApp()));
}
