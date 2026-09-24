/// Application-wide constants.
///
/// Values here are true constants that do not change between environments
/// and do not need to be configurable from Firebase.
class AppConstants {
  AppConstants._();

  // ── App Info ──────────────────────────────────────────────────
  static const String appName = 'RioDent';
  static const String appTagline = 'Dental Technician Services';

  // ── Media Upload Limits ───────────────────────────────────────
  // These are client-side defaults. Server-side limits are enforced
  // by Firebase Storage Security Rules. The actual configurable values
  // come from appSettings/bookingConfig in Firestore.
  static const int defaultMaxPhotos = 5;
  static const int defaultMaxPhotoSizeMB = 5;
  static const int defaultMaxVideoSizeMB = 25;
  static const int defaultMaxVideoDurationSec = 30;

  // ── Firestore Collection Names ────────────────────────────────
  static const String usersCollection = 'users';
  static const String technicianRequestsCollection = 'technicianRequests';
  static const String techniciansCollection = 'technicians';
  static const String appSettingsCollection = 'appSettings';
  static const String bookingConfigDoc = 'bookingConfig';

  // ── Storage Paths ─────────────────────────────────────────────
  static const String storageRequestsPath = 'requests';

  // ── User Roles ────────────────────────────────────────────────
  static const String roleDentist = 'dentist';
  static const String roleAdmin = 'admin';

  // ── Request Statuses ──────────────────────────────────────────
  static const String statusNew = 'NEW';
  static const String statusAssigned = 'ASSIGNED';
  static const String statusInProgress = 'IN_PROGRESS';
  static const String statusCompleted = 'COMPLETED';
  static const String statusCancelled = 'CANCELLED';

  /// Valid status transitions.
  static const Map<String, List<String>> statusTransitions = {
    statusNew: [statusAssigned, statusCancelled],
    statusAssigned: [statusInProgress, statusCancelled],
    statusInProgress: [statusCompleted, statusCancelled],
    statusCompleted: [],
    statusCancelled: [],
  };

  /// Returns true if transitioning from [currentStatus] to [newStatus] is valid.
  static bool isValidTransition(String currentStatus, String newStatus) {
    final allowed = statusTransitions[currentStatus];
    return allowed != null && allowed.contains(newStatus);
  }

  // ── Pagination ────────────────────────────────────────────────
  static const int defaultPageSize = 10;
}
