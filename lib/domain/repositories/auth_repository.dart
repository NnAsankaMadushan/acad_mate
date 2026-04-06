import 'package:acad_mate/domain/entities/app_user.dart';

enum SocialAuthProvider {
  apple,
  facebook,
  google,
}

abstract class AuthRepository {
  Stream<AppUser?> authStateChanges();

  Future<AppUser?> currentUser();

  Future<void> signIn({
    required String email,
    required String password,
  });

  Future<void> register({
    required String name,
    required String email,
    required String password,
    required String grade,
    required String stream,
  });

  Future<void> signInWithProvider(SocialAuthProvider provider);

  Future<void> signOut();

  Future<void> sendPasswordResetEmail(String email);

  Future<void> sendOtp({
    required String email,
    required String type, // 'signup' or 'password_reset'
  });

  Future<Map<String, dynamic>> submitQuizResult({
    required String quizId,
    required int score,
    required int total,
  });

  Future<void> verifyOtp({
    required String email,
    required String code,
    required String type,
  });

  Future<void> resetPasswordWithOtp({
    required String email,
    required String code,
    required String newPassword,
  });
}

