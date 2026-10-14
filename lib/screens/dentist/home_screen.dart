import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../models/booking_config_model.dart';
import '../../models/technician_request_model.dart';
import '../../providers/auth_providers.dart';
import '../../providers/request_providers.dart';
import '../../providers/settings_providers.dart';
import '../../theme/app_theme.dart';
import '../../utils/constants.dart';

/// Clinical home dashboard for dental surgeons and clinic directors.
/// Implements Section 3.7:
/// - Live status tiles (Pending, Assigned, In Progress, Completed) deep-linking to My Requests
/// - Active requests list displaying all ongoing requests (up to 5, then 'View all')
/// - Category tiles matching config.issueTypes codes
/// - Profile navigation in AppBar
/// - Clean fee messaging
class DentistHomeScreen extends ConsumerWidget {
  const DentistHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final userAsync = ref.watch(currentUserProfileProvider);
    final requestsAsync = ref.watch(dentistRequestsProvider);
    final configAsync = ref.watch(bookingConfigProvider);
    final config = configAsync.value ?? BookingConfigModel.defaultConfig();
    final dentist = userAsync.value;

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: Text(
          dentist?.clinicName?.isNotEmpty == true ? dentist!.clinicName! : AppConstants.appName,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.assignment_outlined),
            tooltip: 'My Requests',
            onPressed: () => context.push('/dentist/requests'),
          ),
          IconButton(
            icon: const Icon(Icons.person_outline_rounded),
            tooltip: 'Clinic Profile',
            onPressed: () => context.push('/dentist/profile'),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(dentistRequestsProvider);
          ref.invalidate(currentUserProfileProvider);
          ref.invalidate(bookingConfigProvider);
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(AppTheme.spacingMd),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Welcome & Clinic Greeting Card
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
                                    : 'Hyderabad Certified Dental Network',
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
                            'HYDERABAD',
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
                    const SizedBox(height: 18),
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
                              'RioDent platform is free to use. Fast on-site technician dispatch for your dental equipment.',
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
                        'Book a Technician',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 18),

              // 4 Live Status Tiles (Pending, Assigned, In Progress, Completed)
              Builder(
                builder: (context) {
                  final allRequests = requestsAsync.value ?? [];
                  final pendingCount = allRequests.where((r) => r.isNew).length;
                  final assignedCount = allRequests.where((r) => r.isAssigned).length;
                  final inProgressCount = allRequests.where((r) => r.isInProgress).length;
                  final completedCount = allRequests.where((r) => r.isCompleted).length;

                  return Row(
                    children: [
                      _buildStatusTile(
                        context: context,
                        label: 'Pending',
                        count: pendingCount,
                        color: AppTheme.statusNew,
                        icon: Icons.hourglass_top_rounded,
                        filter: AppConstants.statusNew,
                      ),
                      const SizedBox(width: 8),
                      _buildStatusTile(
                        context: context,
                        label: 'Assigned',
                        count: assignedCount,
                        color: AppTheme.statusAssigned,
                        icon: Icons.person_pin_circle_rounded,
                        filter: AppConstants.statusAssigned,
                      ),
                      const SizedBox(width: 8),
                      _buildStatusTile(
                        context: context,
                        label: 'In Progress',
                        count: inProgressCount,
                        color: AppTheme.statusInProgress,
                        icon: Icons.engineering_rounded,
                        filter: AppConstants.statusInProgress,
                      ),
                      const SizedBox(width: 8),
                      _buildStatusTile(
                        context: context,
                        label: 'Completed',
                        count: completedCount,
                        color: AppTheme.statusCompleted,
                        icon: Icons.check_circle_rounded,
                        filter: AppConstants.statusCompleted,
                      ),
                    ],
                  );
                },
              ),

              const SizedBox(height: 22),

              // Active Requests Tracker (Shows all active, up to 5, then 'View all')
              requestsAsync.when(
                loading: () => const Center(child: Padding(padding: EdgeInsets.all(16), child: CircularProgressIndicator())),
                error: (err, stack) => const SizedBox.shrink(),
                data: (requests) {
                  final activeRequests = requests.where((r) => r.isActive).toList();
                  if (activeRequests.isEmpty) return const SizedBox.shrink();

                  final displayList = activeRequests.take(5).toList();
                  final hasMore = activeRequests.length > 5;

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Row(
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
                                Flexible(
                                  child: Text(
                                    'Active Requests (${activeRequests.length})',
                                    style: theme.textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          TextButton(
                            onPressed: () => context.push('/dentist/requests?filter=ACTIVE'),
                            child: const Text('View All'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),

                      ...displayList.map((req) => _buildActiveRequestCard(context, req, theme)),

                      if (hasMore) ...[
                        Center(
                          child: TextButton.icon(
                            onPressed: () => context.push('/dentist/requests?filter=ACTIVE'),
                            icon: const Icon(Icons.arrow_forward_rounded, size: 16),
                            label: Text('View remaining ${activeRequests.length - 5} active requests'),
                          ),
                        ),
                      ],
                      const SizedBox(height: 16),
                    ],
                  );
                },
              ),

              // Quick Equipment Selection (from config.activeIssueTypes)
              Text(
                'Request by Equipment Category',
                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),

              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: config.activeIssueTypes.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 1.25,
                ),
                itemBuilder: (context, index) {
                  final cat = config.activeIssueTypes[index];
                  final icon = _getCategoryIcon(cat.code);

                  return InkWell(
                    borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                    onTap: () {
                      context.push('/dentist/book', extra: {'category': cat.code});
                    },
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                        border: Border.all(color: AppTheme.cardBorderColor),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.02),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(icon, color: AppTheme.primaryColor, size: 26),
                          const SizedBox(height: 8),
                          Text(
                            cat.label,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),

              const SizedBox(height: 24),

              // Service History Nav Card
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
                          Text('My Service History', style: theme.textTheme.titleMedium),
                          const SizedBox(height: 2),
                          Text(
                            'View full history, status timeline, and payment records of all tickets.',
                            style: theme.textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.arrow_forward_ios_rounded, size: 16),
                      onPressed: () => context.push('/dentist/requests?filter=ALL'),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 80),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xFF0284C7),
        foregroundColor: Colors.white,
        elevation: 3,
        onPressed: () => context.push('/dentist/book'),
        icon: const Icon(Icons.build_rounded),
        label: const Text('Book Technician', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
      ),
    );
  }

  Widget _buildStatusTile({
    required BuildContext context,
    required String label,
    required int count,
    required Color color,
    required IconData icon,
    required String filter,
  }) {
    return Expanded(
      child: InkWell(
        borderRadius: BorderRadius.circular(AppTheme.radiusSm),
        onTap: () => context.push('/dentist/requests?filter=$filter'),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(AppTheme.radiusSm),
            border: Border.all(
              color: count > 0 ? color.withValues(alpha: 0.5) : AppTheme.cardBorderColor,
              width: count > 0 ? 1.5 : 1.0,
            ),
          ),
          child: Column(
            children: [
              Icon(icon, color: color, size: 18),
              const SizedBox(height: 4),
              Text(
                '$count',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: color),
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppTheme.textSecondary),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActiveRequestCard(BuildContext context, TechnicianRequestModel req, ThemeData theme) {
    final statusColor = AppTheme.getStatusColor(req.status);
    final dateFormat = DateFormat('MMM dd, hh:mm a');

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        onTap: () => context.push('/dentist/requests/${req.id}'),
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.spacingMd),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      req.issueLabel,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                    ),
                    child: Text(
                      AppTheme.getStatusLabel(req.status),
                      style: TextStyle(
                        color: statusColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                req.issueDescription,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodyMedium,
              ),
              const Divider(height: 18),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      req.assignedTechnicianName != null
                          ? 'Tech: ${req.assignedTechnicianName}'
                          : 'Coordinator dispatching...',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: req.assignedTechnicianName != null ? AppTheme.primaryColor : AppTheme.textSecondary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    dateFormat.format(req.createdAt),
                    style: theme.textTheme.labelSmall,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getCategoryIcon(String code) {
    switch (code) {
      case 'dental_chair':
        return Icons.airline_seat_recline_extra_rounded;
      case 'autoclave':
        return Icons.sanitizer_rounded;
      case 'xray_rvg':
        return Icons.camera_indoor_rounded;
      case 'air_compressor':
        return Icons.air_rounded;
      case 'handpieces':
        return Icons.precision_manufacturing_rounded;
      case 'suction_piping':
        return Icons.plumbing_rounded;
      case 'scalers_lightcure':
        return Icons.light_mode_rounded;
      default:
        return Icons.build_rounded;
    }
  }
}
