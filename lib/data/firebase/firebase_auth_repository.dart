import 'package:acad_mate/core/config/app_config.dart';
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
  }) : _auth = auth ?? FirebaseAuth.instance,
       _firestore = firestore ?? FirebaseFirestore.instance {
    // Eagerly initialize GoogleSignIn so it is ready before the user taps.
    _initGoogleSignInInBackground();
  }

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;
  bool _googleSignInInitialized = false;
  // Holds the in-flight or completed initialization future so concurrent
  // callers (e.g. tapping the button while init is still in progress) wait
  // on the same future instead of starting a second initialization.
  Future<void>? _googleSignInInitFuture;

  CollectionReference<Map<String, dynamic>> get _users =>
      _firestore.collection('users');

  @override
  Stream<AppUser?> authStateChanges() {
    return _auth.authStateChanges().asyncExpand((User? user) async* {
      if (user == null) {
        yield null;
        return;
      }

      // Step 1: Emit an immediate, fast representation of the user based on
      // data already available in the Firebase User object. This makes 
      // the app feel instant.
      yield _defaultAppUser(user);

      // Step 2: In the background, fetch the full profile from the backend.
      final AppUser? fullUser = await _mapFirebaseUser(user);
      if (fullUser != null) {
        yield fullUser;
      }
    });
  }

  @override
  Future<AppUser?> currentUser() async {
    final User? user = _auth.currentUser;
    if (user == null) {
      return null;
    }
    // We try to get the full mapping if possible, but keep it fast.
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
    // Note: OTP via backend is removed. Use Firebase auth methods.
    throw UnimplementedError('OTP via backend is no longer supported.');
  }

  @override
  Future<Map<String, dynamic>> submitQuizResult({
    required String quizId,
    required int score,
    required int total,
  }) async {
    final User? user = _auth.currentUser;
    if (user == null) {
      throw StateError('No authenticated user.');
    }

    // Compute streak from current Firestore data.
    final DocumentSnapshot<Map<String, dynamic>> snap =
        await _users.doc(user.uid).get();
    final Map<String, dynamic>? data = snap.data();
    final DateTime now = DateTime.now();
    int streakDays = (data?['streakDays'] as num?)?.toInt() ?? 0;
    final dynamic lastSeenRaw = data?['lastSeenAt'];
    DateTime? lastSeen;
    if (lastSeenRaw is Timestamp) {
      lastSeen = lastSeenRaw.toDate();
    }
    if (lastSeen == null) {
      streakDays = 1;
    } else {
      final int diffDays = now.difference(lastSeen).inDays;
      final bool sameDay =
          lastSeen.year == now.year &&
          lastSeen.month == now.month &&
          lastSeen.day == now.day;
      if (!sameDay) {
        streakDays = diffDays <= 1 ? streakDays + 1 : 1;
      }
    }

    final Map<String, dynamic> resultEntry = <String, dynamic>{
      'quizId': quizId,
      'score': score,
      'total': total,
      'completedAt': Timestamp.now(),
      'isPerfect': score == total,
    };

    await _users.doc(user.uid).set(<String, dynamic>{
      'completedQuestions': FieldValue.increment(score),
      'streakDays': streakDays,
      'lastSeenAt': FieldValue.serverTimestamp(),
      'quizResults': FieldValue.arrayUnion(<Map<String, dynamic>>[resultEntry]),
      if (score == total)
        'completedQuizIds': FieldValue.arrayUnion(<String>[quizId]),
    }, SetOptions(merge: true));
    return <String, dynamic>{
      'streakDays': streakDays,
      'completedQuestions': score,
      'quizResults': <Map<String, dynamic>>[resultEntry],
    };
  }

  @override
  Future<void> verifyOtp({
    required String email,
    required String code,
    required String type,
  }) async {
    throw UnimplementedError('OTP via backend is no longer supported.');
  }

  @override
  Future<void> resetPasswordWithOtp({
    required String email,
    required String code,
    required String newPassword,
  }) async {
    throw UnimplementedError('OTP via backend is no longer supported.');
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

  /// Kicks off GoogleSignIn initialization in the background immediately after
  /// the repository is constructed, so it is ready the moment the user taps.
  void _initGoogleSignInInBackground() {
    final String? serverClientId =
        defaultTargetPlatform == TargetPlatform.android
        ? null
        : AppConfig.googleServerClientId.trim().isEmpty
        ? null
        : AppConfig.googleServerClientId.trim();
    _googleSignInInitFuture = GoogleSignIn.instance
        .initialize(serverClientId: serverClientId)
        .then((_) {
          _googleSignInInitialized = true;
        })
        .catchError((_) {
          // Silently ignore — will retry in _ensureGoogleSignInInitialized.
        });
  }

  Future<void> _ensureGoogleSignInInitialized({String? serverClientId}) async {
    if (_googleSignInInitialized) {
      return;
    }
    // Await the in-flight init if it already started; otherwise start fresh.
    await (_googleSignInInitFuture ??=
        GoogleSignIn.instance.initialize(serverClientId: serverClientId).then(
          (_) => _googleSignInInitialized = true,
        ));
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
      'isFirebaseAccount': true,
    };

    await _syncProfileWithFirestore(user, payload);
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

    final DocumentReference<Map<String, dynamic>> docRef =
        _users.doc(user.uid);
    final DocumentSnapshot<Map<String, dynamic>> snap = await docRef.get();

    final Map<String, dynamic> data = <String, dynamic>{
      'firebaseUid': user.uid,
      ...payload,
      'linkedProviders': mergedLinkedProviders,
    };

    if (!snap.exists) {
      // New user — initialise stats to zero.
      data['streakDays'] = 0;
      data['completedQuestions'] = 0;
      data['bookmarkedPapers'] = 0;
      data['quizResults'] = <Map<String, dynamic>>[];
      data['completedQuizIds'] = <String>[];
      data['createdAt'] = FieldValue.serverTimestamp();
    }

    await docRef.set(data, SetOptions(merge: true));
  }

  Future<AppUser?> _mapFirebaseUser(User user) async {


    try {
      // Fallback or default path: read profile from Firestore.
      // We add a 3s timeout to keep the app snappy if Firestore is slow.
      final DocumentSnapshot<Map<String, dynamic>> snapshot = await _users
          .doc(user.uid)
          .get()
          .timeout(const Duration(seconds: 3));
      final Map<String, dynamic>? data = snapshot.data();
      if (data != null) {
        return _appUserFromMap(user, data);
      }
    } catch (_) {}

    return _defaultAppUser(user);
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
          final dynamic completedAtRaw = result['completedAt'];
          if (completedAtRaw is DateTime) {
            completedAt = completedAtRaw;
          } else if (completedAtRaw is Timestamp) {
            completedAt = completedAtRaw.toDate();
          } else {
            completedAt = DateTime.tryParse(completedAtRaw?.toString() ?? '') ??
                DateTime.fromMillisecondsSinceEpoch(0);
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
