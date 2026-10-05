import 'package:flutter_test/flutter_test.dart';
import 'package:riodent/config/environment.dart';

void main() {
  test('Environment resolves correctly based on dart-define', () {
    const envString = String.fromEnvironment('ENV', defaultValue: 'dev');
    final env = Environment.current;
    if (envString == 'staging') {
      expect(env, equals(Environment.staging));
      expect(env.firebaseProjectId, equals('riodent-staging'));
      expect(env.label, contains('Staging'));
      expect(env.firebaseOptions.projectId, equals('riodent-staging'));
    } else {
      expect(env, equals(Environment.dev));
      expect(env.firebaseProjectId, equals('equip-services-dev'));
      expect(env.label, contains('DEV'));
      expect(env.firebaseOptions.projectId, equals('equip-services-dev'));
    }
  });
}
