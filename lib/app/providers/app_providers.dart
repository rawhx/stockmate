import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';
import 'package:stockmate/app/providers/theme_provider.dart';
import 'package:stockmate/features/auth/data/datasources/auth_remote_data_source.dart';
import 'package:stockmate/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:stockmate/features/auth/domain/repositories/auth_repository.dart';
import 'package:stockmate/features/auth/domain/usecases/get_current_user.dart';
import 'package:stockmate/features/auth/domain/usecases/sign_in.dart';
import 'package:stockmate/features/auth/domain/usecases/sign_out.dart';
import 'package:stockmate/features/auth/domain/usecases/sign_up.dart';
import 'package:stockmate/features/auth/domain/usecases/watch_auth_state.dart';
import 'package:stockmate/features/auth/presentation/providers/auth_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AppProviders extends StatelessWidget {
  const AppProviders({required this.child, this.authRepository, super.key});

  final Widget child;
  final AuthRepository? authRepository;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        Provider<AuthRepository>(
          create: (_) {
            return authRepository ??
                AuthRepositoryImpl(
                  AuthRemoteDataSource(Supabase.instance.client),
                );
          },
        ),
        ChangeNotifierProvider(
          create: (context) {
            final repository = context.read<AuthRepository>();
            return AuthProvider(
              getCurrentUser: GetCurrentUser(repository),
              watchAuthState: WatchAuthState(repository),
              signIn: SignIn(repository),
              signUp: SignUp(repository),
              signOut: SignOut(repository),
            );
          },
        ),
      ],
      child: child,
    );
  }
}
