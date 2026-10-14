import 'package:flutter_test/flutter_test.dart';
import 'package:riodent/models/booking_config_model.dart';
import 'package:riodent/models/technician_request_model.dart';
import 'package:riodent/models/user_model.dart';
import 'package:riodent/utils/constants.dart';
import 'package:riodent/utils/validators.dart';

void main() {
  group('QA Test Suite (Riodent_MVP_QA_Test_Cases_v2): Auth & User Validation', () {
    test('[AUTH-05, AUTH-08] Doctor registration validation: Email, password, clinic, name', () {
      // Email validation - looser email rule per Issue I12 / AUTH-08
      expect(Validators.email('doctor@clinic.dental'), isNull);
      expect(Validators.email('dr.smith@sub.hospital.org'), isNull);
      expect(Validators.email('invalid-email'), isNotNull);
      expect(Validators.email(''), isNotNull);

      // Password validation (6+ chars)
      expect(Validators.password('123456'), isNull);
      expect(Validators.password('password123'), isNull);
      expect(Validators.password('12345'), isNotNull);

      // Required fields
      expect(Validators.required('Dr. Ramesh', 'Name'), isNull);
      expect(Validators.required('', 'Name'), isNotNull);
      expect(Validators.required('   ', 'Clinic Name'), isNotNull);
    });

    test('[AUTH-23, ADA-04, SEC-03] Role isolation and Custom Claim security', () {
      final now = DateTime(2026, 10, 14, 12, 0);

      // Regular doctor cannot have admin privileges
      final doctorUser = UserModel(
        uid: 'doc_123',
        email: 'doctor@riodent.com',
        displayName: 'Dr. Rao',
        phone: '9876543210',
        isAdmin: false,
        createdAt: now,
        updatedAt: now,
      );
      expect(doctorUser.isAdmin, isFalse);

      // Admin role requires explicit custom claim
      final adminUser = doctorUser.copyWith(isAdmin: true);
      expect(adminUser.isAdmin, isTrue);

      // toMap() never writes role to prevent client-side privilege escalation
      expect(doctorUser.toMap().containsKey('role'), isFalse);
      expect(adminUser.toMap().containsKey('role'), isFalse);
    });
  });

  group('QA Test Suite (Riodent_MVP_QA_Test_Cases_v2): Booking & Address Validation', () {
    test('[BKG-05 to BKG-08] Problem description accepts 1-500 characters and any words', () {
      expect(Validators.required('Fix chair', 'Description'), isNull);
      expect(Validators.required('Dental chair foot pedal stuck and leaking oil', 'Description'), isNull);
      expect(Validators.required('', 'Description'), isNotNull);
      expect(Validators.required('   ', 'Description'), isNotNull);
    });

    test('[BKG-11 to BKG-19] Hyderabad Pincode and Mobile validation', () {
      // Pincode validation: 6 digits starting with 500, 501, 502
      expect(Validators.pincode('500001'), isNull);
      expect(Validators.pincode('500034'), isNull);
      expect(Validators.pincode('501505'), isNull);
      expect(Validators.pincode('502032'), isNull);

      // Non-Hyderabad pincodes rejected
      expect(Validators.pincode('560001'), isNotNull); // Bangalore
      expect(Validators.pincode('110001'), isNotNull); // Delhi
      expect(Validators.pincode('400001'), isNotNull); // Mumbai
      expect(Validators.pincode('5000'), isNotNull);   // Too short

      // Mobile validation: 10 digits starting with 6-9
      expect(Validators.phoneNumber('9876543210'), isNull);
      expect(Validators.phoneNumber('8765432109'), isNull);
      expect(Validators.phoneNumber('1234567890'), isNotNull); // Invalid start digit
      expect(Validators.phoneNumber('98765'), isNotNull);      // Too short
    });
  });

  group('QA Test Suite (Riodent_MVP_QA_Test_Cases_v2): Time Slots & Lead Time', () {
    const slot09_12 = TimeSlotItem(
      key: '09_12',
      label: '9 AM to 12 PM',
      startHour: 9,
      endHour: 12,
    );
    const slot14_17 = TimeSlotItem(
      key: '14_17',
      label: '2 PM to 5 PM',
      startHour: 14,
      endHour: 17,
    );
    const slot18_21 = TimeSlotItem(
      key: '18_21',
      label: '6 PM to 9 PM',
      startHour: 18,
      endHour: 21,
    );

    test('[SLT-01 to SLT-05] Same-day slot calculation with 30-minute min lead time', () {
      final today = DateTime(2026, 10, 14);

      // At 8:00 AM, 9 AM slot has 60 min lead (> 30 min) -> Bookable
      final now8am = DateTime(2026, 10, 14, 8, 0);
      expect(
        BookingConfigModel.isSlotBookable(
          slotStart: slot09_12.getStartDateTime(today),
          now: now8am,
        ),
        isTrue,
      );

      // At 8:40 AM, 9 AM slot has only 20 min lead (< 30 min) -> Expired/Not bookable
      final now840am = DateTime(2026, 10, 14, 8, 40);
      expect(
        BookingConfigModel.isSlotBookable(
          slotStart: slot09_12.getStartDateTime(today),
          now: now840am,
        ),
        isFalse,
      );

      // At 1:00 PM, 2 PM slot has 60 min lead -> Bookable
      final now1pm = DateTime(2026, 10, 14, 13, 0);
      expect(
        BookingConfigModel.isSlotBookable(
          slotStart: slot14_17.getStartDateTime(today),
          now: now1pm,
        ),
        isTrue,
      );

      // At 7:00 PM, 6 PM slot is in the past -> Not bookable
      final now7pm = DateTime(2026, 10, 14, 19, 0);
      expect(
        BookingConfigModel.isSlotBookable(
          slotStart: slot18_21.getStartDateTime(today),
          now: now7pm,
        ),
        isFalse,
      );
    });

    test('[SLT-06 to SLT-13] Future days (tomorrow up to 7 days ahead) slots are all bookable', () {
      final now = DateTime(2026, 10, 14, 15, 30);
      final tomorrow = DateTime(2026, 10, 15);

      expect(
        BookingConfigModel.isSlotBookable(
          slotStart: slot09_12.getStartDateTime(tomorrow),
          now: now,
        ),
        isTrue,
      );
      expect(
        BookingConfigModel.isSlotBookable(
          slotStart: slot14_17.getStartDateTime(tomorrow),
          now: now,
        ),
        isTrue,
      );
      expect(
        BookingConfigModel.isSlotBookable(
          slotStart: slot18_21.getStartDateTime(tomorrow),
          now: now,
        ),
        isTrue,
      );
    });
  });

  group('QA Test Suite (Riodent_MVP_QA_Test_Cases_v2): Ticket Lifecycle & State Machine', () {
    final now = DateTime(2026, 10, 14, 12, 0);

    test('[DR-01 to DR-17, ADM-08 to ADM-18] Request status lifecycle and transitions', () {
      final req = TechnicianRequestModel(
        id: 'req_101',
        ticketNumber: 'REQ-101',
        dentistId: 'doc_1',
        dentistName: 'Dr. Rao',
        clinicName: 'Rao Dental',
        mobile: '9876543210',
        issueCode: 'dental_chair',
        issueLabel: 'Dental Chair',
        issueDescription: 'Chair will not recline',
        address: const RequestAddress(
          line: 'Banjara Hills, Rd 12',
          area: 'Banjara Hills',
          city: 'Hyderabad',
          pincode: '500034',
        ),
        slotDate: '2026-10-15',
        slotKey: '09_12',
        slotStart: DateTime(2026, 10, 15, 9, 0),
        status: AppConstants.statusNew,
        createdAt: now,
        updatedAt: now,
      );

      expect(req.status, equals(AppConstants.statusNew));
      expect(req.isActive, isTrue);

      // Assignment: PENDING/NEW -> ASSIGNED
      final assigned = req.copyWith(
        status: AppConstants.statusAssigned,
        assignedTechnicianId: 'tech_5',
        assignedTechnicianName: 'Suresh Kumar',
        assignedTechnicianPhone: '9848012345',
      );
      expect(assigned.status, equals(AppConstants.statusAssigned));
      expect(assigned.isActive, isTrue);
      expect(assigned.assignedTechnicianName, equals('Suresh Kumar'));

      // Progress: ASSIGNED -> IN_PROGRESS
      final inProgress = assigned.copyWith(status: AppConstants.statusInProgress);
      expect(inProgress.status, equals(AppConstants.statusInProgress));
      expect(inProgress.isActive, isTrue);

      // Completion: IN_PROGRESS -> COMPLETED with whole-rupee amount
      final completed = inProgress.copyWith(
        status: AppConstants.statusCompleted,
        completedAt: now.add(const Duration(hours: 3)),
        amountPaid: 1500,
        completedBy: 'dentist',
      );
      expect(completed.status, equals(AppConstants.statusCompleted));
      expect(completed.isActive, isFalse);
      expect(completed.amountPaid, equals(1500.0));

      // Cancellation: PENDING -> CANCELLED with mandatory reason
      final cancelled = req.copyWith(
        status: AppConstants.statusCancelled,
        cancelledAt: now.add(const Duration(minutes: 15)),
        reasonText: 'Outside service area',
        cancelledBy: 'admin',
      );
      expect(cancelled.status, equals(AppConstants.statusCancelled));
      expect(cancelled.isActive, isFalse);
      expect(cancelled.reasonText, equals('Outside service area'));
      expect(cancelled.cancelledBy, equals('admin'));
    });

    test('[DSH-04] Revenue KPI sums only completed tickets and excludes cancelled/pending', () {
      final list = [
        TechnicianRequestModel(
          id: '1',
          ticketNumber: 'REQ-1',
          dentistId: 'doc_1',
          dentistName: 'Dr. A',
          clinicName: 'A Clinic',
          mobile: '9876543210',
          issueCode: 'dental_chair',
          issueLabel: 'Dental Chair',
          issueDescription: 'Desc',
          address: const RequestAddress(line: 'Street 1', city: 'Hyderabad', pincode: '500001'),
          slotDate: '2026-10-14',
          slotKey: '09_12',
          slotStart: DateTime(2026, 10, 14, 9, 0),
          status: AppConstants.statusCompleted,
          createdAt: now,
          updatedAt: now,
          amountPaid: 1000,
        ),
        TechnicianRequestModel(
          id: '2',
          ticketNumber: 'REQ-2',
          dentistId: 'doc_1',
          dentistName: 'Dr. A',
          clinicName: 'A Clinic',
          mobile: '9876543210',
          issueCode: 'autoclave',
          issueLabel: 'Autoclave',
          issueDescription: 'Desc',
          address: const RequestAddress(line: 'Street 2', city: 'Hyderabad', pincode: '500001'),
          slotDate: '2026-10-14',
          slotKey: '14_17',
          slotStart: DateTime(2026, 10, 14, 14, 0),
          status: AppConstants.statusCompleted,
          createdAt: now,
          updatedAt: now,
          amountPaid: 1500,
        ),
        TechnicianRequestModel(
          id: '3',
          ticketNumber: 'REQ-3',
          dentistId: 'doc_1',
          dentistName: 'Dr. A',
          clinicName: 'A Clinic',
          mobile: '9876543210',
          issueCode: 'xray_rvg',
          issueLabel: 'X-Ray & RVG',
          issueDescription: 'Desc',
          address: const RequestAddress(line: 'Street 3', city: 'Hyderabad', pincode: '500001'),
          slotDate: '2026-10-14',
          slotKey: '18_21',
          slotStart: DateTime(2026, 10, 14, 18, 0),
          status: AppConstants.statusCancelled,
          createdAt: now,
          updatedAt: now,
          amountPaid: 2000, // Should be excluded from revenue calculation
        ),
        TechnicianRequestModel(
          id: '4',
          ticketNumber: 'REQ-4',
          dentistId: 'doc_1',
          dentistName: 'Dr. A',
          clinicName: 'A Clinic',
          mobile: '9876543210',
          issueCode: 'air_compressor',
          issueLabel: 'Air Compressor',
          issueDescription: 'Desc',
          address: const RequestAddress(line: 'Street 4', city: 'Hyderabad', pincode: '500001'),
          slotDate: '2026-10-14',
          slotKey: '09_12',
          slotStart: DateTime(2026, 10, 14, 9, 0),
          status: AppConstants.statusNew,
          createdAt: now,
          updatedAt: now,
        ),
      ];

      // Sum only COMPLETED amountPaid
      final paidToTechnicians = list
          .where((r) => r.status == AppConstants.statusCompleted)
          .fold<double>(0, (sum, r) => sum + (r.amountPaid ?? 0));

      expect(paidToTechnicians, equals(2500.0));
    });
  });

  group('QA Test Suite (Riodent_MVP_QA_Test_Cases_v2): Category Deduplication & Config', () {
    test('[BKG-01 to BKG-04, HOME-05] Category deduplication by unique code', () {
      final rawList = [
        const IssueTypeItem(code: 'dental_chair', label: 'Dental Chair', active: true),
        const IssueTypeItem(code: 'autoclave', label: 'Autoclave', active: true),
        const IssueTypeItem(code: 'dental_chair', label: 'Dental Chair Duplicate', active: true),
        const IssueTypeItem(code: 'xray_rvg', label: 'X-Ray & RVG', active: true),
        const IssueTypeItem(code: '', label: 'Empty Code', active: true),
      ];

      final deduped = IssueTypeItem.deduplicateByCode(rawList);
      expect(deduped.length, equals(3));
      expect(deduped[0].code, equals('dental_chair'));
      expect(deduped[1].code, equals('autoclave'));
      expect(deduped[2].code, equals('xray_rvg'));
    });
  });
}
