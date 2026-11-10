import 'package:stockmate/features/auth/data/datasources/auth_remote_data_source.dart';
import 'package:stockmate/features/auth/data/models/auth_user_model.dart';
import 'package:stockmate/features/auth/domain/entities/auth_user.dart';
import 'package:stockmate/features/auth/domain/entities/sign_up_result.dart';
import 'package:stockmate/features/auth/domain/errors/auth_failure.dart';
import 'package:stockmate/features/auth/domain/repositories/auth_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show AuthException;

class AuthRepositoryImpl implements AuthRepository {
  const AuthRepositoryImpl(this.remoteDataSource);

  final AuthRemoteDataSource remoteDataSource;

  @override
  AuthUser? getCurrentUser() {
    final user = remoteDataSource.getCurrentUser();
    return user == null ? null : AuthUserModel.fromSupabaseUser(user);
  }

  @override
  Stream<AuthUser?> watchAuthState() async* {
    try {
      await for (final user in remoteDataSource.watchAuthState()) {
        yield user == null ? null : AuthUserModel.fromSupabaseUser(user);
      }
    } on AuthException catch (error) {
      throw _mapAuthException(error);
    } catch (_) {
      throw const AuthFailure(
        'Authentication state could not be refreshed. Please try again.',
        code: AuthFailureCode.network,
      );
    }
  }

  @override
  Future<AuthUser?> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final response = await remoteDataSource.signIn(
        email: email,
        password: password,
      );
      final user = response.session?.user ?? response.user;
      return user == null ? null : AuthUserModel.fromSupabaseUser(user);
    } on AuthException catch (error) {
      throw _mapAuthException(error);
    } catch (_) {
      throw const AuthFailure(
        'Unable to contact the authentication service. Please try again.',
        code: AuthFailureCode.network,
      );
    }
  }

  @override
  Future<SignUpResult> signUp({
    required String fullName,
    required String email,
    required String password,
  }) async {
    try {
      final response = await remoteDataSource.signUp(
        fullName: fullName,
        email: email,
        password: password,
      );
      final user = response.user;

      return SignUpResult(
        user: user == null ? null : AuthUserModel.fromSupabaseUser(user),
        requiresEmailConfirmation: response.session == null,
      );
    } on AuthException catch (error) {
      throw _mapAuthException(error);
    } catch (_) {
      throw const AuthFailure(
        'Unable to create the account right now. Please try again.',
        code: AuthFailureCode.network,
      );
    }
  }

  @override
  Future<void> signOut() async {
    try {
      await remoteDataSource.signOut();
    } on AuthException catch (error) {
      throw _mapAuthException(error);
    } catch (_) {
      throw const AuthFailure(
        'Unable to sign out right now. Please try again.',
        code: AuthFailureCode.network,
      );
    }
  }

  AuthFailure _mapAuthException(AuthException error) {
    return switch (error.code) {
      'invalid_credentials' => const AuthFailure(
        'The email or password is incorrect.',
        code: AuthFailureCode.invalidCredentials,
      ),
      'email_not_confirmed' => const AuthFailure(
        'Please verify your email before signing in.',
        code: AuthFailureCode.emailNotConfirmed,
      ),
      'email_exists' || 'user_already_exists' => const AuthFailure(
        'An account with this email already exists.',
        code: AuthFailureCode.userAlreadyRegistered,
      ),
      'weak_password' => const AuthFailure(
        'The password does not meet the security requirements.',
        code: AuthFailureCode.weakPassword,
      ),
      'validation_failed' => const AuthFailure(
        'Please enter a valid email address and password.',
        code: AuthFailureCode.invalidEmail,
      ),
      'over_request_rate_limit' ||
      'over_email_send_rate_limit' => const AuthFailure(
        'Too many attempts. Please wait a moment and try again.',
        code: AuthFailureCode.rateLimited,
      ),
      _ => AuthFailure(error.message),
    };
  }
}
