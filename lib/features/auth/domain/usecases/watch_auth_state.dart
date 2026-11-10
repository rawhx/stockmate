import 'package:stockmate/features/auth/domain/entities/auth_user.dart';
import 'package:stockmate/features/auth/domain/repositories/auth_repository.dart';

class WatchAuthState {
  const WatchAuthState(this.repository);

  final AuthRepository repository;

  Stream<AuthUser?> call() => repository.watchAuthState();
}
