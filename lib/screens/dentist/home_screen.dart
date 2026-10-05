import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../providers/auth_providers.dart';
import '../../providers/request_providers.dart';
import '../../theme/app_theme.dart';
import '../../utils/constants.dart';

/// Premium clinical dashboard for dental surgeons and clinic directors.
class DentistHomeScreen extends ConsumerWidget {
  const DentistHomeScreen({super.key});

  static const List<Map<String, dynamic>> _quickCategories = [
    {
      'title': 'Dental Chair',
      'icon': Icons.airline_seat_recline_extra_rounded,
      'desc': 'Hydraulic, valves, tubing',
    },
    {
      'title': 'Autoclave',
      'icon': Icons.sanitizer_rounded,
      'desc': 'Heating, pressure, seal',
    },
    {
      'title': 'X-Ray & RVG',
      'icon': Icons.camera_indoor_rounded,
      'desc': 'Sensor, arm, exposure',
    },
    {
      'title': 'Air Compressor',
      'icon': Icons.air_rounded,
      'desc': 'Motor, pressure drop',
    },
    {
      'title': 'Handpieces',
      'icon': Icons.precision_manufacturing_rounded,
      'desc': 'Bearing, torque, turbine',
    },
    {
      'title': 'Suction & Piping',
      'icon': Icons.plumbing_rounded,
      'desc': 'Drainage, canister, vacuum',
    },
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final userAsync = ref.watch(currentUserProfileProvider);
    final requestsAsync = ref.watch(dentistRequestsProvider);
    final authRepo = ref.read(authRepositoryProvider);
    final dateFormat = DateFormat('MMM dd, hh:mm a');

    final dentist = userAsync.value;

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: Text(dentist?.clinicName ?? AppConstants.appName),
        actions: [
          IconButton(
            icon: const Icon(Icons.assignment_outlined),
            tooltip: 'My Requests',
            onPressed: () => context.push('/dentist/requests'),
          ),
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            tooltip: 'Sign Out',
            onPressed: () async => await authRepo.signOut(),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(dentistRequestsProvider);
          ref.invalidate(currentUserProfileProvider);
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(AppTheme.spacingMd),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Welcome & Clinic Card
              Container(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF0F4C81), Color(0xFF093154)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primaryColor.withValues(alpha: 0.25),
                      blurRadius: 18,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(AppTheme.spacingLg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                dentist?.displayName.isNotEmpty == true
                                    ? 'Welcome, ${dentist!.displayName}'
                                    : 'Welcome Doctor',
                                style: theme.textTheme.headlineSmall?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                (dentist?.clinicAddress != null && dentist!.clinicAddress!.isNotEmpty)
                                    ? dentist.clinicAddress!
                                    : 'RioDent Certified Dental Network',
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.85),
                                  fontSize: 13,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppTheme.secondaryColor,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Text(
                            'FREE SERVICE',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.verified_rounded, color: Color(0xFF68D391), size: 18),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Zero platform fee. Technician dispatch and diagnosis are 100% complimentary for your clinic.',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                height: 1.4,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: AppTheme.primaryDark,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      onPressed: () => context.push('/dentist/book'),
                      icon: const Icon(Icons.add_circle_outline_rounded, size: 20),
                      label: const Text(
                        'Book a Technician Now',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Active Request Tracker (if any ongoing booking)
              requestsAsync.when(
                loading: () => const SizedBox.shrink(),
                error: (error, stack) => const SizedBox.shrink(),
                data: (requests) {
                  final active = requests.where((r) => !r.isCompleted && !r.isCancelled).toList();
                  if (active.isEmpty) return const SizedBox.shrink();

                  final latestActive = active.first;
                  final statusColor = AppTheme.getStatusColor(latestActive.status);

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 8,
                                height: 8,
                                decoration: const BoxDecoration(
                                  color: AppTheme.successColor,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Active Service Request',
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          TextButton(
                            onPressed: () => context.push('/dentist/requests/${latestActive.id}'),
                            child: const Text('Track Details'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Card(
                        margin: EdgeInsets.zero,
                        child: Padding(
                          padding: const EdgeInsets.all(AppTheme.spacingMd),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    latestActive.issueType,
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: statusColor.withValues(alpha: 0.12),
                                      borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                                    ),
                                    child: Text(
                                      AppTheme.getStatusLabel(latestActive.status),
                                      style: TextStyle(
                                        color: statusColor,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Text(
                                latestActive.issueDescription,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: theme.textTheme.bodyMedium,
                              ),
                              const Divider(height: 20),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    latestActive.assignedTechnicianName != null
                                        ? 'Technician: ${latestActive.assignedTechnicianName}'
                                        : 'Coordinator is assigning nearest tech',
                                    style: theme.textTheme.labelMedium?.copyWith(
                                      color: latestActive.assignedTechnicianName != null
                                          ? AppTheme.primaryColor
                                          : AppTheme.textSecondary,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  Text(
                                    dateFormat.format(latestActive.createdAt),
                                    style: theme.textTheme.labelSmall,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],
                  );
                },
              ),

              // Quick Equipment Selection
              Text(
                'Request by Equipment Category',
                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),

              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _quickCategories.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 1.5,
                ),
                itemBuilder: (context, index) {
                  final cat = _quickCategories[index];
                  return InkWell(
                    borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                    onTap: () {
                      context.push('/dentist/book');
                    },
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                        border: Border.all(color: AppTheme.cardBorderColor),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(cat['icon'] as IconData, color: AppTheme.primaryColor, size: 26),
                          const SizedBox(height: 6),
                          Text(
                            cat['title'] as String,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            cat['desc'] as String,
                            style: theme.textTheme.bodySmall?.copyWith(fontSize: 11),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),

              const SizedBox(height: 24),

              // History Center Navigation Card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                  border: Border.all(color: AppTheme.cardBorderColor),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryLight,
                        borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                      ),
                      child: const Icon(Icons.history_rounded, color: AppTheme.primaryColor),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Service History & Tracking', style: theme.textTheme.titleMedium),
                          const SizedBox(height: 2),
                          Text(
                            'View full history and status of all past clinic requests.',
                            style: theme.textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.arrow_forward_ios_rounded, size: 16),
                      onPressed: () => context.push('/dentist/requests'),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Help & Support Contact Card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.support_agent_rounded, color: AppTheme.primaryDark, size: 28),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Dental Surgery Emergency?',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                          ),
                          Text(
                            'For critical chair or compressor breakdown during active surgery, our emergency dispatch priority is active.',
                            style: theme.textTheme.bodySmall?.copyWith(fontSize: 11),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
