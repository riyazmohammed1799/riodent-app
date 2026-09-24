import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/auth_providers.dart';
import '../../providers/request_providers.dart';
import '../../providers/technician_providers.dart';
import '../../theme/app_theme.dart';
import '../../utils/constants.dart';

/// Admin overview dashboard showing request metrics and operation controls.
class AdminDashboardScreen extends ConsumerWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final requestsAsync = ref.watch(adminRequestsProvider);
    final authRepo = ref.read(authRepositoryProvider);
    final techRepo = ref.read(technicianRepositoryProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: 'App Configuration',
            onPressed: () => context.push('/admin/settings'),
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
          ref.invalidate(adminRequestsProvider);
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(AppTheme.spacingMd),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Metrics Grid
              requestsAsync.when(
                loading: () => const Center(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: CircularProgressIndicator(),
                  ),
                ),
                error: (e, _) => Text('Error loading metrics: $e'),
                data: (requests) {
                  final newCount = requests.where((r) => r.isNew).length;
                  final assignedCount = requests.where((r) => r.isAssigned).length;
                  final inProgressCount = requests.where((r) => r.isInProgress).length;
                  final completedCount = requests.where((r) => r.isCompleted).length;

                  return Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: _MetricCard(
                              label: 'New Requests',
                              count: newCount,
                              color: AppTheme.statusNew,
                              icon: Icons.mark_email_unread_rounded,
                              onTap: () {
                                ref.read(adminStatusFilterProvider.notifier).setFilter(AppConstants.statusNew);
                                context.push('/admin/requests');
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _MetricCard(
                              label: 'Assigned',
                              count: assignedCount,
                              color: AppTheme.statusAssigned,
                              icon: Icons.assignment_ind_rounded,
                              onTap: () {
                                ref.read(adminStatusFilterProvider.notifier).setFilter(AppConstants.statusAssigned);
                                context.push('/admin/requests');
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: _MetricCard(
                              label: 'In Progress',
                              count: inProgressCount,
                              color: AppTheme.statusInProgress,
                              icon: Icons.engineering_rounded,
                              onTap: () {
                                ref.read(adminStatusFilterProvider.notifier).setFilter(AppConstants.statusInProgress);
                                context.push('/admin/requests');
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _MetricCard(
                              label: 'Completed',
                              count: completedCount,
                              color: AppTheme.statusCompleted,
                              icon: Icons.check_circle_outline_rounded,
                              onTap: () {
                                ref.read(adminStatusFilterProvider.notifier).setFilter(AppConstants.statusCompleted);
                                context.push('/admin/requests');
                              },
                            ),
                          ),
                        ],
                      ),
                    ],
                  );
                },
              ),

              const SizedBox(height: 24),

              // Operational Actions
              Text('Operations', style: theme.textTheme.titleMedium),
              const SizedBox(height: 8),

              Card(
                margin: EdgeInsets.zero,
                child: Column(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.list_alt_rounded, color: AppTheme.primaryColor),
                      title: const Text('All Requests Queue'),
                      subtitle: const Text('View and filter full dispatch queue'),
                      trailing: const Icon(Icons.chevron_right_rounded),
                      onTap: () {
                        ref.read(adminStatusFilterProvider.notifier).setFilter('ALL');
                        context.push('/admin/requests');
                      },
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(Icons.tune_rounded, color: AppTheme.primaryColor),
                      title: const Text('Fee & Settings Manager'),
                      subtitle: const Text('Configure visit fee, offer labels, equipment types'),
                      trailing: const Icon(Icons.chevron_right_rounded),
                      onTap: () => context.push('/admin/settings'),
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(Icons.group_add_rounded, color: AppTheme.primaryColor),
                      title: const Text('Seed Technician Roster'),
                      subtitle: const Text('Initialize the 3 standard certified technicians if empty'),
                      trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14),
                      onTap: () async {
                        await techRepo.seedInitialTechniciansIfEmpty();
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Technicians checked / seeded successfully')),
                          );
                        }
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  final String label;
  final int count;
  final Color color;
  final IconData icon;
  final VoidCallback onTap;

  const _MetricCard({
    required this.label,
    required this.count,
    required this.color,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.spacingMd),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Icon(icon, color: color, size: 24),
                  Text(
                    count.toString(),
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                label,
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
