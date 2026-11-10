import 'package:supabase_flutter/supabase_flutter.dart';

class AuthRemoteDataSource {
  const AuthRemoteDataSource(this.client);

  final SupabaseClient client;

  User? getCurrentUser() => client.auth.currentUser;

  Stream<User?> watchAuthState() {
    return client.auth.onAuthStateChange.map(
      (authState) => authState.session?.user,
    );
  }

  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) {
    return client.auth.signInWithPassword(email: email, password: password);
  }

  Future<AuthResponse> signUp({
    required String fullName,
    required String email,
    required String password,
  }) {
    return client.auth.signUp(
      email: email,
      password: password,
      data: {'full_name': fullName},
    );
  }

  Future<void> signOut() => client.auth.signOut();
}
