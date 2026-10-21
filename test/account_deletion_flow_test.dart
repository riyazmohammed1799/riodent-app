import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riodent/models/booking_config_model.dart';
import 'package:riodent/models/user_model.dart';
import 'package:riodent/providers/auth_providers.dart';
import 'package:riodent/providers/request_providers.dart';
import 'package:riodent/providers/settings_providers.dart';
import 'package:riodent/repositories/auth_repository.dart';
import 'package:riodent/screens/dentist/home_screen.dart';
import 'package:riodent/screens/profile/profile_screen.dart';
import 'package:riodent/theme/app_theme.dart';
import 'package:firebase_auth/firebase_auth.dart';

class MockAuthRepository extends Fake implements AuthRepository {
  @override
  Stream<User?> get authStateChanges => Stream.value(null);
  @override
  User? get currentUser => null;
  @override
  Future<void> signOut() async {}
  @override
  Future<void> deleteAccount() async {}
}

void main() {
  group('Account Deletion & Sign-Out Navigation Guards', () {
    testWidgets('DentistHomeScreen guards against deleted/null profile by redirecting to /login', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authRepositoryProvider.overrideWithValue(MockAuthRepository()),
            currentUserProfileProvider.overrideWith((ref) => Stream.value(null)),
            bookingConfigProvider.overrideWith((ref) => Stream.value(BookingConfigModel.defaultConfig())),
            dentistRequestsProvider.overrideWith((ref) => Stream.value([])),
          ],
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: const DentistHomeScreen(),
          ),
        ),
      );

      await tester.pump();

      // Guard should render progress indicator and NOT render doctor's dashboard
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Active Requests'), findsNothing);
      expect(find.text('Emergency Service'), findsNothing);
    });

    testWidgets('ProfileScreen guards against deleted/null profile by showing redirecting state', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authRepositoryProvider.overrideWithValue(MockAuthRepository()),
            currentUserProfileProvider.overrideWith((ref) => Stream.value(null)),
            bookingConfigProvider.overrideWith((ref) => Stream.value(BookingConfigModel.defaultConfig())),
            dentistRequestsProvider.overrideWith((ref) => Stream.value([])),
          ],
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: const ProfileScreen(),
          ),
        ),
      );

      await tester.pump();

      // Should show progress indicator while redirecting, not the clinic profile edit fields
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Save Profile'), findsNothing);
      expect(find.text('Delete RioDent Account'), findsNothing);
    });
  });
}
