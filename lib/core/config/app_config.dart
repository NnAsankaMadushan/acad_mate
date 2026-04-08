import 'package:flutter/foundation.dart';

class AppConfig {
  static const String appName = 'AcadMate';
  static const String tagline = 'Learn smarter. Practice faster.';
  static const bool requestedFirebase = bool.fromEnvironment(
    'USE_FIREBASE',
    defaultValue: true,
  );
  
  static const String googleServerClientId = String.fromEnvironment(
    'GOOGLE_SERVER_CLIENT_ID',
  );

  static bool firebaseReady = false;

  static bool get useFirebase => requestedFirebase && firebaseReady;

  // We are now only using Firebase.
  static const bool useMongoBackend = false;
}
