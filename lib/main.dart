import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'config/environment.dart';

/// Application entry point.
///
/// Firebase is initialized according to the target environment:
///   flutter run                             → Development (equip-services-dev) [DEFAULT]
///   flutter run --dart-define=ENV=dev       → Development (equip-services-dev)
///   flutter run --dart-define=ENV=staging   → Staging (riodent-staging)
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final env = Environment.current;
  await Firebase.initializeApp(
    options: env.firebaseOptions,
  );

  debugPrint('🚀 RioDent started in [${env.label}] mode -> Project: ${env.firebaseProjectId}');

  runApp(
    const ProviderScope(
      child: RioDentApp(),
    ),
  );
}

