import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../providers/auth_providers.dart';
import '../../providers/request_providers.dart';
import '../../providers/technician_providers.dart';
import '../../providers/user_providers.dart';
import '../../theme/app_theme.dart';
import '../../utils/constants.dart';

/// Comprehensive operational dashboard for RioDent administrators.
/// Allows viewing all service bookings, technician dispatching, and registered clinic directory.
class AdminDashboardScreen extends ConsumerStatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  ConsumerState<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends ConsumerState<AdminDashboardScreen> with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final authRepo = ref.read(authRepositoryProvider);

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('RioDent Dispatch Console'),
        actions: [
          IconButton(
            icon: const Icon(Icons.tune_rounded),
            tooltip: 'Equipment Settings',
            onPressed: () => context.push('/admin/settings'),
          ),
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            tooltip: 'Sign Out',
            onPressed: () async => await authRepo.signOut(),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppTheme.primaryColor,
          unselectedLabelColor: AppTheme.textSecondary,
          indicatorColor: AppTheme.primaryColor,
          indicatorWeight: 3,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          tabs: const [
            Tab(
              icon: Icon(Icons.receipt_long_rounded, size: 20),
              text: 'Bookings Queue',
            ),
            Tab(
              icon: Icon(Icons.local_hospital_rounded, size: 20),
              text: 'Registered Doctors',
            ),
            Tab(
              icon: Icon(Icons.engineering_rounded, size: 20),
              text: 'Technicians',
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildBookingsQueueTab(theme),
          _buildDoctorsDirectoryTab(theme),
          _buildTechniciansTab(theme),
        ],
      ),
    );
  }

  // ── Tab 1: Bookings Queue ───────────────────────────────────────
  Widget _buildBookingsQueueTab(ThemeData theme) {
    final requestsAsync = ref.watch(adminRequestsProvider);
    final activeFilter = ref.watch(adminStatusFilterProvider);
    final dateFormat = DateFormat('MMM dd, hh:mm a');

    final filters = [
      'ALL',
      AppConstants.statusNew,
      AppConstants.statusAssigned,
      AppConstants.statusInProgress,
      AppConstants.statusCompleted,
    ];

    return RefreshIndicator(
      onRefresh: () async => ref.invalidate(adminRequestsProvider),
      child: Column(
        children: [
          // Filter Chips
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: filters.map((filter) {
                  final isSelected = activeFilter == filter;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(filter == 'ALL' ? 'All Bookings' : AppTheme.getStatusLabel(filter)),
                      selected: isSelected,
                      onSelected: (_) {
                        ref.read(adminStatusFilterProvider.notifier).setFilter(filter);
                      },
                      selectedColor: AppTheme.primaryLight,
                      labelStyle: TextStyle(
                        color: isSelected ? AppTheme.primaryColor : AppTheme.textSecondary,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        fontSize: 12,
                      ),
                      side: BorderSide(
                        color: isSelected ? AppTheme.primaryColor : AppTheme.cardBorderColor,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
          const Divider(height: 1),

          Expanded(
            child: requestsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Error loading requests: $e')),
              data: (requests) {
                if (requests.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Text(
                        'No requests currently in "${activeFilter == "ALL" ? "All Bookings" : AppTheme.getStatusLabel(activeFilter)}"',
                        style: theme.textTheme.bodyMedium?.copyWith(color: AppTheme.textSecondary),
                      ),
                    ),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.all(AppTheme.spacingMd),
                  itemCount: requests.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final req = requests[index];
                    final statusColor = AppTheme.getStatusColor(req.status);

                    return Card(
                      margin: EdgeInsets.zero,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                        onTap: () => context.push('/admin/requests/${req.id}'),
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
                                      req.clinicName.isNotEmpty ? req.clinicName : 'Dental Clinic',
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                    ),
                                  ),
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
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Doctor: ${req.dentistName} • Phone: ${req.dentistPhone}',
                                style: theme.textTheme.bodySmall,
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'Equipment: ${req.issueType} — ${req.issueDescription}',
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: theme.textTheme.bodyMedium,
                              ),
                              const Divider(height: 18),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      const Icon(Icons.verified_rounded, size: 14, color: AppTheme.successColor),
                                      const SizedBox(width: 4),
                                      const Text(
                                        'Charge: ₹0 (FREE APP)',
                                        style: TextStyle(
                                          color: AppTheme.successColor,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 11,
                                        ),
                                      ),
                                    ],
                                  ),
                                  Text(
                                    dateFormat.format(req.createdAt),
                                    style: theme.textTheme.labelSmall,
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      req.assignedTechnicianName != null
                                          ? 'Technician: ${req.assignedTechnicianName}'
                                          : '⚠️ No technician assigned yet',
                                      style: TextStyle(
                                        color: req.assignedTechnicianName != null
                                            ? AppTheme.primaryColor
                                            : AppTheme.warningColor,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                  OutlinedButton(
                                    style: OutlinedButton.styleFrom(
                                      minimumSize: const Size(90, 32),
                                      padding: const EdgeInsets.symmetric(horizontal: 10),
                                    ),
                                    onPressed: () => context.push('/admin/assign/${req.id}'),
                                    child: Text(req.assignedTechnicianName == null ? 'Assign' : 'Reassign'),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // ── Tab 2: Registered Doctors Directory ─────────────────────────
  Widget _buildDoctorsDirectoryTab(ThemeData theme) {
    final dentistsAsync = ref.watch(registeredDentistsProvider);
    final dateFormat = DateFormat('MMM dd, yyyy');

    return RefreshIndicator(
      onRefresh: () async => ref.invalidate(registeredDentistsProvider),
      child: dentistsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error loading doctor directory: $e')),
        data: (dentists) {
          if (dentists.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.people_outline_rounded, size: 56, color: AppTheme.textHint),
                    const SizedBox(height: 16),
                    Text(
                      'No Doctors Registered Yet',
                      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'When doctors sign up or register clinics, their profiles will appear here.',
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            );
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                color: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Total Registered Doctors: ${dentists.length}',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppTheme.successColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                      ),
                      child: const Text(
                        'Active Network',
                        style: TextStyle(color: AppTheme.successColor, fontSize: 11, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.all(AppTheme.spacingMd),
                  itemCount: dentists.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final dr = dentists[index];
                    return Card(
                      margin: EdgeInsets.zero,
                      child: Padding(
                        padding: const EdgeInsets.all(AppTheme.spacingMd),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                CircleAvatar(
                                  backgroundColor: AppTheme.primaryLight,
                                  child: const Icon(Icons.person_rounded, color: AppTheme.primaryColor),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        dr.displayName.isNotEmpty ? dr.displayName : 'Doctor',
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                      ),
                                      Text(
                                        dr.clinicName?.isNotEmpty == true ? dr.clinicName! : 'Clinic name pending',
                                        style: TextStyle(color: AppTheme.primaryColor, fontWeight: FontWeight.w600, fontSize: 13),
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: dr.profileComplete ? AppTheme.successColor.withValues(alpha: 0.12) : AppTheme.warningColor.withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                                  ),
                                  child: Text(
                                    dr.profileComplete ? 'Verified' : 'New',
                                    style: TextStyle(
                                      color: dr.profileComplete ? AppTheme.successColor : AppTheme.warningColor,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 11,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const Divider(height: 18),
                            if (dr.clinicAddress?.isNotEmpty == true) ...[
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Icon(Icons.location_on_outlined, size: 16, color: AppTheme.textSecondary),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      dr.clinicAddress!,
                                      style: theme.textTheme.bodySmall,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                            ],
                            Row(
                              children: [
                                const Icon(Icons.phone_outlined, size: 16, color: AppTheme.textSecondary),
                                const SizedBox(width: 6),
                                Text(
                                  dr.phone.isNotEmpty ? dr.phone : 'Not provided',
                                  style: theme.textTheme.bodySmall,
                                ),
                                const Spacer(),
                                Text(
                                  'Registered: ${dateFormat.format(dr.createdAt)}',
                                  style: theme.textTheme.labelSmall,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  // ── Tab 3: Certified Technicians ────────────────────────────────
  Widget _buildTechniciansTab(ThemeData theme) {
    final techRepo = ref.read(technicianRepositoryProvider);
    final techsAsync = ref.watch(techniciansProvider);

    return RefreshIndicator(
      onRefresh: () async => ref.invalidate(techniciansProvider),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(AppTheme.spacingMd),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                border: Border.all(color: AppTheme.cardBorderColor),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Certified Technician Roster', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size(110, 36),
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                        ),
                        onPressed: () async {
                          final messenger = ScaffoldMessenger.of(context);
                          await techRepo.seedInitialTechniciansIfEmpty();
                          ref.invalidate(techniciansProvider);
                          if (mounted) {
                            messenger.showSnackBar(
                              const SnackBar(content: Text('Technicians checked / seeded successfully')),
                            );
                          }
                        },
                        icon: const Icon(Icons.sync_rounded, size: 16),
                        label: const Text('Seed Roster'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Certified technicians dispatched to clinics in Bengaluru, Hyderabad, and surrounding areas.',
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            techsAsync.when(
              loading: () => const Center(child: Padding(padding: EdgeInsets.all(32), child: CircularProgressIndicator())),
              error: (e, _) => Center(child: Text('Error loading technicians: $e')),
              data: (techs) {
                if (techs.isEmpty) {
                  return Card(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        children: [
                          const Icon(Icons.engineering_outlined, size: 48, color: AppTheme.textHint),
                          const SizedBox(height: 12),
                          const Text('No technicians found in database.'),
                          const SizedBox(height: 12),
                          ElevatedButton(
                            onPressed: () async {
                              await techRepo.seedInitialTechniciansIfEmpty();
                              ref.invalidate(techniciansProvider);
                            },
                            child: const Text('Seed 3 Standard Technicians'),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return Column(
                  children: techs.map((tech) {
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: Padding(
                        padding: const EdgeInsets.all(AppTheme.spacingMd),
                        child: Row(
                          children: [
                            CircleAvatar(
                              backgroundColor: AppTheme.secondaryLight,
                              child: const Icon(Icons.handyman_rounded, color: AppTheme.secondaryColor),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    tech.name,
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Specialty: ${tech.specialization}',
                                    style: TextStyle(color: AppTheme.primaryColor, fontSize: 13, fontWeight: FontWeight.w500),
                                  ),
                                  Text(
                                    'Phone: ${tech.phone}',
                                    style: theme.textTheme.bodySmall,
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: tech.isActive ? AppTheme.successColor.withValues(alpha: 0.1) : AppTheme.textHint.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                              ),
                              child: Text(
                                tech.isActive ? 'Available' : 'Busy',
                                style: TextStyle(
                                  color: tech.isActive ? AppTheme.successColor : AppTheme.textHint,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 11,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
