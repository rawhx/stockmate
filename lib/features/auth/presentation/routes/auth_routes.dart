import 'package:go_router/go_router.dart';
import 'package:stockmate/app/router/app_routes.dart';
import 'package:stockmate/features/auth/presentation/pages/login_page.dart';
import 'package:stockmate/features/auth/presentation/pages/register_page.dart';

final List<RouteBase> authRoutes = <RouteBase>[
  GoRoute(
    path: AppRoutes.login,
    builder: (context, state) {
      return LoginPage(
        showEmailVerificationMessage:
            state.uri.queryParameters['registered'] == 'true',
      );
    },
  ),
  GoRoute(
    path: AppRoutes.register,
    builder: (context, state) => const RegisterPage(),
  ),
];
