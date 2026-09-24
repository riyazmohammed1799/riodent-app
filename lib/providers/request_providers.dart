import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/technician_request_model.dart';
import '../repositories/request_repository.dart';
import 'auth_providers.dart';
import 'user_providers.dart';

/// Provider for RequestRepository.
final requestRepositoryProvider = Provider<RequestRepository>((ref) {
  final firestore = ref.watch(firestoreProvider);
  return RequestRepository(firestore: firestore);
});

/// Stream of technician requests for the currently signed-in dentist.
final dentistRequestsProvider = StreamProvider<List<TechnicianRequestModel>>((ref) {
  final uid = ref.watch(currentUserIdProvider);
  if (uid == null) {
    return Stream.value([]);
  }
  final repo = ref.watch(requestRepositoryProvider);
  return repo.streamDentistRequests(uid);
});

/// Notifier managing status filter for the admin requests view.
class AdminStatusFilterNotifier extends Notifier<String> {
  @override
  String build() => 'ALL';

  void setFilter(String filter) {
    state = filter;
  }
}

/// Status filter provider for admin requests queue.
final adminStatusFilterProvider =
    NotifierProvider<AdminStatusFilterNotifier, String>(AdminStatusFilterNotifier.new);

/// Stream of technician requests for the admin, filtered by [adminStatusFilterProvider].
final adminRequestsProvider = StreamProvider<List<TechnicianRequestModel>>((ref) {
  final filter = ref.watch(adminStatusFilterProvider);
  final repo = ref.watch(requestRepositoryProvider);
  return repo.streamAdminRequests(status: filter == 'ALL' ? null : filter);
});

/// Stream of a specific request by ID.
final requestDetailProvider =
    StreamProvider.family<TechnicianRequestModel?, String>((ref, requestId) {
  final repo = ref.watch(requestRepositoryProvider);
  return repo.streamRequest(requestId);
});
