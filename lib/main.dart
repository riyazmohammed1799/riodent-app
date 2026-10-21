import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'config/environment.dart';
import 'services/fcm_service.dart';

/// Application entry point.
///
/// Firebase is initialized according to the target environment:
///   flutter run                             → Development (equip-services-dev) [DEFAULT]
///   flutter run --dart-define=ENV=dev       → Development (equip-services-dev)
///   flutter run --dart-define=ENV=prod      → Production (PROD)
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final env = Environment.current;
  await Firebase.initializeApp(
    options: env.firebaseOptions,
  );

  // High performance: Enable Firestore offline cache persistence on mobile
  // Web uses native browser caching managed cleanly by the Firebase Web SDK
  if (!kIsWeb) {
    FirebaseFirestore.instance.settings = const Settings(
      persistenceEnabled: true,
      cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
    );
  }

  debugPrint('🚀 RioDent started in [${env.label}] mode -> Project: ${env.firebaseProjectId}');

  // Non-blocking FCM push notification initialization:
  // Runs in the background without blocking initial app render and UI interactivity
  unawaited(FcmService.initialize());

  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
    debugPrint('🚨 UNCAUGHT FLUTTER ERROR: ${details.exceptionAsString()}\n${details.stack}');
  };

  ErrorWidget.builder = (FlutterErrorDetails details) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Render Error Caught'),
        backgroundColor: Colors.red.shade800,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Text(
          'ERROR: ${details.exceptionAsString()}\n\nSTACK TRACE:\n${details.stack}',
          style: const TextStyle(color: Colors.red, fontSize: 13, fontFamily: 'monospace'),
        ),
      ),
    );
  };

  runApp(
    const ProviderScope(
      child: RioDentApp(),
    ),
  );
}

