import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

import '../pages/category_list_page.dart';
import '../pages/category_detail_page.dart';
import '../pages/category_form_page.dart';
import '../widgets/category_route_loader.dart';

final List<RouteBase> categoryRoutes = [
  GoRoute(
    path: '/categories',
    builder: (context, state) {
      return CategoryListPage(
        onOpenDetail: (id) => context.push('/categories/$id'),
        onEditCategory: (id) => context.push('/categories/$id/edit'),
        onAddCategory: () => context.push('/categories/new'),
      );
    },
  ),

  GoRoute(
    path: '/categories/new',
    builder: (context, state) {
      final parentId = state.uri.queryParameters['parentId'];

      return CategoryFormPage(
        parentId: parentId,
        onSaved: () => _closeCategoryForm(context, parentId),
        onCancel: () => _closeCategoryForm(context, parentId),
      );
    },
  ),

  GoRoute(
    path: '/categories/:id',
    builder: (context, state) {
      final id = state.pathParameters['id']!;

      void goBack() => _closeCategoryForm(context, null);

      return CategoryRouteLoader(
        key: ValueKey(id),
        categoryId: id,
        loadChildren: true,
        onBack: goBack,
        builder: (category) => CategoryDetailPage(
          initialCategory: category,
          onAddSubcategory: () => context.push('/categories/new?parentId=$id'),
          onEdit: () => context.push('/categories/$id/edit'),
          onBack: goBack,
          onOpenSubcategory: (subcategoryId) =>
              context.push('/categories/$subcategoryId'),
        ),
      );
    },
  ),

  GoRoute(
    path: '/categories/:id/edit',
    builder: (context, state) {
      final id = state.pathParameters['id']!;

      return CategoryRouteLoader(
        key: ValueKey(id),
        categoryId: id,
        onBack: () => _closeCategoryForm(context, null),
        builder: (category) => CategoryFormPage(
          category: category,
          onSaved: () => _closeCategoryForm(context, id),
          onCancel: () => _closeCategoryForm(context, id),
        ),
      );
    },
  ),
];

void _closeCategoryForm(BuildContext context, String? returnId) {
  if (context.canPop()) {
    context.pop();
    return;
  }

  context.go(returnId == null ? '/categories' : '/categories/$returnId');
}
