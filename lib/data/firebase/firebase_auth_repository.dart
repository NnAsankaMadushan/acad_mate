import 'package:acad_mate/core/config/app_config.dart';
import 'package:acad_mate/data/backend/backend_profile_client.dart';
import 'package:acad_mate/domain/entities/app_user.dart';
import 'package:acad_mate/domain/repositories/auth_repository.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class FirebaseAuthRepository implements AuthRepository {
  FirebaseAuthRepository({
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
    BackendProfileClient? backendProfileClient,
  }) : _auth = auth ?? FirebaseAuth.instance,
       _firestore = firestore ?? FirebaseFirestore.instance,
       _backendProfileClient = backendProfileClient;

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;
  final BackendProfileClient? _backendProfileClient;
  bool _googleSignInInitialized = false;

  CollectionReference<Map<String, dynamic>> get _users =>
      _firestore.collection('users');

  bool get _useMongoBackend =>
      AppConfig.useMongoBackend && _backendProfileClient != null;

  @override
  Stream<AppUser?> authStateChanges() {
    return _auth.authStateChanges().asyncMap(
      (User? user) async => user == null ? null : _mapFirebaseUser(user),
    );
  }

  @override
  Future<AppUser?> currentUser() async {
    final User? user = _auth.currentUser;
    if (user == null) {
      return null;
    }
    return _mapFirebaseUser(user);
  }

  @override
  Future<void> register({
    required String name,
    required String email,
    required String password,
    required String grade,
    required String stream,
  }) async {
    final UserCredential credential = await _auth
        .createUserWithEmailAndPassword(email: email.trim(), password: password)
        .then((UserCredential value) async {
          await value.user?.updateDisplayName(name.trim());
          return value;
        });

    final User? user = credential.user;
    if (user == null) {
      return;
    }

    await _persistUserProfile(
      user,
      name: name.trim(),
      email: email.trim(),
      grade: grade,
      stream: stream,
      authProvider: _providerIdFor(user, fallback: 'password'),
    );
  }

  @override
  Future<void> signIn({required String email, required String password}) async {
    await _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
  }

  @override
  Future<void> signInWithProvider(SocialAuthProvider provider) async {
    switch (provider) {
      case SocialAuthProvider.google:
        await _signInWithGoogle();
        break;
      case SocialAuthProvider.facebook:
        await _signInWithFacebook();
        break;
      case SocialAuthProvider.apple:
        await _signInWithApple();
        break;
    }
  }

  @override
  Future<void> sendPasswordResetEmail(String email) {
    return _auth.sendPasswordResetEmail(email: email.trim());
  }

  @override
  Future<void> signOut() {
    return _auth.signOut();
  }

  @override
  Future<void> sendOtp({required String email, required String type}) async {
    if (_backendProfileClient == null) {
      throw StateError('Backend client not initialized.');
    }
    await _backendProfileClient.sendOtp(email: email, type: type);
  }

  @override
  Future<Map<String, dynamic>> submitQuizResult({
    required String quizId,
    required int score,
    required int total,
  }) async {
    if (_backendProfileClient == null) {
      // If no backend client is configured, persist only to Firestore.
      final User? user = _auth.currentUser;
      if (user == null) {
        throw StateError('No authenticated user.');
      }
      final List<String> completedQuizIds = <String>[];
      if (score == total) {
        completedQuizIds.add(quizId);
      }
      final Map<String, dynamic> payload = <String, dynamic>{
        'completedQuestions': FieldValue.increment(total),
        if (completedQuizIds.isNotEmpty) 'completedQuizIds': completedQuizIds,
      };
      await _users.doc(user.uid).set(payload, SetOptions(merge: true));
      return payload;
    }

    final User? user = _auth.currentUser;
    if (user == null) {
      throw StateError('No authenticated user.');
    }

    final String? idToken = await user.getIdToken();
    if (idToken == null || idToken.isEmpty) {
      throw StateError('Firebase did not return an ID token.');
    }

    return _backendProfileClient.submitQuizResult(
      idToken: idToken,
      quizId: quizId,
      score: score,
      total: total,
    );
  }

  @override
  Future<void> verifyOtp({
    required String email,
    required String code,
    required String type,
  }) async {
    if (_backendProfileClient == null) {
      throw StateError('Backend client not initialized.');
    }
    await _backendProfileClient.verifyOtp(email: email, code: code, type: type);
  }

  @override
  Future<void> resetPasswordWithOtp({
    required String email,
    required String code,
    required String newPassword,
  }) async {
    if (_backendProfileClient == null) {
      throw StateError('Backend client not initialized.');
    }
    await _backendProfileClient.resetPassword(
      email: email,
      code: code,
      newPassword: newPassword,
    );
  }

  Future<void> _signInWithGoogle() async {
    if (kIsWeb) {
      final GoogleAuthProvider provider = GoogleAuthProvider()
        ..addScope('email')
        ..setCustomParameters(<String, String>{'prompt': 'select_account'});
      await _auth.signInWithPopup(provider);
      return;
    }

    final String? serverClientId =
        defaultTargetPlatform == TargetPlatform.android
        ? null
        : AppConfig.googleServerClientId.trim().isEmpty
        ? null
        : AppConfig.googleServerClientId.trim();
    await _ensureGoogleSignInInitialized(serverClientId: serverClientId);
    try {
      final GoogleSignInAccount account = await GoogleSignIn.instance
          .authenticate(scopeHint: <String>['email']);
      final GoogleSignInAuthentication auth = account.authentication;
      final String? idToken = auth.idToken;
      if (idToken == null || idToken.isEmpty) {
        throw StateError('Google sign-in did not return an ID token.');
      }
      final OAuthCredential credential = GoogleAuthProvider.credential(
        idToken: idToken,
      );
      await _auth.signInWithCredential(credential);
    } on GoogleSignInException catch (error) {
      if (error.code == GoogleSignInExceptionCode.canceled) {
        throw StateError(
          'Google sign-in was canceled by Android. If you did not cancel it manually, '
          'check that Firebase Auth Google sign-in is enabled and that the Android app '
          'SHA-1/SHA-256 fingerprints are registered in Firebase.',
        );
      }
      rethrow;
    }
  }

  Future<void> _signInWithFacebook() async {
    if (kIsWeb) {
      final FacebookAuthProvider provider = FacebookAuthProvider()
        ..addScope('email')
        ..addScope('public_profile');
      await _auth.signInWithPopup(provider);
      return;
    }

    final LoginResult result = await FacebookAuth.instance.login(
      permissions: <String>['email', 'public_profile'],
    );
    if (result.status != LoginStatus.success) {
      final String message =
          result.message ?? 'Facebook sign-in was cancelled.';
      throw StateError(message);
    }

    final AccessToken? accessToken = result.accessToken;
    if (accessToken == null) {
      throw StateError('Facebook sign-in did not return an access token.');
    }

    final OAuthCredential credential = FacebookAuthProvider.credential(
      accessToken.tokenString,
    );
    await _auth.signInWithCredential(credential);
  }

  Future<void> _signInWithApple() async {
    final AppleAuthProvider provider = AppleAuthProvider()
      ..addScope('email')
      ..addScope('name');

    if (kIsWeb) {
      await _auth.signInWithPopup(provider);
      return;
    }

    await _auth.signInWithProvider(provider);
  }

  Future<void> _ensureGoogleSignInInitialized({String? serverClientId}) async {
    if (_googleSignInInitialized) {
      return;
    }

    await GoogleSignIn.instance.initialize(serverClientId: serverClientId);
    _googleSignInInitialized = true;
  }

  Future<void> _persistUserProfile(
    User user, {
    required String name,
    required String email,
    required String grade,
    required String stream,
    required String authProvider,
  }) async {
    final Map<String, dynamic> payload = <String, dynamic>{
      'name': name,
      'email': email,
      'grade': grade,
      'stream': stream,
      'avatarUrl': user.photoURL,
      'authProvider': authProvider,
      'streakDays': 0,
      'completedQuestions': 0,
      'bookmarkedPapers': 0,
      'isFirebaseAccount': true,
    };

    if (_useMongoBackend) {
      await _syncProfileWithBackend(user, payload);
      return;
    }

    await _syncProfileWithFirestore(user, payload);
  }

  Future<void> _syncProfileWithBackend(
    User user,
    Map<String, dynamic> payload,
  ) async {
    final BackendProfileClient? client = _backendProfileClient;
    if (client == null) {
      return;
    }

    try {
      final String? idToken = await user.getIdToken();
      if (idToken == null || idToken.isEmpty) {
        throw StateError('Firebase did not return an ID token.');
      }
      final List<String> mergedLinkedProviders = <String>{
        ...user.providerData
            .map((UserInfo info) => info.providerId)
            .whereType<String>(),
        ...((payload['linkedProviders'] as List<dynamic>?) ?? const <dynamic>[])
            .map((dynamic item) => item.toString()),
      }.where((String item) => item.isNotEmpty).toList();
      await client.upsertCurrentUserProfile(
        idToken: idToken,
        payload: <String, dynamic>{
          'firebaseUid': user.uid,
          ...payload,
          'linkedProviders': mergedLinkedProviders,
        },
      );
    } catch (_) {
      await _syncProfileWithFirestore(user, payload);
    }
  }

  Future<void> _syncProfileWithFirestore(
    User user,
    Map<String, dynamic> payload,
  ) async {
    final List<String> mergedLinkedProviders = <String>{
      ...user.providerData
          .map((UserInfo info) => info.providerId)
          .whereType<String>(),
      ...((payload['linkedProviders'] as List<dynamic>?) ?? const <dynamic>[])
          .map((dynamic item) => item.toString()),
    }.where((String item) => item.isNotEmpty).toList();

    await _users.doc(user.uid).set(<String, dynamic>{
      'firebaseUid': user.uid,
      'createdAt': FieldValue.serverTimestamp(),
      ...payload,
      'linkedProviders': mergedLinkedProviders,
    }, SetOptions(merge: true));
  }

  Future<AppUser?> _mapFirebaseUser(User user) async {
    if (_useMongoBackend) {
      try {
        final DocumentSnapshot<Map<String, dynamic>> snapshot = await _users
            .doc(user.uid)
            .get();
        final Map<String, dynamic>? firestoreData = snapshot.data();
        if (firestoreData != null) {
          await _syncProfileWithBackend(
            user,
            _payloadFromStoredData(user, firestoreData),
          );
        }

        final String? idToken = await user.getIdToken();
        if (idToken == null || idToken.isEmpty) {
          throw StateError('Firebase did not return an ID token.');
        }
        final Map<String, dynamic> data = await _backendProfileClient!
            .loadCurrentUserProfile(idToken: idToken);
        return _appUserFromMap(user, data);
      } catch (_) {}
    }

    try {
      final DocumentSnapshot<Map<String, dynamic>> snapshot = await _users
          .doc(user.uid)
          .get();
      final Map<String, dynamic>? data = snapshot.data();
      if (data != null) {
        return _appUserFromMap(user, data);
      }
    } catch (_) {}

    return _defaultAppUser(user);
  }

  Map<String, dynamic> _payloadFromStoredData(
    User user,
    Map<String, dynamic> data,
  ) {
    return <String, dynamic>{
      'name':
          data['name']?.toString() ?? user.displayName ?? 'AcadMate Student',
      'email': data['email']?.toString() ?? user.email ?? '',
      'grade': data['grade']?.toString() ?? 'A/L',
      'stream': data['stream']?.toString() ?? 'Science',
      'avatarUrl': data['avatarUrl']?.toString() ?? user.photoURL,
      'authProvider':
          data['authProvider']?.toString() ??
          _providerIdFor(user, fallback: 'password'),
      'streakDays': (data['streakDays'] as num?)?.toInt() ?? 0,
      'completedQuestions': (data['completedQuestions'] as num?)?.toInt() ?? 0,
      'bookmarkedPapers': (data['bookmarkedPapers'] as num?)?.toInt() ?? 0,
      'completedQuizIds':
          (data['completedQuizIds'] as List<dynamic>?)
              ?.map((dynamic item) => item.toString())
              .where((String item) => item.isNotEmpty)
              .toList() ??
          const <String>[],
      'quizResults':
          (data['quizResults'] as List<dynamic>?)
              ?.whereType<Map<dynamic, dynamic>>()
              .map((Map<dynamic, dynamic> result) => <String, dynamic>{
                    'quizId': result['quizId']?.toString() ?? '',
                    'score': (result['score'] as num?)?.toInt() ?? 0,
                    'total': (result['total'] as num?)?.toInt() ?? 0,
                    'completedAt': result['completedAt'] is DateTime
                        ? result['completedAt'] as DateTime
                        : result['completedAt']?.toString(),
                    'isPerfect': result['isPerfect'] as bool? ?? false,
                  })
              .toList() ??
          const <Map<String, dynamic>>[],
      'isFirebaseAccount': data['isFirebaseAccount'] as bool? ?? true,
      'linkedProviders':
          (data['linkedProviders'] as List<dynamic>? ?? const <dynamic>[])
              .map((dynamic item) => item.toString())
              .where((String item) => item.isNotEmpty)
              .toList(),
    };
  }

  AppUser _appUserFromMap(User user, Map<String, dynamic> data) {
    final String providerId =
        data['authProvider']?.toString() ??
        _providerIdFor(user, fallback: 'password');

    final List<String> completedQuizIds =
        (data['completedQuizIds'] as List<dynamic>?)
            ?.map((dynamic item) => item.toString())
            .where((String item) => item.isNotEmpty)
            .toList() ??
        const <String>[];

    final List<QuizResult> quizResults =
        (data['quizResults'] as List<dynamic>?)
            ?.whereType<Map<dynamic, dynamic>>()
            .map((Map<dynamic, dynamic> result) {
          final String quizId = result['quizId']?.toString() ?? '';
          final int score = (result['score'] as num?)?.toInt() ?? 0;
          final int total = (result['total'] as num?)?.toInt() ?? 0;
          final DateTime completedAt;
          if (result['completedAt'] is String) {
            completedAt = DateTime.tryParse(result['completedAt'] as String) ??
                DateTime.fromMillisecondsSinceEpoch(0);
          } else if (result['completedAt'] is DateTime) {
            completedAt = result['completedAt'] as DateTime;
          } else {
            completedAt = DateTime.fromMillisecondsSinceEpoch(0);
          }

          return QuizResult(
            quizId: quizId,
            score: score,
            total: total,
            completedAt: completedAt,
            isPerfect: result['isPerfect'] as bool? ?? score == total,
          );
        })
            .where((QuizResult result) => result.quizId.isNotEmpty)
            .toList() ??
        const <QuizResult>[];

    return AppUser(
      uid: data['firebaseUid']?.toString() ?? user.uid,
      name: data['name']?.toString() ?? user.displayName ?? 'AcadMate Student',
      email: data['email']?.toString() ?? user.email ?? '',
      grade: data['grade']?.toString() ?? 'A/L',
      stream: data['stream']?.toString() ?? 'Science',
      avatarUrl: data['avatarUrl']?.toString() ?? user.photoURL,
      authProvider: providerId,
      streakDays: (data['streakDays'] as num?)?.toInt() ?? 0,
      completedQuestions: (data['completedQuestions'] as num?)?.toInt() ?? 0,
      bookmarkedPapers: (data['bookmarkedPapers'] as num?)?.toInt() ?? 0,
      completedQuizIds: completedQuizIds,
      quizResults: quizResults,
      isFirebaseAccount: data['isFirebaseAccount'] as bool? ?? true,
    );
  }

  AppUser _defaultAppUser(User user) {
    return AppUser(
      uid: user.uid,
      name: user.displayName ?? 'AcadMate Student',
      email: user.email ?? '',
      grade: 'A/L',
      stream: 'Science',
      avatarUrl: user.photoURL,
      authProvider: _providerIdFor(user, fallback: 'password'),
      isFirebaseAccount: true,
    );
  }

  String _providerIdFor(User user, {required String fallback}) {
    for (final UserInfo info in user.providerData) {
      final String providerId = info.providerId;
      if (providerId.isNotEmpty) {
        return providerId;
      }
    }
    return fallback;
  }
}
