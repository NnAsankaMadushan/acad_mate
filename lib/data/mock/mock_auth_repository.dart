import 'dart:async';

import 'package:acad_mate/domain/entities/app_user.dart';
import 'package:acad_mate/domain/repositories/auth_repository.dart';

class MockAuthRepository implements AuthRepository {
  MockAuthRepository() {
    _stateController.add(_currentUser);
  }

  final StreamController<AppUser?> _stateController =
      StreamController<AppUser?>.broadcast();

  AppUser? _currentUser;

  @override
  Stream<AppUser?> authStateChanges() => _stateController.stream;

  @override
  Future<AppUser?> currentUser() async => _currentUser;

  @override
  Future<void> register({
    required String name,
    required String email,
    required String password,
    required String grade,
    required String stream,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 700));
    _currentUser = AppUser(
      uid: 'demo-${email.hashCode.abs()}',
      name: name.trim().isEmpty ? 'AcadMate Student' : name.trim(),
      email: email.trim(),
      grade: grade,
      stream: stream,
      authProvider: 'password',
      streakDays: 7,
      completedQuestions: 128,
      bookmarkedPapers: 18,
      isFirebaseAccount: false,
    );
    _stateController.add(_currentUser);
  }

  @override
  Future<void> sendPasswordResetEmail(String email) async {
    await Future<void>.delayed(const Duration(milliseconds: 250));
  }

  @override
  Future<void> signIn({
    required String email,
    required String password,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 700));
    _currentUser = AppUser(
      uid: 'demo-${email.hashCode.abs()}',
      name: 'AcadMate Student',
      email: email.trim(),
      grade: 'A/L',
      stream: 'Science',
      authProvider: 'password',
      streakDays: 11,
      completedQuestions: 246,
      bookmarkedPapers: 24,
      isFirebaseAccount: false,
    );
    _stateController.add(_currentUser);
  }

  @override
  Future<void> signInWithProvider(SocialAuthProvider provider) async {
    await Future<void>.delayed(const Duration(milliseconds: 650));

    switch (provider) {
      case SocialAuthProvider.google:
        _currentUser = const AppUser(
          uid: 'demo-google',
          name: 'Ayesha Perera',
          email: 'ayesha.google@acadmate.app',
          grade: 'A/L',
          stream: 'Science',
          authProvider: 'google.com',
          streakDays: 14,
          completedQuestions: 312,
          bookmarkedPapers: 27,
          isFirebaseAccount: false,
        );
        break;
      case SocialAuthProvider.facebook:
        _currentUser = const AppUser(
          uid: 'demo-facebook',
          name: 'Nimal Fernando',
          email: 'nimal.facebook@acadmate.app',
          grade: 'A/L',
          stream: 'Commerce',
          authProvider: 'facebook.com',
          streakDays: 9,
          completedQuestions: 188,
          bookmarkedPapers: 16,
          isFirebaseAccount: false,
        );
        break;
      case SocialAuthProvider.apple:
        _currentUser = const AppUser(
          uid: 'demo-apple',
          name: 'Harini Silva',
          email: 'harini.apple@acadmate.app',
          grade: 'O/L',
          stream: 'All',
          authProvider: 'apple.com',
          streakDays: 6,
          completedQuestions: 95,
          bookmarkedPapers: 8,
          isFirebaseAccount: false,
        );
        break;
    }

    _stateController.add(_currentUser);
  }

  @override
  Future<void> signOut() async {
    await Future<void>.delayed(const Duration(milliseconds: 300));
    _currentUser = null;
    _stateController.add(null);
  }

  @override
  Future<void> sendOtp({required String email, required String type}) async {
    await Future<void>.delayed(const Duration(milliseconds: 500));
  }

  @override
  Future<void> verifyOtp({
    required String email,
    required String code,
    required String type,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 500));
    if (code != '123456') {
      throw Exception('Invalid verification code');
    }
  }

  @override
  Future<void> resetPasswordWithOtp({
    required String email,
    required String code,
    required String newPassword,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 500));
  }
}
