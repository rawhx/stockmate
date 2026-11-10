import 'package:stockmate/features/auth/domain/entities/auth_user.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show User;

class AuthUserModel extends AuthUser {
  const AuthUserModel({
    required super.id,
    required super.email,
    super.fullName,
  });

  factory AuthUserModel.fromSupabaseUser(User user) {
    final rawFullName = user.userMetadata?['full_name'];
    final fullName = rawFullName is String && rawFullName.trim().isNotEmpty
        ? rawFullName.trim()
        : null;

    return AuthUserModel(
      id: user.id,
      email: user.email ?? '',
      fullName: fullName,
    );
  }
}
