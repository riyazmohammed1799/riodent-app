import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import '../firebase_options.dart';

/// Application environment configuration.
///
/// The active environment is determined at build time via:
/// ```
/// flutter run                         # Defaults to DEV (equip-services-dev)
/// flutter run --dart-define=ENV=dev   # Explicit DEV (equip-services-dev)
/// flutter run --dart-define=ENV=prod  # Production (PROD)
/// ```
enum Environment {
  dev,
  prod;

  /// Resolves the current environment from the build-time dart-define.
  /// Defaults to [Environment.dev] if not specified.
  static Environment get current {
    const envString = String.fromEnvironment('ENV', defaultValue: 'dev');
    return Environment.values.firstWhere(
      (e) => e.name == envString.toLowerCase(),
      orElse: () => Environment.dev,
    );
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
        // Future production Firebase project; defaults to equip-services-dev
        return 'equip-services-dev';
    }
  }

  /// Returns the corresponding FirebaseOptions for this environment.
  FirebaseOptions get firebaseOptions {
    switch (this) {
      case Environment.dev:
      case Environment.prod:
        return DefaultFirebaseOptions.currentPlatform;
    }
  }

  /// Whether this is a non-production environment.
  bool get isDebug => this != Environment.prod;

  /// Whether this is the DEV environment.
  bool get isDev => this == Environment.dev;

  /// Whether this is the PROD environment.
  bool get isProd => this == Environment.prod;
}
