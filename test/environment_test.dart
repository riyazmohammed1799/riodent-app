import 'package:flutter_test/flutter_test.dart';
import 'package:riodent/config/environment.dart';

void main() {
  group('Environment enum unit tests', () {
    test('Environment properties for DEV', () {
      const env = Environment.dev;
      expect(env.isDev, isTrue);
      expect(env.isProd, isFalse);
      expect(env.isDebug, isTrue);
      expect(env.firebaseProjectId, equals('equip-services-dev'));
      expect(env.label, contains('DEV'));
      expect(env.firebaseOptions.projectId, equals('equip-services-dev'));
    });

    test('Environment properties for PROD', () {
      const env = Environment.prod;
      expect(env.isProd, isTrue);
      expect(env.isDev, isFalse);
      expect(env.isDebug, isFalse);
      expect(env.firebaseProjectId, equals('equip-services-dev'));
      expect(env.label, contains('PROD'));
      expect(env.firebaseOptions.projectId, equals('equip-services-dev'));
    });

    test('Environment.current resolves correctly based on dart-define', () {
      const envString = String.fromEnvironment('ENV', defaultValue: 'dev');
      final env = Environment.current;
      if (envString == 'prod') {
        expect(env, equals(Environment.prod));
        expect(env.isProd, isTrue);
      } else {
        expect(env, equals(Environment.dev));
        expect(env.isDev, isTrue);
        expect(env.firebaseProjectId, equals('equip-services-dev'));
      }
    });
  });
}
