import 'package:flutter_test/flutter_test.dart';
import 'package:riodent/models/technician_request_model.dart';
import 'package:riodent/utils/constants.dart';

void main() {
  group('Status Model & Transitions (Issue I14 / ADM-08 to ADM-18, DR-03 to DR-15)', () {
    test('Only 5 valid statuses exist', () {
      const allowedStatuses = {'NEW', 'ASSIGNED', 'IN_PROGRESS', 'COMPLETED', 'CANCELLED'};
      expect(AppConstants.statusNew, equals('NEW'));
      expect(AppConstants.statusAssigned, equals('ASSIGNED'));
      expect(AppConstants.statusInProgress, equals('IN_PROGRESS'));
      expect(AppConstants.statusCompleted, equals('COMPLETED'));
      expect(AppConstants.statusCancelled, equals('CANCELLED'));
      expect({
        AppConstants.statusNew,
        AppConstants.statusAssigned,
        AppConstants.statusInProgress,
        AppConstants.statusCompleted,
        AppConstants.statusCancelled,
      }, equals(allowedStatuses));
    });

    test('Doctor valid status transitions', () {
      // Doctor can cancel only when NEW or ASSIGNED
      expect(TechnicianRequestModel.canDoctorCancel(AppConstants.statusNew), isTrue);
      expect(TechnicianRequestModel.canDoctorCancel(AppConstants.statusAssigned), isTrue);
      expect(TechnicianRequestModel.canDoctorCancel(AppConstants.statusInProgress), isFalse); // Must call support
      expect(TechnicianRequestModel.canDoctorCancel(AppConstants.statusCompleted), isFalse);
      expect(TechnicianRequestModel.canDoctorCancel(AppConstants.statusCancelled), isFalse);

      // Doctor can complete only when ASSIGNED or IN_PROGRESS
      expect(TechnicianRequestModel.canDoctorComplete(AppConstants.statusNew), isFalse);
      expect(TechnicianRequestModel.canDoctorComplete(AppConstants.statusAssigned), isTrue);
      expect(TechnicianRequestModel.canDoctorComplete(AppConstants.statusInProgress), isTrue);
      expect(TechnicianRequestModel.canDoctorComplete(AppConstants.statusCompleted), isFalse);
      expect(TechnicianRequestModel.canDoctorComplete(AppConstants.statusCancelled), isFalse);
    });

    test('Admin valid status transitions', () {
      // Admin can assign/reassign in NEW or ASSIGNED
      expect(TechnicianRequestModel.canAdminAssign(AppConstants.statusNew), isTrue);
      expect(TechnicianRequestModel.canAdminAssign(AppConstants.statusAssigned), isTrue);
      expect(TechnicianRequestModel.canAdminAssign(AppConstants.statusInProgress), isFalse);
      expect(TechnicianRequestModel.canAdminAssign(AppConstants.statusCompleted), isFalse);
      expect(TechnicianRequestModel.canAdminAssign(AppConstants.statusCancelled), isFalse);

      // Admin can set IN_PROGRESS only if ASSIGNED and has technician
      expect(TechnicianRequestModel.canAdminSetInProgress(status: AppConstants.statusAssigned, hasTechnician: true), isTrue);
      expect(TechnicianRequestModel.canAdminSetInProgress(status: AppConstants.statusAssigned, hasTechnician: false), isFalse);
      expect(TechnicianRequestModel.canAdminSetInProgress(status: AppConstants.statusNew, hasTechnician: false), isFalse);
      expect(TechnicianRequestModel.canAdminSetInProgress(status: AppConstants.statusInProgress, hasTechnician: true), isFalse);

      // Admin can close on behalf of doctor in ASSIGNED or IN_PROGRESS
      expect(TechnicianRequestModel.canAdminCloseOnBehalf(AppConstants.statusAssigned), isTrue);
      expect(TechnicianRequestModel.canAdminCloseOnBehalf(AppConstants.statusInProgress), isTrue);
      expect(TechnicianRequestModel.canAdminCloseOnBehalf(AppConstants.statusNew), isFalse);
      expect(TechnicianRequestModel.canAdminCloseOnBehalf(AppConstants.statusCompleted), isFalse);

      // Admin can cancel any non-final status
      expect(TechnicianRequestModel.canAdminCancel(AppConstants.statusNew), isTrue);
      expect(TechnicianRequestModel.canAdminCancel(AppConstants.statusAssigned), isTrue);
      expect(TechnicianRequestModel.canAdminCancel(AppConstants.statusInProgress), isTrue);
      expect(TechnicianRequestModel.canAdminCancel(AppConstants.statusCompleted), isFalse);
      expect(TechnicianRequestModel.canAdminCancel(AppConstants.statusCancelled), isFalse);
    });

    test('COMPLETED and CANCELLED are terminal states', () {
      expect(TechnicianRequestModel.isTerminal(AppConstants.statusCompleted), isTrue);
      expect(TechnicianRequestModel.isTerminal(AppConstants.statusCancelled), isTrue);
      expect(TechnicianRequestModel.isTerminal(AppConstants.statusNew), isFalse);
      expect(TechnicianRequestModel.isTerminal(AppConstants.statusAssigned), isFalse);
      expect(TechnicianRequestModel.isTerminal(AppConstants.statusInProgress), isFalse);
    });
  });
}
