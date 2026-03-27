import 'package:firebase_core/firebase_core.dart';

class DefaultFirebaseOptions {
  static FirebaseOptions? get currentPlatform {
    const String apiKey = String.fromEnvironment('FIREBASE_API_KEY');
    const String appId = String.fromEnvironment('FIREBASE_APP_ID');
    const String messagingSenderId =
        String.fromEnvironment('FIREBASE_MESSAGING_SENDER_ID');
    const String projectId = String.fromEnvironment('FIREBASE_PROJECT_ID');
    const String storageBucket =
        String.fromEnvironment('FIREBASE_STORAGE_BUCKET');
    const String authDomain = String.fromEnvironment('FIREBASE_AUTH_DOMAIN');

    if (apiKey.isEmpty ||
        appId.isEmpty ||
        messagingSenderId.isEmpty ||
        projectId.isEmpty) {
      return null;
    }

    return FirebaseOptions(
      apiKey: apiKey,
      appId: appId,
      messagingSenderId: messagingSenderId,
      projectId: projectId,
      storageBucket: storageBucket.isEmpty ? null : storageBucket,
      authDomain: authDomain.isEmpty ? null : authDomain,
    );
  }
}

