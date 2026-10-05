import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:riodent/config/environment.dart';
import 'package:riodent/widgets/staging_indicator.dart';

void main() {
  group('Environment enum unit tests', () {
    test('Environment properties for DEV', () {
      const env = Environment.dev;
      expect(env.isDev, isTrue);
      expect(env.isStaging, isFalse);
      expect(env.isProd, isFalse);
      expect(env.isDebug, isTrue);
      expect(env.firebaseProjectId, equals('equip-services-dev'));
      expect(env.label, contains('DEV'));
      expect(env.firebaseOptions.projectId, equals('equip-services-dev'));
    });

    test('Environment properties for STAGING', () {
      const env = Environment.staging;
      expect(env.isStaging, isTrue);
      expect(env.isDev, isFalse);
      expect(env.isProd, isFalse);
      expect(env.isDebug, isTrue);
      expect(env.firebaseProjectId, equals('riodent-staging'));
      expect(env.label, contains('Staging'));
      expect(env.firebaseOptions.projectId, equals('riodent-staging'));
    });

    test('Environment properties for PROD', () {
      const env = Environment.prod;
      expect(env.isProd, isTrue);
      expect(env.isDev, isFalse);
      expect(env.isStaging, isFalse);
      expect(env.isDebug, isFalse);
      expect(env.firebaseProjectId, equals('equip-services-dev'));
      expect(env.label, contains('PROD'));
    });

    test('Environment.current resolves correctly based on dart-define', () {
      const envString = String.fromEnvironment('ENV', defaultValue: 'dev');
      final env = Environment.current;
      if (envString == 'staging') {
        expect(env, equals(Environment.staging));
        expect(env.isStaging, isTrue);
        expect(env.firebaseProjectId, equals('riodent-staging'));
      } else {
        expect(env, equals(Environment.dev));
        expect(env.isDev, isTrue);
        expect(env.firebaseProjectId, equals('equip-services-dev'));
      }
    });
  });

  group('StagingIndicatorOverlay widget tests', () {
    testWidgets('Renders BETA / STAGING badge when environment is STAGING', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: StagingIndicatorOverlay(
            environment: Environment.staging,
            child: Scaffold(
              body: Center(child: Text('Main Content')),
            ),
          ),
        ),
      );

      expect(find.text('Main Content'), findsOneWidget);
      expect(find.text('BETA / STAGING'), findsOneWidget);
      expect(find.byIcon(Icons.science_rounded), findsOneWidget);

      // Verify IgnorePointer wraps the badge so it does not block user interaction
      final ignorePointer = tester.widget<IgnorePointer>(
        find.descendant(
          of: find.byType(Positioned),
          matching: find.byType(IgnorePointer),
        ),
      );
      expect(ignorePointer.ignoring, isTrue);
    });

    testWidgets('Does NOT render badge when environment is DEV', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: StagingIndicatorOverlay(
            environment: Environment.dev,
            child: Scaffold(
              body: Center(child: Text('Main Content')),
            ),
          ),
        ),
      );

      expect(find.text('Main Content'), findsOneWidget);
      expect(find.text('BETA / STAGING'), findsNothing);
      expect(find.byIcon(Icons.science_rounded), findsNothing);
    });

    testWidgets('Does NOT render badge when environment is PROD', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: StagingIndicatorOverlay(
            environment: Environment.prod,
            child: Scaffold(
              body: Center(child: Text('Main Content')),
            ),
          ),
        ),
      );

      expect(find.text('Main Content'), findsOneWidget);
      expect(find.text('BETA / STAGING'), findsNothing);
      expect(find.byIcon(Icons.science_rounded), findsNothing);
    });
  });
}
