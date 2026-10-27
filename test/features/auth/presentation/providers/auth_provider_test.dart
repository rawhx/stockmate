import 'package:flutter_test/flutter_test.dart';
import 'package:stockmate/features/auth/domain/entities/auth_user.dart';
import 'package:stockmate/features/auth/domain/errors/auth_failure.dart';
import 'package:stockmate/features/auth/domain/usecases/get_current_user.dart';
import 'package:stockmate/features/auth/domain/usecases/sign_in.dart';
import 'package:stockmate/features/auth/domain/usecases/sign_out.dart';
import 'package:stockmate/features/auth/domain/usecases/sign_up.dart';
import 'package:stockmate/features/auth/domain/usecases/watch_auth_state.dart';
import 'package:stockmate/features/auth/presentation/providers/auth_provider.dart';

import '../../../../helpers/fake_auth_repository.dart';

void main() {
  const user = AuthUser(
    id: 'user-id',
    email: 'user@example.com',
    fullName: 'Stock Mate',
  );

  AuthProvider createProvider(FakeAuthRepository repository) {
    return AuthProvider(
      getCurrentUser: GetCurrentUser(repository),
      watchAuthState: WatchAuthState(repository),
      signIn: SignIn(repository),
      signUp: SignUp(repository),
      signOut: SignOut(repository),
    );
  }

  test('restores the current authenticated user on creation', () async {
    final repository = FakeAuthRepository(currentUser: user);
    final provider = createProvider(repository);

    expect(provider.isInitialized, isTrue);
    expect(provider.isAuthenticated, isTrue);
    expect(provider.user, same(user));

    provider.dispose();
    await repository.dispose();
  });

  test('updates the user from auth state changes', () async {
    final repository = FakeAuthRepository();
    final provider = createProvider(repository);

    repository.emitAuthState(user);

    expect(provider.user, same(user));
    expect(provider.isAuthenticated, isTrue);

    repository.emitAuthState(null);
    expect(provider.isAuthenticated, isFalse);

    provider.dispose();
    await repository.dispose();
  });

  test(
    'handles auth stream errors and cancels subscription on dispose',
    () async {
      final repository = FakeAuthRepository();
      final provider = createProvider(repository);

      repository.emitAuthError(
        const AuthFailure('The authentication session could not be refreshed.'),
      );
      expect(
        provider.errorMessage,
        'The authentication session could not be refreshed.',
      );

      provider.dispose();
      await Future<void>.delayed(Duration.zero);
      expect(repository.authStateSubscriptionCancelled, isTrue);
      await repository.dispose();
    },
  );
}
