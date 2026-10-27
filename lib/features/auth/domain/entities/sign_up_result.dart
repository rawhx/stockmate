import 'package:stockmate/features/auth/domain/entities/auth_user.dart';

class SignUpResult {
  const SignUpResult({
    required this.user,
    required this.requiresEmailConfirmation,
  });

  final AuthUser? user;
  final bool requiresEmailConfirmation;
}
