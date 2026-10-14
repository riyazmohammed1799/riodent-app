import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../models/technician_model.dart';
import '../../providers/auth_providers.dart';
import '../../providers/request_providers.dart';
import '../../providers/technician_providers.dart';
import '../../providers/user_providers.dart';
import '../../theme/app_theme.dart';
import '../../utils/constants.dart';
import '../../utils/validators.dart';

/// Operational console for RioDent administrators.
/// Implements Section 3.8:
/// Bottom navigation: Dashboard (0), Bookings (1), Doctors (2), Technicians (3), Settings (4).
class AdminDashboardScreen extends ConsumerStatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  ConsumerState<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends ConsumerState<AdminDashboardScreen> {
  int _selectedTabIndex = 0;

  // Bookings tab state
  String _bookingStatusFilter = 'ALL';
  String _bookingSearchQuery = '';

  // Doctors tab state
  String _doctorSearchQuery = '';

  void _navigateToBookingsWithFilter(String status) {
    setState(() {
      _selectedTabIndex = 1;
      _bookingStatusFilter = status;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: Text(_tabTitle(_selectedTabIndex)),
        actions: [
          if (_selectedTabIndex == 4) ...[
            IconButton(
              icon: const Icon(Icons.settings_outlined),
              tooltip: 'Advanced Settings',
              onPressed: () => context.push('/admin/settings'),
            ),
          ],
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            tooltip: 'Sign Out',
            onPressed: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Admin Sign Out'),
                  content: const Text('Are you sure you want to sign out of RioDent Admin Console?'),
                  actions: [
                    TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancel')),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryColor),
                      onPressed: () => Navigator.of(ctx).pop(true),
                      child: const Text('Sign Out'),
                    ),
                  ],
                ),
              );
              if (confirm == true) {
                await ref.read(authRepositoryProvider).signOut();
              }
            },
          ),
        ],
      ),
      body: IndexedStack(
        index: _selectedTabIndex,
        children: [
          _buildExecutiveDashboardTab(),
          _buildBookingsTab(),
          _buildDoctorsTab(),
          _buildTechniciansTab(),
          _buildSettingsTab(),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedTabIndex,
        onTap: (index) => setState(() => _selectedTabIndex = index),
        type: BottomNavigationBarType.fixed,
        selectedItemColor: AppTheme.primaryColor,
        unselectedItemColor: AppTheme.textSecondary,
        selectedFontSize: 11,
        unselectedFontSize: 11,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard_rounded),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.receipt_long_rounded),
            label: 'Bookings',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.local_hospital_rounded),
            label: 'Doctors',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.engineering_rounded),
            label: 'Technicians',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.tune_rounded),
            label: 'Settings',
          ),
        ],
      ),
    );
  }

  String _tabTitle(int index) {
    switch (index) {
      case 0:
        return 'Executive Overview';
      case 1:
        return 'Bookings Dispatch Queue';
      case 2:
        return 'Registered Clinics Directory';
      case 3:
        return 'Field Technicians Roster';
      case 4:
        return 'Platform Settings';
      default:
        return 'RioDent Admin';
    }
  }

  // ══════════════════════════════════════════════════════════════════
  // TAB 0: Executive Dashboard
  // ══════════════════════════════════════════════════════════════════
  Widget _buildExecutiveDashboardTab() {
    final needsAttentionAsync = ref.watch(adminNeedsAttentionProvider);
    final newCountAsync = ref.watch(adminStatusCountProvider(AppConstants.statusNew));
    final assignedCountAsync = ref.watch(adminStatusCountProvider(AppConstants.statusAssigned));
    final inProgressCountAsync = ref.watch(adminStatusCountProvider(AppConstants.statusInProgress));
    final completedCountAsync = ref.watch(adminStatusCountProvider(AppConstants.statusCompleted));
    final cancelledCountAsync = ref.watch(adminStatusCountProvider(AppConstants.statusCancelled));
    final doctorCountAsync = ref.watch(dentistCountProvider);
    final activeTechsCountAsync = ref.watch(activeTechnicianCountProvider);
    final totalRevenueAsync = ref.watch(adminTotalRevenueProvider);

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(adminNeedsAttentionProvider);
        ref.invalidate(dentistCountProvider);
        ref.invalidate(activeTechnicianCountProvider);
        ref.invalidate(adminTotalRevenueProvider);
      },
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppTheme.spacingMd),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 1. Needs Attention Section
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF2F2),
                borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                border: Border.all(color: const Color(0xFFFECACA)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.warning_amber_rounded, color: AppTheme.errorColor, size: 20),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Needs Attention',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF991B1B)),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Tickets pending > 2 hours, today\'s slots without technician, or stalled tickets > 48 hours.',
                    style: TextStyle(fontSize: 12, color: Color(0xFF7F1D1D)),
                  ),
                  const SizedBox(height: 12),
                  needsAttentionAsync.when(
                    loading: () => const Center(child: Padding(padding: EdgeInsets.all(8), child: CircularProgressIndicator())),
                    error: (err, _) => Text('Error: $err'),
                    data: (attentionItems) {
                      if (attentionItems.isEmpty) {
                        return Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                          ),
                          child: const Row(
                            children: [
                              Icon(Icons.check_circle_rounded, color: AppTheme.successColor, size: 18),
                              SizedBox(width: 8),
                              Expanded(
                                child: Text('No urgent items! All bookings dispatched on time.', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                              ),
                            ],
                          ),
                        );
                      }

                      return Column(
                        children: attentionItems.take(5).map((item) {
                          return Container(
                            margin: const EdgeInsets.only(bottom: 6),
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                              border: Border.all(color: const Color(0xFFFCA5A5)),
                            ),
                            child: InkWell(
                              onTap: () => context.push('/admin/requests/${item.id}'),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          '${item.displayTicketId} • ${item.clinicName}',
                                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        Text(
                                          '${item.issueLabel} • Status: ${AppTheme.getStatusLabel(item.status)}',
                                          style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppTheme.primaryColor),
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

            const SizedBox(height: 20),

            // 2. Executive KPIs (All Tappable)
            const Text(
              'Key Operations Metrics',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
            ),
            const SizedBox(height: 10),

            // Status Metric Grid
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: 1.15,
              children: [
                _buildKpiCard(
                  title: 'Pending Dispatch',
                  count: newCountAsync.value?.toString() ?? '...',
                  color: AppTheme.statusNew,
                  icon: Icons.hourglass_top_rounded,
                  onTap: () => _navigateToBookingsWithFilter(AppConstants.statusNew),
                ),
                _buildKpiCard(
                  title: 'Assigned Leads',
                  count: assignedCountAsync.value?.toString() ?? '...',
                  color: AppTheme.statusAssigned,
                  icon: Icons.person_pin_circle_rounded,
                  onTap: () => _navigateToBookingsWithFilter(AppConstants.statusAssigned),
                ),
                _buildKpiCard(
                  title: 'In Progress Visits',
                  count: inProgressCountAsync.value?.toString() ?? '...',
                  color: AppTheme.statusInProgress,
                  icon: Icons.engineering_rounded,
                  onTap: () => _navigateToBookingsWithFilter(AppConstants.statusInProgress),
                ),
                _buildKpiCard(
                  title: 'Completed Repairs',
                  count: completedCountAsync.value?.toString() ?? '...',
                  color: AppTheme.statusCompleted,
                  icon: Icons.check_circle_rounded,
                  onTap: () => _navigateToBookingsWithFilter(AppConstants.statusCompleted),
                ),
                _buildKpiCard(
                  title: 'Cancelled / Denied',
                  count: cancelledCountAsync.value?.toString() ?? '...',
                  color: AppTheme.statusCancelled,
                  icon: Icons.cancel_rounded,
                  onTap: () => _navigateToBookingsWithFilter(AppConstants.statusCancelled),
                ),
                _buildKpiCard(
                  title: 'Registered Doctors',
                  count: doctorCountAsync.value?.toString() ?? '...',
                  color: AppTheme.primaryColor,
                  icon: Icons.local_hospital_rounded,
                  onTap: () => setState(() => _selectedTabIndex = 2),
                ),
                _buildKpiCard(
                  title: 'Active Technicians',
                  count: activeTechsCountAsync.value?.toString() ?? '...',
                  color: const Color(0xFF0D9488),
                  icon: Icons.build_circle_rounded,
                  onTap: () => setState(() => _selectedTabIndex = 3),
                ),
                _buildKpiCard(
                  title: 'Paid to Technicians',
                  count: totalRevenueAsync.when(
                    data: (v) => '₹${v.toInt()}',
                    loading: () => '...',
                    error: (err, stack) => '₹0',
                  ),
                  color: const Color(0xFF15803D),
                  icon: Icons.currency_rupee_rounded,
                  onTap: () => _navigateToBookingsWithFilter(AppConstants.statusCompleted),
                ),
              ],
            ),

            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildKpiCard({
    required String title,
    required String count,
    required Color color,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(AppTheme.radiusMd),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
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
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Icon(icon, size: 18, color: color),
                const SizedBox(width: 4),
                Flexible(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      count,
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: color),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppTheme.textPrimary),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const Text(
              'Tap to inspect list',
              style: TextStyle(fontSize: 10, color: AppTheme.textHint),
            ),
          ],
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════
  // TAB 1: Bookings Dispatch Queue
  // ══════════════════════════════════════════════════════════════════
  Widget _buildBookingsTab() {
    final statusFilter = _bookingStatusFilter;
    final requestsAsync = ref.watch(adminRequestsProvider);

    final filterOptions = [
      {'key': 'ALL', 'label': 'All'},
      {'key': AppConstants.statusNew, 'label': 'Pending'},
      {'key': AppConstants.statusAssigned, 'label': 'Assigned'},
      {'key': AppConstants.statusInProgress, 'label': 'In Progress'},
      {'key': AppConstants.statusCompleted, 'label': 'Completed'},
      {'key': AppConstants.statusCancelled, 'label': 'Cancelled'},
    ];

    return Column(
      children: [
        // Search & Filter Header
        Container(
          color: Colors.white,
          padding: const EdgeInsets.all(AppTheme.spacingMd),
          child: Column(
            children: [
              TextField(
                decoration: const InputDecoration(
                  hintText: 'Search by clinic, doctor, mobile, or ID...',
                  prefixIcon: Icon(Icons.search_rounded),
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                ),
                onChanged: (val) => setState(() => _bookingSearchQuery = val.trim().toLowerCase()),
              ),
              const SizedBox(height: 10),
              SizedBox(
                height: 36,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: filterOptions.length,
                  separatorBuilder: (_, i) => const SizedBox(width: 8),
                  itemBuilder: (context, index) {
                    final f = filterOptions[index];
                    final isSelected = statusFilter == f['key'];
                    return ChoiceChip(
                      label: Text(f['label']!),
                      selected: isSelected,
                      onSelected: (selected) {
                        if (selected) {
                          setState(() => _bookingStatusFilter = f['key']!);
                          ref.read(adminStatusFilterProvider.notifier).setFilter(f['key']!);
                        }
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
        const Divider(height: 1),

        // Bookings List (sorted by slot time)
        Expanded(
          child: requestsAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, _) => Center(child: Text('Error: $err')),
            data: (requests) {
              final query = _bookingSearchQuery;
              final filtered = requests.where((r) {
                if (query.isEmpty) return true;
                return r.clinicName.toLowerCase().contains(query) ||
                    r.dentistName.toLowerCase().contains(query) ||
                    r.mobile.contains(query) ||
                    r.displayTicketId.toLowerCase().contains(query);
              }).toList();

              if (filtered.isEmpty) {
                return const Center(child: Text('No bookings match your filter/search criteria.'));
              }

              return RefreshIndicator(
                onRefresh: () async => ref.invalidate(adminRequestsProvider),
                child: ListView.separated(
                  padding: const EdgeInsets.all(AppTheme.spacingMd),
                  itemCount: filtered.length,
                  separatorBuilder: (_, i) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final req = filtered[index];
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
                                  Text(
                                    req.displayTicketId,
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.primaryDark),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
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
                                req.clinicName.isNotEmpty ? req.clinicName : 'Clinic',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                              ),
                              Text(
                                '${req.issueLabel} • ${req.dentistName} (${req.mobile})',
                                style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                              ),
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  const Icon(Icons.schedule_rounded, size: 14, color: AppTheme.textSecondary),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Slot: ${req.slotDate.isNotEmpty ? req.slotDate : DateFormat('MMM dd').format(req.slotStart)} (${DateFormat('h:mm a').format(req.slotStart)})',
                                    style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                                  ),
                                ],
                              ),
                              const Divider(height: 16),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    req.assignedTechnicianName != null
                                        ? 'Tech: ${req.assignedTechnicianName}'
                                        : 'Needs Tech Assignment',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: req.assignedTechnicianName != null ? AppTheme.primaryColor : AppTheme.errorColor,
                                    ),
                                  ),
                                  const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppTheme.textHint),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  // ══════════════════════════════════════════════════════════════════
  // TAB 2: Registered Doctors Directory
  // ══════════════════════════════════════════════════════════════════
  Widget _buildDoctorsTab() {
    final doctorsAsync = ref.watch(registeredDentistsProvider);

    return Column(
      children: [
        Container(
          color: Colors.white,
          padding: const EdgeInsets.all(AppTheme.spacingMd),
          child: TextField(
            decoration: const InputDecoration(
              hintText: 'Search clinic by name, phone, or address...',
              prefixIcon: Icon(Icons.search_rounded),
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            ),
            onChanged: (val) => setState(() => _doctorSearchQuery = val.trim().toLowerCase()),
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: doctorsAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, _) => Center(child: Text('Error: $err')),
            data: (doctors) {
              final query = _doctorSearchQuery;
              final filtered = doctors.where((d) {
                if (query.isEmpty) return true;
                return d.displayName.toLowerCase().contains(query) ||
                    (d.clinicName?.toLowerCase().contains(query) ?? false) ||
                    d.phone.contains(query);
              }).toList();

              if (filtered.isEmpty) {
                return const Center(child: Text('No clinics found.'));
              }

              return RefreshIndicator(
                onRefresh: () async => ref.invalidate(registeredDentistsProvider),
                child: ListView.separated(
                  padding: const EdgeInsets.all(AppTheme.spacingMd),
                  itemCount: filtered.length,
                  separatorBuilder: (_, i) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final doc = filtered[index];
                    return Card(
                      margin: EdgeInsets.zero,
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: AppTheme.primaryLight,
                          child: const Icon(Icons.apartment_rounded, color: AppTheme.primaryColor),
                        ),
                        title: Text(
                          doc.clinicName?.isNotEmpty == true ? doc.clinicName! : doc.displayName,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                        subtitle: Text(
                          '${doc.displayName} • ${doc.phone}\n${doc.clinicAddress ?? 'Hyderabad'}',
                          style: const TextStyle(fontSize: 12),
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.phone_outlined, color: AppTheme.primaryColor),
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Dialing ${doc.phone}')),
                            );
                          },
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  // ══════════════════════════════════════════════════════════════════
  // TAB 3: Field Technicians Roster (Add, Edit, Deactivate)
  // ══════════════════════════════════════════════════════════════════
  Widget _buildTechniciansTab() {
    final techniciansAsync = ref.watch(techniciansProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: techniciansAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Error: $err')),
        data: (techs) {
          if (techs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.engineering_outlined, size: 54, color: AppTheme.textHint),
                  const SizedBox(height: 12),
                  const Text('No technicians in roster.', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  ElevatedButton.icon(
                    onPressed: _showAddTechnicianDialog,
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('Add Field Technician'),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(techniciansProvider),
            child: ListView.separated(
              padding: const EdgeInsets.all(AppTheme.spacingMd),
              itemCount: techs.length,
              separatorBuilder: (_, i) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final tech = techs[index];
                return Card(
                  margin: EdgeInsets.zero,
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: tech.isActive ? const Color(0xFFE0F2FE) : const Color(0xFFF3F4F6),
                      child: Icon(
                        Icons.engineering_rounded,
                        color: tech.isActive ? AppTheme.primaryColor : AppTheme.textHint,
                      ),
                    ),
                    title: Text(
                      tech.name,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        decoration: tech.isActive ? null : TextDecoration.lineThrough,
                      ),
                    ),
                    subtitle: Text(
                      '${tech.phone} • Area: ${tech.area ?? 'Hyderabad'}\n${tech.specialization ?? 'General Dental Equipment'}',
                      style: const TextStyle(fontSize: 12),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit_outlined, size: 20),
                          onPressed: () => _showEditTechnicianDialog(tech),
                        ),
                        Switch(
                          value: tech.isActive,
                          onChanged: (val) async {
                            await ref.read(technicianRepositoryProvider).toggleTechnicianActive(
                              id: tech.id,
                              isActive: val,
                            );
                            ref.invalidate(techniciansProvider);
                            ref.invalidate(activeTechniciansProvider);
                          },
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        onPressed: _showAddTechnicianDialog,
        icon: const Icon(Icons.person_add_rounded),
        label: const Text('Add Technician'),
      ),
    );
  }

  void _showAddTechnicianDialog() {
    final nameCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final areaCtrl = TextEditingController();
    final specCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Field Technician'),
        content: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(labelText: 'Technician Name *'),
                  validator: (val) => Validators.required(val, 'Name'),
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: phoneCtrl,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(labelText: 'Phone Number *'),
                  validator: Validators.phoneNumber,
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: areaCtrl,
                  decoration: const InputDecoration(labelText: 'Service Area (e.g. Banjara Hills)'),
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: specCtrl,
                  decoration: const InputDecoration(labelText: 'Specialization (e.g. Chairs & Compressors)'),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              if (formKey.currentState!.validate()) {
                await ref.read(technicianRepositoryProvider).addTechnician(
                  name: nameCtrl.text.trim(),
                  phone: phoneCtrl.text.trim(),
                  area: areaCtrl.text.trim(),
                  specialization: specCtrl.text.trim(),
                );
                ref.invalidate(techniciansProvider);
                ref.invalidate(activeTechniciansProvider);
                if (ctx.mounted) Navigator.of(ctx).pop();
              }
            },
            child: const Text('Save Technician'),
          ),
        ],
      ),
    );
  }

  void _showEditTechnicianDialog(TechnicianModel tech) {
    final nameCtrl = TextEditingController(text: tech.name);
    final phoneCtrl = TextEditingController(text: tech.phone);
    final areaCtrl = TextEditingController(text: tech.area ?? '');
    final specCtrl = TextEditingController(text: tech.specialization ?? '');
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Edit Technician'),
        content: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(labelText: 'Name *'),
                  validator: (val) => Validators.required(val, 'Name'),
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: phoneCtrl,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(labelText: 'Phone *'),
                  validator: Validators.phoneNumber,
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: areaCtrl,
                  decoration: const InputDecoration(labelText: 'Area'),
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: specCtrl,
                  decoration: const InputDecoration(labelText: 'Specialization'),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              if (formKey.currentState!.validate()) {
                await ref.read(technicianRepositoryProvider).updateTechnician(
                  id: tech.id,
                  name: nameCtrl.text.trim(),
                  phone: phoneCtrl.text.trim(),
                  area: areaCtrl.text.trim(),
                  specialization: specCtrl.text.trim(),
                );
                ref.invalidate(techniciansProvider);
                ref.invalidate(activeTechniciansProvider);
                if (ctx.mounted) Navigator.of(ctx).pop();
              }
            },
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════
  // TAB 4: Settings Tab
  // ══════════════════════════════════════════════════════════════════
  Widget _buildSettingsTab() {
    return SingleChildScrollView(
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
                const Text(
                  'RioDent Operational Configuration',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Manage equipment categories, time slot windows, Hyderabad serviceable pincodes, and cancellation reasons without releasing a new app build.',
                  style: TextStyle(fontSize: 13, color: AppTheme.textSecondary),
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () => context.push('/admin/settings'),
                  icon: const Icon(Icons.tune_rounded),
                  label: const Text('Open System Configuration Editor'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
