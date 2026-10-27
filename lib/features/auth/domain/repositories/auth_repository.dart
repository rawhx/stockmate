import 'package:stockmate/features/auth/domain/entities/auth_user.dart';
import 'package:stockmate/features/auth/domain/entities/sign_up_result.dart';

abstract interface class AuthRepository {
  AuthUser? getCurrentUser();

  Stream<AuthUser?> watchAuthState();

  Future<AuthUser?> signIn({required String email, required String password});

  Future<SignUpResult> signUp({
    required String fullName,
    required String email,
    required String password,
  });

  Future<void> signOut();
}
