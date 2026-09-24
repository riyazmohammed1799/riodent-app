import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/technician_model.dart';
import '../repositories/technician_repository.dart';
import 'user_providers.dart';

/// Provider for TechnicianRepository.
final technicianRepositoryProvider = Provider<TechnicianRepository>((ref) {
  final firestore = ref.watch(firestoreProvider);
  return TechnicianRepository(firestore: firestore);
});

/// Stream of active technicians available for assignment.
final activeTechniciansProvider = StreamProvider<List<TechnicianModel>>((ref) {
  final repo = ref.watch(technicianRepositoryProvider);
  return repo.streamActiveTechnicians();
});
