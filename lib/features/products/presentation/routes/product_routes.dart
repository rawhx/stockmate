import 'package:go_router/go_router.dart';

import '../pages/product_detail_page.dart';
import '../pages/product_form_page.dart';
import '../pages/product_list_page.dart';

final List<RouteBase> productRoutes = [
  GoRoute(
    path: '/products',
    builder: (context, state) {
      return const ProductListPage();
    },
  ),
  GoRoute(
    path: '/products/new',
    builder: (context, state) {
      return const ProductFormPage();
    },
  ),
  GoRoute(
    path: '/products/:id',
    builder: (context, state) {
      return ProductDetailPage(productId: state.pathParameters['id']!);
    },
  ),
];
