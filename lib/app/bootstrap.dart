import 'package:acad_mate/app/app.dart';
import 'package:acad_mate/core/config/app_config.dart';
import 'package:acad_mate/firebase_options.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

Future<void> bootstrap() async {
  WidgetsFlutterBinding.ensureInitialized();

  await SystemChrome.setPreferredOrientations(<DeviceOrientation>[
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  if (AppConfig.requestedFirebase) {
    final FirebaseOptions? options = DefaultFirebaseOptions.currentPlatform;
    try {
      if (options != null) {
        await Firebase.initializeApp(options: options);
      } else if (!kIsWeb) {
        // Android can fall back to the native google-services.json config.
        await Firebase.initializeApp();
      } else {
        throw StateError(
          'Firebase configuration not available. Running AcadMate in demo mode.',
        );
      }
      AppConfig.firebaseReady = true;
    } catch (error, stackTrace) {
      debugPrint('Firebase initialization failed, using demo mode.');
      debugPrint('$error');
      debugPrint('$stackTrace');
    }
  }

  runApp(
    const ProviderScope(
      child: AcadMateApp(),
    ),
  );
}

