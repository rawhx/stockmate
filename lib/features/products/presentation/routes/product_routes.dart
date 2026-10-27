import 'package:go_router/go_router.dart';

import '../pages/product_list_page.dart';

final List<RouteBase> productRoutes = [
  GoRoute(
    path: '/products',
    builder: (context, state) {
      return const ProductListPage();
    },
  ),
];
