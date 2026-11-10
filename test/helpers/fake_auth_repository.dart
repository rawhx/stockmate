import 'dart:async';

import 'package:stockmate/features/auth/domain/entities/auth_user.dart';
import 'package:stockmate/features/auth/domain/entities/sign_up_result.dart';
import 'package:stockmate/features/auth/domain/repositories/auth_repository.dart';

class FakeAuthRepository implements AuthRepository {
  FakeAuthRepository({this.currentUser}) {
    authStateController = StreamController<AuthUser?>.broadcast(
      sync: true,
      onCancel: () => authStateSubscriptionCancelled = true,
    );
  }

  AuthUser? currentUser;
  AuthUser? signInResult;
  SignUpResult signUpResult = const SignUpResult(
    user: null,
    requiresEmailConfirmation: true,
  );
  Object? signInError;
  Object? signUpError;
  Object? signOutError;
  bool authStateSubscriptionCancelled = false;
  late final StreamController<AuthUser?> authStateController;

  @override
  AuthUser? getCurrentUser() => currentUser;

  @override
  Stream<AuthUser?> watchAuthState() => authStateController.stream;

  @override
  Future<AuthUser?> signIn({
    required String email,
    required String password,
  }) async {
    if (signInError case final error?) throw error;
    currentUser = signInResult;
    return signInResult;
  }

  @override
  Future<SignUpResult> signUp({
    required String fullName,
    required String email,
    required String password,
  }) async {
    if (signUpError case final error?) throw error;
    currentUser = signUpResult.requiresEmailConfirmation
        ? null
        : signUpResult.user;
    return signUpResult;
  }

  @override
  Future<void> signOut() async {
    if (signOutError case final error?) throw error;
    currentUser = null;
    authStateController.add(null);
  }

  void emitAuthState(AuthUser? user) {
    currentUser = user;
    authStateController.add(user);
  }

  void emitAuthError(Object error) => authStateController.addError(error);

  Future<void> dispose() => authStateController.close();
}
