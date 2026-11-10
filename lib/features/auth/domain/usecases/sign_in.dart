import 'package:stockmate/features/auth/domain/entities/auth_user.dart';
import 'package:stockmate/features/auth/domain/repositories/auth_repository.dart';

class SignIn {
  const SignIn(this.repository);

  final AuthRepository repository;

  Future<AuthUser?> call({required String email, required String password}) {
    return repository.signIn(email: email, password: password);
  }
}
