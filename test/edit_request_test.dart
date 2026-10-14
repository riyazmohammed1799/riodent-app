import 'package:flutter_test/flutter_test.dart';
import 'package:riodent/models/booking_config_model.dart';
import 'package:riodent/models/technician_request_model.dart';
import 'package:riodent/utils/constants.dart';

void main() {
  group('Doctor Edit Request Logic (Wrong Issue or Wrong Time Slot)', () {
    final now = DateTime(2026, 10, 14, 12, 0);

    final initialRequest = TechnicianRequestModel(
      id: 'req_edit_01',
      ticketNumber: 'REQ-5512',
      dentistId: 'dentist_01',
      dentistName: 'Dr. John',
      clinicName: 'Smile Care',
      mobile: '9876543210',
      issueCode: 'dental_chair',
      issueLabel: 'Dental Chair',
      issueDescription: 'Chair not moving up/down',
      address: const RequestAddress(
        line: 'Road 12',
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

    test('Doctor can edit details while ticket is in NEW status', () {
      expect(initialRequest.isNew, isTrue);

      // Doctor changes issue to Autoclave and preferred slot to 2 PM to 5 PM
      final updated = initialRequest.copyWith(
        issueCode: 'autoclave',
        issueLabel: 'Autoclave',
        issueDescription: 'Pressure valve leak during cycle',
        slotDate: '2026-10-16',
        slotKey: '14_17',
        slotStart: DateTime(2026, 10, 16, 14, 0),
        updatedAt: now.add(const Duration(minutes: 5)),
      );

      expect(updated.issueCode, equals('autoclave'));
      expect(updated.issueLabel, equals('Autoclave'));
      expect(updated.issueDescription, equals('Pressure valve leak during cycle'));
      expect(updated.slotDate, equals('2026-10-16'));
      expect(updated.slotKey, equals('14_17'));
      expect(updated.status, equals(AppConstants.statusNew));
      expect(updated.isActive, isTrue);
    });

    test('Doctor can edit details while ticket is in ASSIGNED status (before technician starts)', () {
      final assigned = initialRequest.copyWith(
        status: AppConstants.statusAssigned,
        assignedTechnicianId: 'tech_1',
        assignedTechnicianName: 'Rajesh Sharma',
        assignedTechnicianPhone: '9848011223',
      );

      expect(assigned.isAssigned, isTrue);

      // Doctor updates slot
      final updatedSlot = assigned.copyWith(
        slotDate: '2026-10-17',
        slotKey: '18_21',
        slotStart: DateTime(2026, 10, 17, 18, 0),
        updatedAt: now.add(const Duration(minutes: 10)),
      );

      expect(updatedSlot.slotDate, equals('2026-10-17'));
      expect(updatedSlot.slotKey, equals('18_21'));
      expect(updatedSlot.assignedTechnicianName, equals('Rajesh Sharma'));
      expect(updatedSlot.status, equals(AppConstants.statusAssigned));
    });

    test('Closed and cancelled tickets cannot be edited', () {
      final completed = initialRequest.copyWith(status: AppConstants.statusCompleted);
      final cancelled = initialRequest.copyWith(status: AppConstants.statusCancelled);

      expect(completed.isCompleted, isTrue);
      expect(completed.isActive, isFalse);

      expect(cancelled.isCancelled, isTrue);
      expect(cancelled.isActive, isFalse);
    });

    test('Slot lead time validation prevents selecting past or immediate slots on edit', () {
      const slot09 = TimeSlotItem(
        key: '09_12',
        label: '9 AM to 12 PM',
        startHour: 9,
        endHour: 12,
      );

      // Slot at 9:00 AM checked at 8:50 AM with 30-min lead time -> Not bookable
      final slotStart = slot09.getStartDateTime(DateTime(2026, 10, 14));
      final currentTime = DateTime(2026, 10, 14, 8, 50);

      expect(
        BookingConfigModel.isSlotBookable(
          slotStart: slotStart,
          now: currentTime,
          minLeadMinutes: 30,
        ),
        isFalse,
      );
    });
  });
}
