import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:stockmate/features/auth/domain/entities/auth_user.dart';
import 'package:stockmate/features/auth/domain/entities/sign_up_result.dart';
import 'package:stockmate/features/auth/domain/errors/auth_failure.dart';
import 'package:stockmate/features/auth/domain/usecases/get_current_user.dart';
import 'package:stockmate/features/auth/domain/usecases/sign_in.dart';
import 'package:stockmate/features/auth/domain/usecases/sign_out.dart';
import 'package:stockmate/features/auth/domain/usecases/sign_up.dart';
import 'package:stockmate/features/auth/domain/usecases/watch_auth_state.dart';

class AuthProvider extends ChangeNotifier {
  AuthProvider({
    required GetCurrentUser getCurrentUser,
    required WatchAuthState watchAuthState,
    required SignIn signIn,
    required SignUp signUp,
    required SignOut signOut,
  }) : this._(getCurrentUser, watchAuthState, signIn, signUp, signOut);

  AuthProvider._(
    this._getCurrentUser,
    this._watchAuthState,
    this._signIn,
    this._signUp,
    this._signOut,
  ) {
    _initialize();
  }

  final GetCurrentUser _getCurrentUser;
  final WatchAuthState _watchAuthState;
  final SignIn _signIn;
  final SignUp _signUp;
  final SignOut _signOut;

  StreamSubscription<AuthUser?>? _authSubscription;
  AuthUser? _user;
  bool _isLoading = false;
  bool _isInitialized = false;
  bool _isDisposed = false;
  String? _errorMessage;

  AuthUser? get user => _user;
  bool get isAuthenticated => _user != null;
  bool get isLoading => _isLoading;
  bool get isInitialized => _isInitialized;
  String? get errorMessage => _errorMessage;

  void _initialize() {
    try {
      _user = _getCurrentUser();
    } catch (error) {
      _errorMessage = _messageFor(error);
    } finally {
      _isInitialized = true;
    }

    _authSubscription = _watchAuthState().listen(
      _handleAuthStateChanged,
      onError: _handleAuthStateError,
    );
  }

  Future<bool> signIn({required String email, required String password}) async {
    if (_isLoading) return false;
    _startRequest();

    try {
      final user = await _signIn(email: email.trim(), password: password);
      if (user == null) {
        _errorMessage = 'Sign in did not return an authenticated session.';
        return false;
      }
      _user = user;
      return true;
    } catch (error) {
      _errorMessage = _messageFor(error);
      return false;
    } finally {
      _finishRequest();
    }
  }

  Future<SignUpResult?> signUp({
    required String fullName,
    required String email,
    required String password,
  }) async {
    if (_isLoading) return null;
    _startRequest();

    try {
      final result = await _signUp(
        fullName: fullName.trim(),
        email: email.trim(),
        password: password,
      );
      _user = result.requiresEmailConfirmation ? null : result.user;
      return result;
    } catch (error) {
      _errorMessage = _messageFor(error);
      return null;
    } finally {
      _finishRequest();
    }
  }

  Future<bool> signOut() async {
    if (_isLoading) return false;
    _startRequest();

    try {
      await _signOut();
      _user = null;
      return true;
    } catch (error) {
      _errorMessage = _messageFor(error);
      return false;
    } finally {
      _finishRequest();
    }
  }

  void clearError() {
    if (_errorMessage == null) return;
    _errorMessage = null;
    _notifySafely();
  }

  void _handleAuthStateChanged(AuthUser? user) {
    _user = user;
    _errorMessage = null;
    _isInitialized = true;
    _notifySafely();
  }

  void _handleAuthStateError(Object error, StackTrace stackTrace) {
    _errorMessage = _messageFor(error);
    _isInitialized = true;
    _notifySafely();
  }

  void _startRequest() {
    _isLoading = true;
    _errorMessage = null;
    _notifySafely();
  }

  void _finishRequest() {
    _isLoading = false;
    _notifySafely();
  }

  String _messageFor(Object error) {
    if (error is AuthFailure) return error.message;
    return 'Something went wrong. Please try again.';
  }

  void _notifySafely() {
    if (!_isDisposed) notifyListeners();
  }

  @override
  void dispose() {
    _isDisposed = true;
    unawaited(_authSubscription?.cancel());
    super.dispose();
  }
}
