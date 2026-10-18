import 'package:flutter_test/flutter_test.dart';
import 'package:riodent/models/booking_config_model.dart';
import 'package:riodent/models/technician_model.dart';
import 'package:riodent/models/technician_request_model.dart';
import 'package:riodent/utils/constants.dart';
import 'package:riodent/utils/validators.dart';

void main() {
  group('Admin Panel Comprehensive Test Suite (Positive & Negative QA)', () {
    final now = DateTime.now();

    TechnicianRequestModel createTestTicket({
      required String status,
      String? techId,
      String? techName,
      String? techPhone,
      double? amountPaid,
    }) {
      return TechnicianRequestModel(
        id: 'REQ-101',
        ticketNumber: 'REQ-101',
        dentistId: 'doc-001',
        dentistName: 'Dr. Rao',
        clinicName: 'Rao Dental Care',
        mobile: '9876543210',
        address: const RequestAddress(
          line: 'Plot 42, Jubilee Hills',
          city: 'Hyderabad',
          pincode: '500033',
        ),
        issueCode: 'dental_chair',
        issueLabel: 'Dental Chair',
        issueDescription: 'Hydraulic lift not operating',
        slotDate: '2026-10-20',
        slotKey: '09_12',
        slotStart: now.add(const Duration(hours: 4)),
        status: status,
        assignedTechnicianId: techId,
        assignedTechnicianName: techName,
        assignedTechnicianPhone: techPhone,
        amountPaid: amountPaid,
        createdAt: now,
        updatedAt: now,
      );
    }

    // ── 1. Technician Assignment (Positive & Negative) ───────────
    group('1. Technician Assignment & Reassignment', () {
      test('[POS] Admin can assign technician when request is in NEW status', () {
        final ticket = createTestTicket(status: AppConstants.statusNew);
        expect(TechnicianRequestModel.canAdminAssign(ticket.status), isTrue);
      });

      test('[POS] Admin can reassign technician when request is in ASSIGNED status', () {
        final ticket = createTestTicket(
          status: AppConstants.statusAssigned,
          techId: 'tech-1',
          techName: 'Suresh Kumar',
          techPhone: '9876500001',
        );
        expect(TechnicianRequestModel.canAdminAssign(ticket.status), isTrue);
      });

      test('[NEG] Admin CANNOT assign technician when request is IN_PROGRESS (job locked)', () {
        final ticket = createTestTicket(
          status: AppConstants.statusInProgress,
          techId: 'tech-1',
        );
        expect(TechnicianRequestModel.canAdminAssign(ticket.status), isFalse);
      });

      test('[NEG] Admin CANNOT assign technician when request is COMPLETED', () {
        final ticket = createTestTicket(
          status: AppConstants.statusCompleted,
          amountPaid: 1500,
        );
        expect(TechnicianRequestModel.canAdminAssign(ticket.status), isFalse);
      });

      test('[NEG] Admin CANNOT assign technician when request is CANCELLED', () {
        final ticket = createTestTicket(status: AppConstants.statusCancelled);
        expect(TechnicianRequestModel.canAdminAssign(ticket.status), isFalse);
      });

      test('[POS] Technician model maps active state properly for dispatch selection', () {
        final activeTech = TechnicianModel(
          id: 't-1',
          name: 'Ramesh Field Tech',
          phone: '9876543210',
          area: 'Banjara Hills',
          isActive: true,
          createdAt: now,
          updatedAt: now,
        );
        final inactiveTech = TechnicianModel(
          id: 't-2',
          name: 'Off-duty Tech',
          phone: '9876543211',
          area: 'Secunderabad',
          isActive: false,
          createdAt: now,
          updatedAt: now,
        );

        final roster = [activeTech, inactiveTech];
        final dispatchable = roster.where((t) => t.isActive).toList();
        expect(dispatchable.length, equals(1));
        expect(dispatchable.first.name, equals('Ramesh Field Tech'));
      });
    });

    // ── 2. Transition to IN_PROGRESS (Positive & Negative) ────────
    group('2. Status Progression to IN_PROGRESS', () {
      test('[POS] Can advance to IN_PROGRESS when ASSIGNED and assigned technician exists', () {
        final canAdvance = TechnicianRequestModel.canAdminSetInProgress(
          status: AppConstants.statusAssigned,
          hasTechnician: true,
        );
        expect(canAdvance, isTrue);
      });

      test('[NEG] CANNOT advance to IN_PROGRESS if status is ASSIGNED but NO technician assigned', () {
        final canAdvance = TechnicianRequestModel.canAdminSetInProgress(
          status: AppConstants.statusAssigned,
          hasTechnician: false,
        );
        expect(canAdvance, isFalse);
      });

      test('[NEG] CANNOT advance to IN_PROGRESS if status is still NEW (unassigned)', () {
        final canAdvance = TechnicianRequestModel.canAdminSetInProgress(
          status: AppConstants.statusNew,
          hasTechnician: false,
        );
        expect(canAdvance, isFalse);
      });

      test('[NEG] CANNOT advance to IN_PROGRESS if status is already IN_PROGRESS', () {
        final canAdvance = TechnicianRequestModel.canAdminSetInProgress(
          status: AppConstants.statusInProgress,
          hasTechnician: true,
        );
        expect(canAdvance, isFalse);
      });
    });

    // ── 3. Close on Behalf & Payment (Positive & Negative) ────────
    group('3. Close on Behalf of Doctor & Payment Validation', () {
      test('[POS] Admin can close ticket on behalf from IN_PROGRESS', () {
        expect(TechnicianRequestModel.canAdminCloseOnBehalf(AppConstants.statusInProgress), isTrue);
      });

      test('[POS] Admin can close ticket on behalf from ASSIGNED', () {
        expect(TechnicianRequestModel.canAdminCloseOnBehalf(AppConstants.statusAssigned), isTrue);
      });

      test('[NEG] Admin CANNOT close ticket on behalf from NEW (must dispatch technician first)', () {
        expect(TechnicianRequestModel.canAdminCloseOnBehalf(AppConstants.statusNew), isFalse);
      });

      test('[NEG] Admin CANNOT close ticket on behalf if already COMPLETED or CANCELLED', () {
        expect(TechnicianRequestModel.canAdminCloseOnBehalf(AppConstants.statusCompleted), isFalse);
        expect(TechnicianRequestModel.canAdminCloseOnBehalf(AppConstants.statusCancelled), isFalse);
      });

      test('[POS] Amount paid validator accepts whole rupees between 0 and 100,000', () {
        expect(Validators.amountPaid('0'), isNull);
        expect(Validators.amountPaid('500'), isNull);
        expect(Validators.amountPaid('2500'), isNull);
        expect(Validators.amountPaid('100000'), isNull);
      });

      test('[NEG] Amount paid validator rejects negative, decimal, or excessive values', () {
        expect(Validators.amountPaid('-50'), isNotNull);
        expect(Validators.amountPaid('150.75'), isNotNull);
        expect(Validators.amountPaid('100001'), isNotNull);
        expect(Validators.amountPaid('abc'), isNotNull);
      });
    });

    // ── 4. Cancellation Rules (Positive & Negative) ───────────────
    group('4. Ticket Cancellation by Admin & Doctor', () {
      test('[POS] Admin can cancel ticket from NEW, ASSIGNED, or IN_PROGRESS with reason', () {
        expect(TechnicianRequestModel.canAdminCancel(AppConstants.statusNew), isTrue);
        expect(TechnicianRequestModel.canAdminCancel(AppConstants.statusAssigned), isTrue);
        expect(TechnicianRequestModel.canAdminCancel(AppConstants.statusInProgress), isTrue);
      });

      test('[NEG] Admin CANNOT cancel terminal ticket (COMPLETED or CANCELLED)', () {
        expect(TechnicianRequestModel.canAdminCancel(AppConstants.statusCompleted), isFalse);
        expect(TechnicianRequestModel.canAdminCancel(AppConstants.statusCancelled), isFalse);
      });

      test('[NEG] Doctor CANNOT cancel ticket once technician is IN_PROGRESS (must contact admin/support)', () {
        expect(TechnicianRequestModel.canDoctorCancel(AppConstants.statusInProgress), isFalse);
      });
    });

    // ── 5. Equipment Category Management (Positive & Negative) ────
    group('5. Equipment Category Management in Settings', () {
      test('[POS] Adding a new category creates code and label properly', () {
        final label = 'Laser Handpieces';
        final code = label.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '_');
        expect(code, equals('laser_handpieces'));

        final item = IssueTypeItem(code: code, label: label, active: true);
        expect(item.active, isTrue);
        expect(item.label, equals('Laser Handpieces'));
      });

      test('[NEG] Prevents duplicate category code from being added', () {
        final currentCategories = [
          const IssueTypeItem(code: 'dental_chair', label: 'Dental Chair', active: true),
          const IssueTypeItem(code: 'autoclave', label: 'Autoclave', active: true),
        ];

        final newLabel = 'Dental Chair';
        final newCode = newLabel.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '_');
        final isDuplicate = currentCategories.any((c) => c.code == newCode);
        expect(isDuplicate, isTrue);
      });

      test('[POS] Deduplication preserves unique items and maintains order', () {
        final raw = [
          const IssueTypeItem(code: 'autoclave', label: 'Autoclave', active: true),
          const IssueTypeItem(code: 'dental_chair', label: 'Dental Chair 1', active: true),
          const IssueTypeItem(code: 'autoclave', label: 'Autoclave Duplicate', active: false),
        ];
        final deduplicated = IssueTypeItem.deduplicateByCode(raw);
        expect(deduplicated.length, equals(2));
        expect(deduplicated[0].code, equals('autoclave'));
        expect(deduplicated[0].label, equals('Autoclave'));
        expect(deduplicated[1].code, equals('dental_chair'));
      });
    });

    // ── 6. Real-Time Metric Reducers (Positive & Negative) ────────
    group('6. Real-Time Dashboard KPI Calculations', () {
      test('[POS] Revenue calculation sums only COMPLETED tickets with whole rupee amounts', () {
        final tickets = [
          createTestTicket(status: AppConstants.statusCompleted, amountPaid: 1200),
          createTestTicket(status: AppConstants.statusCompleted, amountPaid: 3500),
          createTestTicket(status: AppConstants.statusCancelled, amountPaid: 5000), // Should be ignored
          createTestTicket(status: AppConstants.statusNew, amountPaid: null),       // Should be ignored
          createTestTicket(status: AppConstants.statusInProgress, amountPaid: 2000), // Should be ignored
        ];

        double totalRevenue = 0.0;
        for (final t in tickets) {
          if (t.isCompleted) {
            totalRevenue += t.amountPaid ?? 0.0;
          }
        }

        expect(totalRevenue, equals(4700.0));
      });

      test('[POS] Technician deletions reflect immediately in active roster count', () {
        final tech1 = TechnicianModel(id: '1', name: 'A', phone: '9876543210', isActive: true, createdAt: now, updatedAt: now);
        final tech2 = TechnicianModel(id: '2', name: 'B', phone: '9876543211', isActive: true, createdAt: now, updatedAt: now);
        final tech3 = TechnicianModel(id: '3', name: 'C', phone: '9876543212', isActive: false, createdAt: now, updatedAt: now);

        var roster = [tech1, tech2, tech3];
        expect(roster.where((t) => t.isActive).length, equals(2));

        // Delete technician 2
        roster = roster.where((t) => t.id != '2').toList();
        expect(roster.where((t) => t.isActive).length, equals(1));
        expect(roster.first.id, equals('1'));
      });

      test('[POS] Doctor phone number validator enforces 10 digits starting with 6-9', () {
        expect(Validators.phoneNumber('9876543210'), isNull);
        expect(Validators.phoneNumber('8123456789'), isNull);
        expect(Validators.phoneNumber('7000000000'), isNull);
        expect(Validators.phoneNumber('6300000000'), isNull);

        // Negative: fewer or more digits, invalid starting digit, non-digits
        expect(Validators.phoneNumber('987654321'), isNotNull);
        expect(Validators.phoneNumber('98765432100'), isNotNull);
        expect(Validators.phoneNumber('5876543210'), isNotNull);
        expect(Validators.phoneNumber('98765abcde'), isNotNull);
      });
    });
  });
}
