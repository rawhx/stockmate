import 'package:go_router/go_router.dart';
import 'package:stockmate/app/router/app_routes.dart';
import 'package:stockmate/features/suppliers/presentation/pages/supplier_form_page.dart';
import 'package:stockmate/features/suppliers/presentation/pages/suppliers_page.dart';

/// Routes owned by the suppliers feature.
final List<RouteBase> supplierRoutes = <RouteBase>[
  GoRoute(
    path: AppRoutes.suppliers,
    builder: (context, state) => const SuppliersPage(),
  ),
  GoRoute(
    path: '/suppliers/form',
    builder: (context, state) => const SupplierFormPage(),
  ),
];
