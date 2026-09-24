/// Application environment configuration.
///
/// The active environment is determined at build time via:
/// ```
/// flutter run --dart-define=ENV=dev
/// flutter run --dart-define=ENV=staging
/// flutter run --dart-define=ENV=prod
/// ```
enum Environment {
  dev,
  staging,
  prod;

  /// Resolves the current environment from the build-time dart-define.
  static Environment get current {
    const envString = String.fromEnvironment('ENV', defaultValue: 'dev');
    return Environment.values.firstWhere(
      (e) => e.name == envString,
      orElse: () => Environment.dev,
    );
  }

  /// Human-readable label for display in debug UI.
  String get label {
    switch (this) {
      case Environment.dev:
        return 'Development';
      case Environment.staging:
        return 'Staging';
      case Environment.prod:
        return 'Production';
    }
  }

  /// Whether this is a non-production environment.
  bool get isDebug => this != Environment.prod;
}
