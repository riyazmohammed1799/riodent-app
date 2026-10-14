import 'package:flutter_test/flutter_test.dart';
import 'package:riodent/models/technician_request_model.dart';
import 'package:riodent/utils/constants.dart';

void main() {
  group('TechnicianRequestModel unit tests', () {
    final now = DateTime(2026, 10, 14, 14, 0);

    test('displayTicketId formats ticketNumber or falls back to REQ-prefix', () {
      final req = TechnicianRequestModel(
        id: 'firestore_doc_123',
        ticketNumber: 'REQ-784210',
        dentistId: 'dentist_1',
        dentistName: 'Dr. John Doe',
        mobile: '9876543210',
        clinicName: 'Smile Care',
        address: const RequestAddress(
          line: 'Road No 12',
          area: 'Banjara Hills',
          city: 'Hyderabad',
          pincode: '500034',
          lat: 17.4156,
          lng: 78.4350,
        ),
        issueCode: 'dental_chair',
        issueLabel: 'Dental Chair',
        issueDescription: 'Hydraulic lift stuck, foot pedal unresponsive',
        slotDate: '2026-10-15',
        slotKey: '09_12',
        slotStart: now.add(const Duration(hours: 19)),
        status: AppConstants.statusNew,
        createdAt: now,
        updatedAt: now,
      );

      expect(req.displayTicketId, equals('REQ-784210'));
      expect(req.locality, equals('Banjara Hills'));
      expect(req.city, equals('Hyderabad'));
      expect(req.isCompleted, isFalse);
      expect(req.isCancelled, isFalse);
      expect(req.isActive, isTrue);
    });

    test('Cancellation mapping and fields', () {
      final cancelledReq = TechnicianRequestModel(
        id: 'doc_456',
        ticketNumber: 'REQ-991234',
        dentistId: 'dentist_1',
        dentistName: 'Dr. Jane Smith',
        mobile: '9876543210',
        clinicName: 'Apex Dental',
        address: const RequestAddress(
          line: 'Jubilee Hills Checkpost',
          area: 'Jubilee Hills',
          city: 'Hyderabad',
          pincode: '500033',
        ),
        issueCode: 'autoclave',
        issueLabel: 'Autoclave',
        issueDescription: 'Temperature sensor failure',
        slotDate: '2026-10-15',
        slotKey: '14_17',
        slotStart: now,
        status: AppConstants.statusCancelled,
        cancelledAt: now,
        cancelledBy: 'dentist',
        reasonCode: 'fee_dispute',
        reasonText: 'Found another technician',
        createdAt: now,
        updatedAt: now,
      );

      expect(cancelledReq.isCancelled, isTrue);
      expect(cancelledReq.reasonText, equals('Found another technician'));
      expect(cancelledReq.cancelledBy, equals('dentist'));

      final map = cancelledReq.toMap();
      expect(map['ticketNumber'], equals('REQ-991234'));
      expect(map['status'], equals(AppConstants.statusCancelled));
      expect(map['reasonText'], equals('Found another technician'));
      expect(map['cancelledBy'], equals('dentist'));
    });

    test('Completion mapping and amountPaid', () {
      final completedReq = TechnicianRequestModel(
        id: 'doc_789',
        ticketNumber: 'REQ-123456',
        dentistId: 'dentist_1',
        dentistName: 'Dr. Rao',
        mobile: '9876543210',
        clinicName: 'City Dental',
        address: const RequestAddress(
          line: 'Hitec City Main Road',
          area: 'Hitec City',
          city: 'Hyderabad',
          pincode: '500081',
        ),
        issueCode: 'air_compressor',
        issueLabel: 'Air Compressor',
        issueDescription: 'Pressure not building up',
        slotDate: '2026-10-14',
        slotKey: '09_12',
        slotStart: now,
        status: AppConstants.statusCompleted,
        assignedTechnicianId: 'tech_1',
        assignedTechnicianName: 'Suresh Kumar',
        assignedTechnicianPhone: '+919876543219',
        amountPaid: 1500.0,
        completedAt: now,
        completedBy: 'dentist',
        createdAt: now,
        updatedAt: now,
      );

      expect(completedReq.isCompleted, isTrue);
      expect(completedReq.amountPaid, equals(1500.0));
      expect(completedReq.completedBy, equals('dentist'));
      expect(completedReq.assignedTechnicianName, equals('Suresh Kumar'));

      final map = completedReq.toMap();
      expect(map['amountPaid'], equals(1500.0));
      expect(map['completedBy'], equals('dentist'));
      expect(map['status'], equals(AppConstants.statusCompleted));
    });
  });
}
