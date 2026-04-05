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
  static const String mongoBackendBaseUrl = String.fromEnvironment(
    'MONGO_BACKEND_BASE_URL',
    defaultValue: 'http://192.168.43.27:3000',
  );
  static const String googleServerClientId = String.fromEnvironment(
    'GOOGLE_SERVER_CLIENT_ID',
  );

  static bool firebaseReady = false;

  static bool get mongoBackendReady =>
      requestedMongoBackend && mongoBackendBaseUrl.trim().isNotEmpty;

  static bool get useFirebase => requestedFirebase && firebaseReady;

  static bool get useMongoBackend =>
      requestedMongoBackend && firebaseReady && mongoBackendReady;
}
