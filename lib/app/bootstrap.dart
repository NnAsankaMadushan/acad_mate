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
        AppConfig.firebaseReady = true;
      } else if (!kIsWeb) {
        // Android can fall back to the native google-services.json config.
        await Firebase.initializeApp();
        AppConfig.firebaseReady = true;
      }
    } catch (_) {
      // Leave Firebase disabled and continue in the configured fallback mode.
    }
  }

  runApp(const ProviderScope(child: AcadMateApp()));
}
