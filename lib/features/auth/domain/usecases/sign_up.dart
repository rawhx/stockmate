import 'package:stockmate/features/auth/domain/entities/sign_up_result.dart';
import 'package:stockmate/features/auth/domain/repositories/auth_repository.dart';

class SignUp {
  const SignUp(this.repository);

  final AuthRepository repository;

  Future<SignUpResult> call({
    required String fullName,
    required String email,
    required String password,
  }) {
    return repository.signUp(
      fullName: fullName,
      email: email,
      password: password,
    );
  }
}
