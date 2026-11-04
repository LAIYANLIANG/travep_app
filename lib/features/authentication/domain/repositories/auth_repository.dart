import 'package:dartz/dartz.dart';
import '../entities/user_model.dart';

abstract class AuthRepository {
  /// Stream of the current user. Emits null if not logged in.
  Stream<AppUser?> get user;
  
  /// Current user synchronously
  AppUser? get currentUser;

  /// Sign in with Google
  Future<Either<String, AppUser>> signInWithGoogle();

  /// Sign in with Apple
  Future<Either<String, AppUser>> signInWithApple();
  
  /// Sign out
  Future<void> signOut();

  /// Join a project via invitation code
  Future<Either<String, void>> joinProject(String projectCode);
}
