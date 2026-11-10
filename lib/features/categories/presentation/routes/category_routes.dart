import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../data/datasources/category_mock_datasource.dart';
import '../../data/repositories/category_repository_impl.dart';

import '../../domain/usecases/get_categories.dart';
import '../../domain/usecases/get_category_by_id.dart';
import '../../domain/usecases/add_category.dart';
import '../../domain/usecases/update_category.dart';
import '../../domain/usecases/delete_category.dart';

import '../providers/category_provider.dart';
import '../pages/category_list_page.dart';
import '../pages/category_detail_page.dart';
import '../pages/category_form_page.dart';

// Satu sumber dummy dan satu Provider untuk seluruh
// navigasi fitur Categories.
final CategoryMockDataSource _dataSource = CategoryMockDataSource();

final CategoryRepositoryImpl _repository = CategoryRepositoryImpl(_dataSource);

final CategoryProvider _categoryProvider = CategoryProvider(
  getCategories: GetCategories(_repository),
  getCategoryById: GetCategoryById(_repository),
  addCategory: AddCategory(_repository),
  updateCategory: UpdateCategory(_repository),
  deleteCategory: DeleteCategory(_repository),
)..loadCategories();

// Routes milik fitur Categories.

final List<RouteBase> categoryRoutes = [
  GoRoute(
    path: '/categories',
    builder: (context, state) {
      return ChangeNotifierProvider<CategoryProvider>.value(
        value: _categoryProvider,
        child: CategoryListPage(
          onOpenDetail: (id) => context.push('/categories/$id'),
          onEditCategory: (id) => context.push('/categories/$id/edit'),
          onAddCategory: () => context.push('/categories/new'),
        ),
      );
    },
  ),

  GoRoute(
    path: '/categories/new',
    builder: (context, state) {
      return ChangeNotifierProvider<CategoryProvider>.value(
        value: _categoryProvider,
        child: CategoryFormPage(
          onSaved: () => context.go('/categories'),
          onCancel: () => context.go('/categories'),
        ),
      );
    },
  ),

  GoRoute(
    path: '/categories/:id',
    builder: (context, state) {
      final id = state.pathParameters['id']!;

      return ChangeNotifierProvider<CategoryProvider>.value(
        value: _categoryProvider,
        child: CategoryDetailPage(
          categoryId: id,
          onEdit: () => context.push('/categories/$id/edit'),
          onBack: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/categories');
            }
          },
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

      return ChangeNotifierProvider<CategoryProvider>.value(
        value: _categoryProvider,
        child: CategoryFormPage(
          categoryId: id,
          onSaved: () => context.go('/categories/$id'),
          onCancel: () => context.go('/categories/$id'),
        ),
      );
    },
  ),
];
