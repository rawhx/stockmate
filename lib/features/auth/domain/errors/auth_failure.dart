enum AuthFailureCode {
  invalidCredentials,
  invalidEmail,
  emailNotConfirmed,
  userAlreadyRegistered,
  weakPassword,
  rateLimited,
  network,
  unexpected,
}

class AuthFailure implements Exception {
  const AuthFailure(this.message, {this.code = AuthFailureCode.unexpected});

  final String message;
  final AuthFailureCode code;

  @override
  String toString() => 'AuthFailure($code, $message)';
}
