import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart' show kIsWeb;
import '../firebase_options.dart';
import '../firebase_options_prod.dart';

/// Application environment configuration.
///
/// The active environment is determined at build time via:
/// ```
/// flutter run                         # Defaults to DEV (equip-services-dev)
/// flutter run --dart-define=ENV=dev   # Explicit DEV (equip-services-dev)
/// flutter run --dart-define=ENV=prod  # Production (riodent-prod)
/// ```
enum Environment {
  dev,
  prod;

  /// Resolves the current environment from the build-time dart-define.
  /// On web, dynamically detects riodent-prod domain when no explicit flag is set.
  static Environment get current {
    const envString = String.fromEnvironment('ENV', defaultValue: '');
    if (envString.isNotEmpty) {
      return Environment.values.firstWhere(
        (e) => e.name == envString.toLowerCase(),
        orElse: () => Environment.dev,
      );
    }
    if (kIsWeb) {
      final host = Uri.base.host.toLowerCase();
      if (host.contains('riodent-prod')) {
        return Environment.prod;
      }
    }
    return Environment.dev;
  }

  /// Human-readable label for display in debug UI or console.
  String get label {
    switch (this) {
      case Environment.dev:
        return 'Development (DEV)';
      case Environment.prod:
        return 'Production (PROD)';
    }
  }

  /// Returns the active Firebase project ID.
  String get firebaseProjectId {
    switch (this) {
      case Environment.dev:
        return 'equip-services-dev';
      case Environment.prod:
        return 'riodent-prod';
    }
  }

  /// Returns the corresponding FirebaseOptions for this environment.
  FirebaseOptions get firebaseOptions {
    switch (this) {
      case Environment.dev:
        return DefaultFirebaseOptions.currentPlatform;
      case Environment.prod:
        return ProdFirebaseOptions.currentPlatform;
    }
  }

  /// Whether this is a non-production environment.
  bool get isDebug => this != Environment.prod;

  /// Whether this is the DEV environment.
  bool get isDev => this == Environment.dev;

  /// Whether this is the PROD environment.
  bool get isProd => this == Environment.prod;
}
