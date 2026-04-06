import 'package:flutter/foundation.dart';

class AppConfig {
  static const String appName = 'AcadMate';
  static const String tagline = 'Learn smarter. Practice faster.';
  static const bool requestedFirebase = bool.fromEnvironment(
    'USE_FIREBASE',
    defaultValue: true,
  );
  static const bool requestedMongoBackend = bool.fromEnvironment(
    'USE_MONGO_BACKEND',
    defaultValue: true,
  );
  static final String mongoBackendBaseUrl = _resolveMongoBackendBaseUrl();
  static const String googleServerClientId = String.fromEnvironment(
    'GOOGLE_SERVER_CLIENT_ID',
  );

  static bool firebaseReady = false;

  static bool get mongoBackendReady =>
      requestedMongoBackend && mongoBackendBaseUrl.trim().isNotEmpty;

  static bool get useFirebase => requestedFirebase && firebaseReady;

  static bool get useMongoBackend =>
      requestedMongoBackend && firebaseReady && mongoBackendReady;

  static String _resolveMongoBackendBaseUrl() {
    const String envUrl = String.fromEnvironment('MONGO_BACKEND_BASE_URL');
    if (envUrl.trim().isNotEmpty) {
      return envUrl.trim().replaceFirst(RegExp(r'/$'), '');
    }

    if (kIsWeb) {
      return 'http://localhost:3000';
    }

    if (defaultTargetPlatform == TargetPlatform.android) {
      return 'http://192.168.1.156:3000';
    }

    return 'http://localhost:3000';
  }
}
