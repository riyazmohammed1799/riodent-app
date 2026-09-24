import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';

/// Application entry point.
///
/// Firebase initialization will be added here once Firebase projects
/// are configured. The environment is determined by --dart-define=ENV.
///
/// Usage:
///   flutter run                         → Development
///   flutter run --dart-define=ENV=staging → Staging
///   flutter run --dart-define=ENV=prod    → Production
void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // TODO: Initialize Firebase based on Environment.current
  // await Firebase.initializeApp(
  //   options: _getFirebaseOptions(),
  // );

  runApp(
    const ProviderScope(
      child: RioDentApp(),
    ),
  );
}
