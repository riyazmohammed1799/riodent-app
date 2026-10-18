import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riodent/models/booking_config_model.dart';
import 'package:riodent/models/technician_model.dart';
import 'package:riodent/models/technician_request_model.dart';
import 'package:riodent/models/user_model.dart';
import 'package:riodent/providers/auth_providers.dart';
import 'package:riodent/providers/request_providers.dart';
import 'package:riodent/providers/settings_providers.dart';
import 'package:riodent/providers/technician_providers.dart';
import 'package:riodent/providers/user_providers.dart';
import 'package:riodent/screens/admin/dashboard_screen.dart';
import 'package:riodent/screens/auth/login_screen.dart';
import 'package:riodent/screens/dentist/book_technician_screen.dart';
import 'package:riodent/screens/dentist/home_screen.dart';
import 'package:riodent/screens/dentist/request_review_screen.dart';
import 'package:riodent/screens/profile/profile_screen.dart';
import 'package:riodent/theme/app_theme.dart';
import 'package:riodent/utils/constants.dart';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:riodent/repositories/auth_repository.dart';

class FakeAuthRepository extends Fake implements AuthRepository {
  @override
  Stream<User?> get authStateChanges => Stream.value(null);
  @override
  User? get currentUser => null;
}

void main() {
  const viewports = [
    Size(320, 568), // Compact: iPhone SE 1st gen / Small Android
    Size(360, 640), // Standard: Budget Android
    Size(412, 915), // High-res: Modern flagship
  ];

  final now = DateTime.now();

  final testUser = UserModel(
    uid: 'dr-test-uid',
    displayName: 'Dr. Ayesha Khan',
    email: 'ayesha@hyderabaddental.clinic',
    phone: '9876543210',
    clinicName: 'Ayesha Dental Care',
    clinicAddress: 'Road No 36, Jubilee Hills, Hyderabad',
    createdAt: now,
    updatedAt: now,
  );

  final testRequest = TechnicianRequestModel(
    id: 'req-001',
    ticketNumber: 'REQ-100234',
    dentistId: 'dr-test-uid',
    dentistName: 'Dr. Ayesha Khan',
    clinicName: 'Ayesha Dental Care',
    mobile: '9876543210',
    address: const RequestAddress(
      line: 'Road No 36, Jubilee Hills',
      area: 'Jubilee Hills',
      city: 'Hyderabad',
      pincode: '500033',
      lat: 17.4319,
      lng: 78.4073,
    ),
    issueCode: 'CHAIR',
    issueLabel: 'Dental Chair Unit',
    issueDescription: 'Compressor air leakage and foot control erratic',
    slotDate: '2026-10-15',
    slotKey: 'slot_9_12',
    slotStart: now.add(const Duration(hours: 4)),
    status: AppConstants.statusAssigned,
    assignedTechnicianId: 'tech-001',
    assignedTechnicianName: 'Ramesh Kumar',
    assignedTechnicianPhone: '9123456780',
    createdAt: now,
    updatedAt: now,
  );

  final testTechnician = TechnicianModel(
    id: 'tech-001',
    name: 'Ramesh Kumar',
    phone: '9123456780',
    area: 'Banjara Hills / Jubilee Hills',
    specialization: 'Dental Chairs & Compressors',
    isActive: true,
    createdAt: now,
    updatedAt: now,
  );

  final commonOverrides = [
    authRepositoryProvider.overrideWithValue(FakeAuthRepository()),
    currentUserIdProvider.overrideWith((ref) => 'dr-test-uid'),
    currentUserProfileProvider.overrideWith((ref) => Stream.value(testUser)),
    bookingConfigProvider.overrideWith((ref) => Stream.value(BookingConfigModel.defaultConfig())),
    dentistRequestsProvider.overrideWith((ref) => Stream.value([testRequest])),
    adminRequestsProvider.overrideWith((ref) => Stream.value([testRequest])),
    adminNeedsAttentionProvider.overrideWith((ref) => Future.value([testRequest])),
    adminStatusCountProvider(AppConstants.statusNew).overrideWith((ref) => Stream.value(0)),
    adminStatusCountProvider(AppConstants.statusAssigned).overrideWith((ref) => Stream.value(1)),
    adminStatusCountProvider(AppConstants.statusInProgress).overrideWith((ref) => Stream.value(0)),
    adminStatusCountProvider(AppConstants.statusCompleted).overrideWith((ref) => Stream.value(5)),
    adminStatusCountProvider(AppConstants.statusCancelled).overrideWith((ref) => Stream.value(1)),
    dentistCountProvider.overrideWith((ref) => Stream.value(12)),
    activeTechnicianCountProvider.overrideWith((ref) => Stream.value(3)),
    adminTotalRevenueProvider.overrideWith((ref) => Stream.value(14500.0)),
    registeredDentistsProvider.overrideWith((ref) => Stream.value([testUser])),
    techniciansProvider.overrideWith((ref) => Stream.value([testTechnician])),
  ];

  Widget buildTestApp(Widget child) {
    return ProviderScope(
      overrides: commonOverrides,
      child: MaterialApp(
        theme: AppTheme.lightTheme,
        home: child,
      ),
    );
  }

  group('UI Zero-Overflow Viewport Suite (QA Issue I12 / GEN-01 to GEN-10)', () {
    for (final size in viewports) {
      testWidgets('LoginScreen renders with zero overflow at ${size.width}x${size.height}', (tester) async {
        tester.view.physicalSize = Size(size.width * 2, size.height * 2);
        tester.view.devicePixelRatio = 2.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        await tester.pumpWidget(buildTestApp(const LoginScreen()));
        await tester.pump();

        expect(tester.takeException(), isNull);
        expect(find.text(AppConstants.appName), findsOneWidget);
      });

      testWidgets('DentistHomeScreen renders with zero overflow at ${size.width}x${size.height}', (tester) async {
        tester.view.physicalSize = Size(size.width * 2, size.height * 2);
        tester.view.devicePixelRatio = 2.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        await tester.pumpWidget(buildTestApp(const DentistHomeScreen()));
        await tester.pump();

        expect(tester.takeException(), isNull);
        expect(find.text('Ayesha Dental Care'), findsOneWidget);
      });

      testWidgets('BookTechnicianScreen renders with zero overflow at ${size.width}x${size.height}', (tester) async {
        tester.view.physicalSize = Size(size.width * 2, size.height * 2);
        tester.view.devicePixelRatio = 2.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        await tester.pumpWidget(buildTestApp(const BookTechnicianScreen()));
        await tester.pump();

        expect(tester.takeException(), isNull);
        expect(find.text('Book Technician'), findsOneWidget);
      });

      testWidgets('RequestReviewScreen renders with zero overflow at ${size.width}x${size.height}', (tester) async {
        tester.view.physicalSize = Size(size.width * 2, size.height * 2);
        tester.view.devicePixelRatio = 2.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        final reviewData = {
          'dentistId': 'dr-test-uid',
          'dentistName': 'Dr. Ayesha Khan',
          'clinicName': 'Ayesha Dental Care',
          'mobile': '9876543210',
          'addressLine': 'Road No 36, Jubilee Hills',
          'area': 'Jubilee Hills',
          'city': 'Hyderabad',
          'pincode': '500033',
          'issueCode': 'CHAIR',
          'issueLabel': 'Dental Chair Unit',
          'issueDescription': 'Compressor air leakage and foot control erratic',
          'slotDate': '2026-10-15',
          'slotKey': 'slot_9_12',
          'slotLabel': 'Morning (09:00 - 12:00)',
          'slotStart': now.add(const Duration(hours: 4)),
        };

        await tester.pumpWidget(buildTestApp(RequestReviewScreen(requestData: reviewData)));
        await tester.pump();

        expect(tester.takeException(), isNull);
        expect(find.text('Review Booking'), findsOneWidget);
      });

      testWidgets('AdminDashboardScreen renders with zero overflow at ${size.width}x${size.height}', (tester) async {
        tester.view.physicalSize = Size(size.width * 2, size.height * 2);
        tester.view.devicePixelRatio = 2.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        await tester.pumpWidget(buildTestApp(const AdminDashboardScreen()));
        await tester.pump();

        expect(tester.takeException(), isNull);
        expect(find.text('Executive Overview'), findsOneWidget);
      });

      testWidgets('ProfileScreen renders with zero overflow at ${size.width}x${size.height}', (tester) async {
        tester.view.physicalSize = Size(size.width * 2, size.height * 2);
        tester.view.devicePixelRatio = 2.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        await tester.pumpWidget(buildTestApp(const ProfileScreen()));
        await tester.pump();

        expect(tester.takeException(), isNull);
        expect(find.text('Clinic Profile'), findsOneWidget);
      });
    }
  });
}
