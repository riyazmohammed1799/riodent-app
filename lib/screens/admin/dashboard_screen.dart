import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../models/booking_config_model.dart';
import '../../models/riodent_share_model.dart';
import '../../models/technician_model.dart';
import '../../providers/auth_providers.dart';
import '../../providers/request_providers.dart';
import '../../providers/settings_providers.dart';
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
  String _bookingSearchQuery = '';

  // Doctors tab state
  String _doctorSearchQuery = '';

  // Settings tab state
  final _newCategoryController = TextEditingController();
  final _supportPhoneController = TextEditingController();
  final _pincodesController = TextEditingController();
  final _maxDaysController = TextEditingController();
  final _maxOpenRequestsController = TextEditingController();
  bool _isSettingsInitialized = false;
  bool _isSavingSettings = false;

  @override
  void dispose() {
    _newCategoryController.dispose();
    _supportPhoneController.dispose();
    _pincodesController.dispose();
    _maxDaysController.dispose();
    _maxOpenRequestsController.dispose();
    super.dispose();
  }

  void _navigateToBookingsWithFilter(String status) {
    setState(() {
      _selectedTabIndex = 1;
    });
    ref.read(adminStatusFilterProvider.notifier).setFilter(status);
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        if (_selectedTabIndex != 0) {
          setState(() => _selectedTabIndex = 0);
        } else {
          // Stay on admin dashboard, or let system handle if root
        }
      },
      child: Scaffold(
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
    final newCountAsync = ref.watch(adminStatusCountProvider(AppConstants.statusNew));
    final assignedCountAsync = ref.watch(adminStatusCountProvider(AppConstants.statusAssigned));
    final completedCountAsync = ref.watch(adminStatusCountProvider(AppConstants.statusCompleted));
    final cancelledCountAsync = ref.watch(adminStatusCountProvider(AppConstants.statusCancelled));
    final clinicCountAsync = ref.watch(dentistCountProvider);
    final registeredTechsCountAsync = ref.watch(registeredTechnicianCountProvider);
    final activeTechsCountAsync = ref.watch(activeTechnicianCountProvider);
    final totalRevenueAsync = ref.watch(adminTotalRevenueProvider);
    final riodentShareAsync = ref.watch(riodentShareSummaryProvider);

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(dentistCountProvider);
        ref.invalidate(registeredTechnicianCountProvider);
        ref.invalidate(activeTechnicianCountProvider);
        ref.invalidate(adminTotalRevenueProvider);
        ref.invalidate(riodentShareSummaryProvider);
      },
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppTheme.spacingMd),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 1. Dedicated RioDent Share Accounting Section (Section 17)
            _buildRioDentShareCard(riodentShareAsync),

            const SizedBox(height: 20),

            // 2. Executive KPIs (All Tappable)
            const Text(
              'Key Operations Metrics',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
            ),
            const SizedBox(height: 10),

            // Status Metric Grid (No In Progress, Added Registered Clinics)
            LayoutBuilder(
              builder: (context, constraints) {
                final isWide = constraints.maxWidth > 700;
                return GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: isWide ? 4 : 2,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                  childAspectRatio: isWide ? 1.4 : 1.15,
                  children: [
                    _buildKpiCard(
                      title: 'Pending Leads',
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
                      title: 'Registered Clinics',
                      count: clinicCountAsync.value?.toString() ?? '...',
                      color: AppTheme.primaryColor,
                      icon: Icons.apartment_rounded,
                      onTap: () => setState(() => _selectedTabIndex = 2),
                    ),
                    _buildKpiCard(
                      title: 'Field Technicians',
                      count: '${registeredTechsCountAsync.value ?? 0} (${activeTechsCountAsync.value ?? 0} Active)',
                      color: const Color(0xFF0D9488),
                      icon: Icons.engineering_rounded,
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
                );
              },
            ),

            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════
  // Section 17: RioDent Share Accounting Card & Settlement
  // ══════════════════════════════════════════════════════════════════
  Widget _buildRioDentShareCard(AsyncValue<RioDentShareSummary> shareAsync) {
    return shareAsync.when(
      loading: () => Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          border: Border.all(color: AppTheme.cardBorderColor),
        ),
        child: const Center(child: CircularProgressIndicator()),
      ),
      error: (err, _) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFFEF2F2),
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          border: Border.all(color: const Color(0xFFFECACA)),
        ),
        child: Text('Error loading RioDent Share: $err'),
      ),
      data: (share) {
        final hasUnsettled = share.unsettledShare > 0;

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(AppTheme.radiusMd),
            border: Border.all(color: const Color(0xFFCBD5E1), width: 1.5),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEFF6FF),
                      borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                    ),
                    child: const Icon(Icons.account_balance_wallet_rounded, color: AppTheme.primaryColor, size: 24),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Expanded(
                              child: Text(
                                'RioDent Share Accounting',
                                style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: AppTheme.textPrimary),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFEF3C7),
                                borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                                border: Border.all(color: const Color(0xFFFDE68A)),
                              ),
                              child: const Text(
                                '10% Share Rate',
                                style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF92400E)),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        const Text(
                          '10% of eligible amounts paid to doctors • Technician fees remain intact & separate',
                          style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Divider(height: 1),
              const SizedBox(height: 14),

              // Metrics Grid
              LayoutBuilder(
                builder: (context, constraints) {
                  final isWide = constraints.maxWidth > 500;
                  return GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: isWide ? 4 : 2,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                    childAspectRatio: isWide ? 1.6 : 1.35,
                    children: [
                      _buildShareMetricBox(
                        label: 'Total Doctor Paid',
                        value: '₹${share.totalDoctorPaid.toInt()}',
                        color: AppTheme.textPrimary,
                        subtitle: '${share.eligibleBillsCount} eligible bills',
                      ),
                      _buildShareMetricBox(
                        label: 'Total Share Earned',
                        value: '₹${share.totalShareEarned.toInt()}',
                        color: const Color(0xFF2563EB),
                        subtitle: '10% calculation',
                      ),
                      _buildShareMetricBox(
                        label: 'Total Share Settled',
                        value: '₹${share.totalShareSettled.toInt()}',
                        color: const Color(0xFF16A34A),
                        subtitle: 'Recorded settlements',
                      ),
                      _buildShareMetricBox(
                        label: 'Current Unsettled',
                        value: '₹${share.unsettledShare.toInt()}',
                        color: hasUnsettled ? const Color(0xFFD97706) : const Color(0xFF16A34A),
                        subtitle: hasUnsettled ? 'Pending settlement' : 'Fully settled',
                        highlight: hasUnsettled,
                      ),
                    ],
                  );
                },
              ),

              // Latest settlement information
              if (share.latestSettlement != null) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.history_rounded, size: 14, color: AppTheme.textSecondary),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          'Latest settlement: ₹${share.latestSettlement!.amountSettled.toInt()} on ${DateFormat('dd MMM yyyy, h:mm a').format(share.latestSettlement!.settledAt)} by ${share.latestSettlement!.settledBy}',
                          style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 14),

              // Actions: Settle Share & Financial Ledger
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: hasUnsettled ? const Color(0xFF0F766E) : Colors.grey.shade400,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      onPressed: hasUnsettled ? () => _showSettleShareDialog(share) : null,
                      icon: const Icon(Icons.check_circle_outline_rounded, size: 18),
                      label: Text(
                        hasUnsettled ? 'Settle Share (₹${share.unsettledShare.toInt()})' : 'All Share Settled',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      side: const BorderSide(color: AppTheme.primaryColor),
                    ),
                    onPressed: () => _showFinancialLedgerDialog(share),
                    icon: const Icon(Icons.receipt_long_rounded, size: 18, color: AppTheme.primaryColor),
                    label: const Text('Ledger & Batches', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildShareMetricBox({
    required String label,
    required String value,
    required Color color,
    required String subtitle,
    bool highlight = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: highlight ? const Color(0xFFFEF3C7).withValues(alpha: 0.5) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(AppTheme.radiusSm),
        border: Border.all(
          color: highlight ? const Color(0xFFF59E0B) : const Color(0xFFE2E8F0),
          width: highlight ? 1.5 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppTheme.textSecondary),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: color),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: const TextStyle(fontSize: 10, color: AppTheme.textHint),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  /// Opens the confirmation dialog for settling the outstanding RioDent Share.
  void _showSettleShareDialog(RioDentShareSummary share) {
    final unsettledBills = share.bills.where((b) => !b.isSettled).toList();
    final notesController = TextEditingController();
    bool isSubmitting = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.radiusMd)),
            title: const Row(
              children: [
                Icon(Icons.verified_rounded, color: Color(0xFF0F766E), size: 24),
                SizedBox(width: 8),
                Text('Settle RioDent Share', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0FDF4),
                      borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                      border: Border.all(color: const Color(0xFFBBF7D0)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Unsettled 10% Share Amount:',
                          style: TextStyle(fontSize: 12, color: Color(0xFF166534)),
                        ),
                        Text(
                          '₹${share.unsettledShare.toInt()}',
                          style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: Color(0xFF166534)),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'From ${unsettledBills.length} eligible completed doctor bill(s)',
                          style: const TextStyle(fontSize: 11, color: Color(0xFF166534)),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  const Text(
                    'Critical Accounting Guarantees:',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    '• Settlement resets ONLY the outstanding RioDent Share balance.\n'
                    '• Historical doctor payments and technician payments remain 100% intact.\n'
                    '• Cumulative earned share (₹) is never wiped out.\n'
                    '• An auditable settlement record is permanently created.',
                    style: TextStyle(fontSize: 11, color: AppTheme.textSecondary, height: 1.4),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: notesController,
                    decoration: const InputDecoration(
                      labelText: 'Settlement Notes / Reference (Optional)',
                      hintText: 'e.g. Received via Bank Transfer / Batch #01',
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: isSubmitting ? null : () => Navigator.of(ctx).pop(),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0F766E),
                  foregroundColor: Colors.white,
                ),
                onPressed: isSubmitting
                    ? null
                    : () async {
                        final messenger = ScaffoldMessenger.of(context);
                        setDialogState(() => isSubmitting = true);
                        try {
                          final unsettledIds = unsettledBills.map((b) => b.ticketId).toList();
                          await ref.read(requestRepositoryProvider).settleRioDentShare(
                            amountToSettle: share.unsettledShare,
                            adminEmail: 'riyaz.mohammed1799@gmail.com',
                            requestIds: unsettledIds,
                            notes: notesController.text.trim(),
                          );
                          ref.invalidate(riodentShareSummaryProvider);
                          ref.invalidate(riodentSettlementsProvider);
                          if (ctx.mounted) Navigator.of(ctx).pop();
                          if (mounted) {
                            messenger.showSnackBar(
                              SnackBar(
                                backgroundColor: AppTheme.successColor,
                                content: Text('Settled ₹${share.unsettledShare.toInt()} successfully!'),
                              ),
                            );
                          }
                        } catch (e) {
                          setDialogState(() => isSubmitting = false);
                          if (mounted) {
                            messenger.showSnackBar(
                              SnackBar(content: Text('Settlement error: $e')),
                            );
                          }
                        }
                      },
                child: isSubmitting
                    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Text('Confirm Settlement'),
              ),
            ],
          );
        },
      ),
    );
  }

  /// Opens the Financial Ledger & Settlement Batches history modal.
  void _showFinancialLedgerDialog(RioDentShareSummary share) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => DefaultTabController(
        length: 2,
        child: Container(
          height: MediaQuery.of(ctx).size.height * 0.85,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // Handle
              const SizedBox(height: 10),
              Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2))),
              const SizedBox(height: 10),

              // Title
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'RioDent Share Ledger & Batches',
                      style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded),
                      onPressed: () => Navigator.of(ctx).pop(),
                    ),
                  ],
                ),
              ),

              const TabBar(
                labelColor: AppTheme.primaryColor,
                unselectedLabelColor: AppTheme.textSecondary,
                indicatorColor: AppTheme.primaryColor,
                tabs: [
                  Tab(text: 'Per-Bill Accounting'),
                  Tab(text: 'Settlement Batches'),
                ],
              ),

              Expanded(
                child: TabBarView(
                  children: [
                    // Tab 1: Per-Bill Accounting
                    share.bills.isEmpty
                        ? const Center(child: Text('No completed bills with recorded payments yet.'))
                        : ListView.separated(
                            padding: const EdgeInsets.all(AppTheme.spacingMd),
                            itemCount: share.bills.length,
                            separatorBuilder: (_, i) => const Divider(height: 12),
                            itemBuilder: (context, i) {
                              final b = share.bills[i];
                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        b.displayTicketId,
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.primaryDark),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: b.isSettled ? const Color(0xFFDCFCE7) : const Color(0xFFFEF3C7),
                                          borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                                        ),
                                        child: Text(
                                          b.isSettled ? 'Settled' : 'Unsettled',
                                          style: TextStyle(
                                            color: b.isSettled ? const Color(0xFF166534) : const Color(0xFF92400E),
                                            fontWeight: FontWeight.bold,
                                            fontSize: 10,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${b.clinicName} • Dr. ${b.doctorName}',
                                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                                  ),
                                  Text(
                                    'Bill Date: ${DateFormat('dd MMM yyyy').format(b.billDate)}',
                                    style: const TextStyle(fontSize: 11, color: AppTheme.textHint),
                                  ),
                                  const SizedBox(height: 6),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text('Paid to Doctor: ₹${b.doctorPaymentAmount.toInt()}', style: const TextStyle(fontSize: 12)),
                                      Text(
                                        '10% Share: ₹${b.calculatedShare.toInt()}',
                                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF2563EB)),
                                      ),
                                    ],
                                  ),
                                  Text(
                                    'Technician Payment (separate): ₹${b.technicianPaymentAmount.toInt()}',
                                    style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary),
                                  ),
                                ],
                              );
                            },
                          ),

                    // Tab 2: Settlement Batches
                    Consumer(
                      builder: (context, ref, _) {
                        final settlementsAsync = ref.watch(riodentSettlementsProvider);
                        return settlementsAsync.when(
                          loading: () => const Center(child: CircularProgressIndicator()),
                          error: (e, _) => Center(child: Text('Error: $e')),
                          data: (batches) {
                            if (batches.isEmpty) {
                              return const Center(
                                child: Text('No settlements recorded yet. Use "Settle Share" above when funds are received.'),
                              );
                            }
                            return ListView.separated(
                              padding: const EdgeInsets.all(AppTheme.spacingMd),
                              itemCount: batches.length,
                              separatorBuilder: (_, i) => const Divider(height: 16),
                              itemBuilder: (context, i) {
                                final batch = batches[i];
                                return Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF8FAFC),
                                    borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                                    border: Border.all(color: const Color(0xFFE2E8F0)),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            'Settlement #${batch.id.substring(0, batch.id.length >= 6 ? 6 : batch.id.length).toUpperCase()}',
                                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                          ),
                                          Text(
                                            '₹${batch.amountSettled.toInt()}',
                                            style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: Color(0xFF16A34A)),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Settled by: ${batch.settledBy}',
                                        style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary),
                                      ),
                                      Text(
                                        'Date: ${DateFormat('dd MMM yyyy, hh:mm a').format(batch.settledAt)}',
                                        style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary),
                                      ),
                                      Text(
                                        'Bills Included: ${batch.billCount} booking(s)',
                                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                                      ),
                                      if (batch.notes != null && batch.notes!.isNotEmpty) ...[
                                        const SizedBox(height: 4),
                                        Text('Notes: ${batch.notes}', style: const TextStyle(fontSize: 11, fontStyle: FontStyle.italic)),
                                      ],
                                    ],
                                  ),
                                );
                              },
                            );
                          },
                        );
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
    final statusFilter = ref.watch(adminStatusFilterProvider);
    final requestsAsync = ref.watch(adminRequestsProvider);

    final filterOptions = [
      {'key': 'ALL', 'label': 'All'},
      {'key': AppConstants.statusNew, 'label': 'Pending'},
      {'key': AppConstants.statusAssigned, 'label': 'Assigned'},
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
              filtered.sort((a, b) => b.createdAt.compareTo(a.createdAt));

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
                                  Expanded(
                                    child: Text(
                                      req.isCancelled
                                          ? (req.cancelledBy == 'admin' ? 'Cancelled by Admin' : 'Cancelled by Doctor')
                                          : req.isCompleted
                                              ? 'Completed (${req.completedBy == 'admin' ? 'Admin' : 'Doctor'})'
                                              : (req.assignedTechnicianName != null
                                                  ? 'Tech: ${req.assignedTechnicianName}'
                                                  : 'Needs Tech Assignment'),
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: req.isCancelled
                                            ? AppTheme.statusCancelled
                                            : req.isCompleted
                                                ? AppTheme.statusCompleted
                                                : (req.assignedTechnicianName != null ? AppTheme.primaryColor : AppTheme.errorColor),
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
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
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                        side: const BorderSide(color: AppTheme.cardBorderColor),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(AppTheme.spacingMd),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // 1. Clinic Name & Doctor
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: AppTheme.primaryLight,
                                    borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                                  ),
                                  child: const Icon(Icons.apartment_rounded, color: AppTheme.primaryColor, size: 22),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        doc.clinicName?.isNotEmpty == true ? doc.clinicName! : 'Dental Clinic',
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppTheme.textPrimary),
                                      ),
                                      const SizedBox(height: 2),
                                      Row(
                                        children: [
                                          const Icon(Icons.person_outline_rounded, size: 14, color: AppTheme.textSecondary),
                                          const SizedBox(width: 4),
                                          Text(
                                            'Dr. ${doc.displayName}',
                                            style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary, fontWeight: FontWeight.w500),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            const Divider(height: 1),
                            const SizedBox(height: 10),

                            // 2. Phone Number with Call Action
                            Row(
                              children: [
                                const Icon(Icons.phone_rounded, size: 16, color: AppTheme.primaryColor),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    doc.phone.isNotEmpty ? doc.phone : 'No mobile number recorded',
                                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.textPrimary),
                                  ),
                                ),
                                if (doc.phone.isNotEmpty)
                                  OutlinedButton.icon(
                                    style: OutlinedButton.styleFrom(
                                      minimumSize: Size.zero,
                                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                      visualDensity: VisualDensity.compact,
                                    ),
                                    onPressed: () {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(content: Text('Dialing ${doc.phone}')),
                                      );
                                    },
                                    icon: const Icon(Icons.call_rounded, size: 14),
                                    label: const Text('Call', style: TextStyle(fontSize: 12)),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 8),

                            // 3. Address
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Icon(Icons.location_on_rounded, size: 16, color: Color(0xFFE11D48)),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    doc.clinicAddress?.isNotEmpty == true ? doc.clinicAddress! : 'Hyderabad, Telangana',
                                    style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary, height: 1.3),
                                  ),
                                ),
                              ],
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
        ),
      ],
    );
  }

  // ══════════════════════════════════════════════════════════════════
  // TAB 3: Field Technicians Roster (Add, Edit, Deactivate)
  // ══════════════════════════════════════════════════════════════════
  Widget _buildTechniciansTab() {
    final techniciansAsync = ref.watch(techniciansProvider);

    return techniciansAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, _) => Center(child: Text('Error: $err')),
      data: (techs) {
        final activeCount = techs.where((t) => t.isActive).length;

        return RefreshIndicator(
          onRefresh: () async => ref.invalidate(techniciansProvider),
          child: ListView(
            padding: const EdgeInsets.all(AppTheme.spacingMd),
            children: [
              // Header Card with Synchronized Real-time Count & Inline Add Button (No floating overlap!)
              Container(
                padding: const EdgeInsets.all(16),
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
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFCCFBF1),
                        borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                      ),
                      child: const Icon(Icons.engineering_rounded, color: Color(0xFF0D9488), size: 24),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Field Technicians Roster',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.textPrimary),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${techs.length} Registered Technicians ($activeCount Active)',
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF0F766E)),
                          ),
                        ],
                      ),
                    ),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      ),
                      onPressed: _showAddTechnicianDialog,
                      icon: const Icon(Icons.person_add_rounded, size: 16),
                      label: const Text('Add Tech', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 14),

              if (techs.isEmpty) ...[
                const SizedBox(height: 40),
                const Center(
                  child: Column(
                    children: [
                      Icon(Icons.engineering_outlined, size: 54, color: AppTheme.textHint),
                      SizedBox(height: 12),
                      Text('No technicians in roster.', style: TextStyle(fontWeight: FontWeight.bold)),
                      SizedBox(height: 6),
                      Text('Click "+ Add Tech" above to register your first technician.', style: TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
                    ],
                  ),
                ),
              ] else ...[
                // Technician Cards List
                ...techs.map((tech) {
                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                      side: const BorderSide(color: AppTheme.cardBorderColor),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(AppTheme.spacingMd),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Top Row: Avatar, Name, Status Badge, Edit & Delete Actions
                          Row(
                            children: [
                              CircleAvatar(
                                radius: 20,
                                backgroundColor: tech.isActive ? const Color(0xFFE0F2FE) : const Color(0xFFF3F4F6),
                                child: Icon(
                                  Icons.engineering_rounded,
                                  size: 22,
                                  color: tech.isActive ? AppTheme.primaryColor : AppTheme.textHint,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      tech.name,
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 15,
                                        decoration: tech.isActive ? null : TextDecoration.lineThrough,
                                        color: tech.isActive ? AppTheme.textPrimary : AppTheme.textHint,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: tech.isActive ? const Color(0xFFDCFCE7) : const Color(0xFFFEE2E2),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        tech.isActive ? 'Active in Roster' : 'Inactive / Off-Duty',
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                          color: tech.isActive ? const Color(0xFF166534) : const Color(0xFF991B1B),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.edit_outlined, size: 20),
                                tooltip: 'Edit Details',
                                visualDensity: VisualDensity.compact,
                                onPressed: () => _showEditTechnicianDialog(tech),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete_outline_rounded, size: 20, color: AppTheme.errorColor),
                                tooltip: 'Delete Technician',
                                visualDensity: VisualDensity.compact,
                                onPressed: () async {
                                  final confirm = await showDialog<bool>(
                                    context: context,
                                    builder: (ctx) => AlertDialog(
                                      title: const Text('Delete Technician'),
                                      content: Text('Are you sure you want to remove ${tech.name} from the roster?'),
                                      actions: [
                                        TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancel')),
                                        ElevatedButton(
                                          style: ElevatedButton.styleFrom(backgroundColor: AppTheme.errorColor),
                                          onPressed: () => Navigator.of(ctx).pop(true),
                                          child: const Text('Delete'),
                                        ),
                                      ],
                                    ),
                                  );
                                  if (confirm == true) {
                                    await ref.read(technicianRepositoryProvider).deleteTechnician(tech.id);
                                    ref.invalidate(techniciansProvider);
                                    ref.invalidate(activeTechniciansProvider);
                                    ref.invalidate(registeredTechnicianCountProvider);
                                    ref.invalidate(activeTechnicianCountProvider);
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(content: Text('${tech.name} removed from roster.')),
                                      );
                                    }
                                  }
                                },
                              ),
                            ],
                          ),

                          const SizedBox(height: 10),
                          const Divider(height: 1),
                          const SizedBox(height: 10),

                          // Contact Row
                          Row(
                            children: [
                              const Icon(Icons.phone_rounded, size: 15, color: AppTheme.primaryColor),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  tech.phone.isNotEmpty ? tech.phone : 'No phone recorded',
                                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.textPrimary),
                                ),
                              ),
                              if (tech.phone.isNotEmpty)
                                OutlinedButton.icon(
                                  style: OutlinedButton.styleFrom(
                                    visualDensity: VisualDensity.compact,
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    minimumSize: Size.zero,
                                  ),
                                  onPressed: () {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text('Dialing ${tech.phone}...')),
                                    );
                                  },
                                  icon: const Icon(Icons.call_rounded, size: 13),
                                  label: const Text('Call', style: TextStyle(fontSize: 11)),
                                ),
                            ],
                          ),

                          const SizedBox(height: 8),

                          // Tags: Service Area & Specialization
                          Wrap(
                            spacing: 8,
                            runSpacing: 6,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF1F5F9),
                                  borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.location_on_rounded, size: 13, color: Color(0xFFE11D48)),
                                    const SizedBox(width: 4),
                                    Text(
                                      tech.area?.isNotEmpty == true ? tech.area! : 'Hyderabad Coverage',
                                      style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary, fontWeight: FontWeight.w500),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF1F5F9),
                                  borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.build_rounded, size: 13, color: Color(0xFF0D9488)),
                                    const SizedBox(width: 4),
                                    Text(
                                      tech.specialization?.isNotEmpty == true ? tech.specialization! : 'Dental Equipment Repair',
                                      style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary, fontWeight: FontWeight.w500),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 10),
                          const Divider(height: 1),

                          // Bottom Switch Row
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Available for Ticket Dispatch',
                                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.textPrimary),
                              ),
                              Switch(
                                value: tech.isActive,
                                activeThumbColor: AppTheme.primaryColor,
                                onChanged: (val) async {
                                  await ref.read(technicianRepositoryProvider).toggleTechnicianActive(
                                    id: tech.id,
                                    isActive: val,
                                  );
                                  ref.invalidate(techniciansProvider);
                                  ref.invalidate(activeTechniciansProvider);
                                  ref.invalidate(registeredTechnicianCountProvider);
                                  ref.invalidate(activeTechnicianCountProvider);
                                },
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                }),
              ],
            ],
          ),
        );
      },
    );
  }

  void _showAddTechnicianDialog() {
    final nameCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final areaCtrl = TextEditingController();
    final specCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();
    bool isSubmitting = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.radiusMd)),
            title: const Row(
              children: [
                Icon(Icons.person_add_rounded, color: AppTheme.primaryColor),
                SizedBox(width: 8),
                Text('Add Field Technician', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
              ],
            ),
            content: Form(
              key: formKey,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      controller: nameCtrl,
                      decoration: const InputDecoration(labelText: 'Technician Name *', prefixIcon: Icon(Icons.person_outline_rounded)),
                      validator: (val) => Validators.required(val, 'Name'),
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: phoneCtrl,
                      keyboardType: TextInputType.phone,
                      maxLength: 10,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(10),
                      ],
                      decoration: const InputDecoration(
                        labelText: 'Phone Number (10 digits) *',
                        hintText: 'e.g. 9876543210',
                        prefixIcon: Icon(Icons.phone_outlined),
                        counterText: '',
                      ),
                      validator: Validators.phoneNumber,
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: areaCtrl,
                      decoration: const InputDecoration(labelText: 'Service Area (e.g. Banjara Hills, Rangareddy)', prefixIcon: Icon(Icons.location_on_outlined)),
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: specCtrl,
                      decoration: const InputDecoration(labelText: 'Specialization (e.g. Chairs, Compressors)', prefixIcon: Icon(Icons.build_outlined)),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: isSubmitting ? null : () => Navigator.of(ctx).pop(),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: isSubmitting
                    ? null
                    : () async {
                        if (formKey.currentState!.validate()) {
                          setDialogState(() => isSubmitting = true);
                          try {
                            await ref.read(technicianRepositoryProvider).addTechnician(
                              name: nameCtrl.text.trim(),
                              phone: phoneCtrl.text.trim(),
                              area: areaCtrl.text.trim(),
                              specialization: specCtrl.text.trim(),
                            );
                            ref.invalidate(techniciansProvider);
                            ref.invalidate(activeTechniciansProvider);
                            ref.invalidate(registeredTechnicianCountProvider);
                            ref.invalidate(activeTechnicianCountProvider);
                            if (ctx.mounted) Navigator.of(ctx).pop();
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(backgroundColor: AppTheme.successColor, content: Text('Technician added to roster!')),
                              );
                            }
                          } catch (e) {
                            setDialogState(() => isSubmitting = false);
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Failed to add technician: $e')),
                              );
                            }
                          }
                        }
                      },
                child: isSubmitting
                    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Text('Save Technician'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showEditTechnicianDialog(TechnicianModel tech) {
    final nameCtrl = TextEditingController(text: tech.name);
    final phoneCtrl = TextEditingController(text: tech.phone);
    final areaCtrl = TextEditingController(text: tech.area ?? '');
    final specCtrl = TextEditingController(text: tech.specialization ?? '');
    final formKey = GlobalKey<FormState>();
    bool isSubmitting = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.radiusMd)),
            title: const Row(
              children: [
                Icon(Icons.edit_rounded, color: AppTheme.primaryColor),
                SizedBox(width: 8),
                Text('Edit Technician', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
              ],
            ),
            content: Form(
              key: formKey,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      controller: nameCtrl,
                      decoration: const InputDecoration(labelText: 'Name *', prefixIcon: Icon(Icons.person_outline_rounded)),
                      validator: (val) => Validators.required(val, 'Name'),
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: phoneCtrl,
                      keyboardType: TextInputType.phone,
                      maxLength: 10,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(10),
                      ],
                      decoration: const InputDecoration(
                        labelText: 'Phone (10 digits) *',
                        hintText: 'e.g. 9876543210',
                        prefixIcon: Icon(Icons.phone_outlined),
                        counterText: '',
                      ),
                      validator: Validators.phoneNumber,
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: areaCtrl,
                      decoration: const InputDecoration(labelText: 'Area', prefixIcon: Icon(Icons.location_on_outlined)),
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: specCtrl,
                      decoration: const InputDecoration(labelText: 'Specialization', prefixIcon: Icon(Icons.build_outlined)),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: isSubmitting ? null : () => Navigator.of(ctx).pop(),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: isSubmitting
                    ? null
                    : () async {
                        if (formKey.currentState!.validate()) {
                          setDialogState(() => isSubmitting = true);
                          try {
                            await ref.read(technicianRepositoryProvider).updateTechnician(
                              id: tech.id,
                              name: nameCtrl.text.trim(),
                              phone: phoneCtrl.text.trim(),
                              area: areaCtrl.text.trim(),
                              specialization: specCtrl.text.trim(),
                            );
                            ref.invalidate(techniciansProvider);
                            ref.invalidate(activeTechniciansProvider);
                            ref.invalidate(registeredTechnicianCountProvider);
                            ref.invalidate(activeTechnicianCountProvider);
                            if (ctx.mounted) Navigator.of(ctx).pop();
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(backgroundColor: AppTheme.successColor, content: Text('Technician details updated!')),
                              );
                            }
                          } catch (e) {
                            setDialogState(() => isSubmitting = false);
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Failed to update: $e')),
                              );
                            }
                          }
                        }
                      },
                child: isSubmitting
                    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Text('Update'),
              ),
            ],
          );
        },
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════
  // TAB 4: Inline Equipment Categories & Platform Settings
  // ══════════════════════════════════════════════════════════════════
  void _initSettingsFields(BookingConfigModel config) {
    if (_isSettingsInitialized) return;
    _supportPhoneController.text = config.supportPhone;
    _pincodesController.text = config.serviceablePincodePrefixes.join(', ');
    _maxDaysController.text = config.maxDaysAhead.toString();
    _maxOpenRequestsController.text = config.maxOpenRequests.toString();
    _isSettingsInitialized = true;
  }

  Future<void> _addCategory(BookingConfigModel config) async {
    final label = _newCategoryController.text.trim();
    if (label.isEmpty) return;
    final code = label.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '_');

    if (config.issueTypes.any((c) => c.code == code)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Category with this code already exists.')),
      );
      return;
    }

    final updatedCategories = List<IssueTypeItem>.from(config.issueTypes)
      ..add(IssueTypeItem(code: code, label: label, active: true));

    final updatedConfig = config.copyWith(
      issueTypes: updatedCategories,
      updatedAt: DateTime.now(),
    );

    try {
      await ref.read(settingsRepositoryProvider).updateBookingConfig(updatedConfig);
      ref.invalidate(bookingConfigProvider);
      _newCategoryController.clear();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(backgroundColor: AppTheme.successColor, content: Text('Added category "$label"')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to add category: $e')));
    }
  }

  Future<void> _toggleCategoryActive(BookingConfigModel config, int index, bool active) async {
    final updatedCategories = List<IssueTypeItem>.from(config.issueTypes);
    final current = updatedCategories[index];
    updatedCategories[index] = IssueTypeItem(code: current.code, label: current.label, active: active);

    final updatedConfig = config.copyWith(
      issueTypes: updatedCategories,
      updatedAt: DateTime.now(),
    );

    await ref.read(settingsRepositoryProvider).updateBookingConfig(updatedConfig);
    ref.invalidate(bookingConfigProvider);
  }

  Future<void> _renameCategory(BookingConfigModel config, int index) async {
    final cat = config.issueTypes[index];
    final renameController = TextEditingController(text: cat.label);

    final newName = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Rename Equipment Category'),
        content: TextField(
          controller: renameController,
          decoration: const InputDecoration(labelText: 'Category Name'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(null), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(renameController.text.trim()),
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (newName != null && newName.isNotEmpty && newName != cat.label) {
      final updatedCategories = List<IssueTypeItem>.from(config.issueTypes);
      updatedCategories[index] = IssueTypeItem(code: cat.code, label: newName, active: cat.active);

      final updatedConfig = config.copyWith(
        issueTypes: updatedCategories,
        updatedAt: DateTime.now(),
      );

      await ref.read(settingsRepositoryProvider).updateBookingConfig(updatedConfig);
      ref.invalidate(bookingConfigProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(backgroundColor: AppTheme.successColor, content: Text('Renamed to "$newName"')),
        );
      }
    }
  }

  Future<void> _savePlatformSettings(BookingConfigModel config) async {
    setState(() => _isSavingSettings = true);
    final prefixes = _pincodesController.text
        .split(',')
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();

    final maxDays = int.tryParse(_maxDaysController.text.trim()) ?? config.maxDaysAhead;
    final maxOpen = int.tryParse(_maxOpenRequestsController.text.trim()) ?? config.maxOpenRequests;
    final phone = _supportPhoneController.text.trim();

    final updatedConfig = config.copyWith(
      supportPhone: phone.isNotEmpty ? phone : config.supportPhone,
      serviceablePincodePrefixes: prefixes.isNotEmpty ? prefixes : config.serviceablePincodePrefixes,
      maxDaysAhead: maxDays,
      maxOpenRequests: maxOpen,
      updatedAt: DateTime.now(),
    );

    try {
      await ref.read(settingsRepositoryProvider).updateBookingConfig(updatedConfig);
      ref.invalidate(bookingConfigProvider);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: AppTheme.successColor,
          content: Text('Settings saved successfully'),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to save settings: $e')));
    } finally {
      if (mounted) setState(() => _isSavingSettings = false);
    }
  }

  Widget _buildSettingsTab() {
    final configAsync = ref.watch(bookingConfigProvider);
    final config = configAsync.value ?? BookingConfigModel.defaultConfig();
    _initSettingsFields(config);

    final activeCount = config.issueTypes.where((c) => c.active).length;

    return RefreshIndicator(
      onRefresh: () async => ref.invalidate(bookingConfigProvider),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppTheme.spacingMd),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Section 1: Equipment Categories ──────────────────────────
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
                      const Row(
                        children: [
                          Icon(Icons.build_circle_rounded, color: AppTheme.primaryColor, size: 22),
                          SizedBox(width: 8),
                          Text(
                            'Equipment Categories',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.textPrimary),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryLight,
                          borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                        ),
                        child: Text(
                          '$activeCount Active',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppTheme.primaryColor),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Add, rename, and toggle dental equipment categories available for doctor bookings.',
                    style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                  ),
                  const SizedBox(height: 16),

                  // Add New Category Input with Suffix Action
                  TextField(
                    controller: _newCategoryController,
                    decoration: InputDecoration(
                      labelText: 'New Equipment Category *',
                      hintText: 'e.g. Autoclaves, X-Ray Units',
                      prefixIcon: const Icon(Icons.add_box_rounded),
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.add_circle_rounded, color: AppTheme.primaryColor),
                        tooltip: 'Add Category',
                        onPressed: () => _addCategory(config),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    ),
                    onSubmitted: (_) => _addCategory(config),
                  ),
                  const SizedBox(height: 16),
                  const Divider(height: 1),
                  const SizedBox(height: 12),

                  // Categories List
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: config.issueTypes.length,
                    separatorBuilder: (context, index) => const Divider(height: 8),
                    itemBuilder: (context, index) {
                      final cat = config.issueTypes[index];
                      return ListTile(
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        leading: CircleAvatar(
                          radius: 16,
                          backgroundColor: cat.active ? AppTheme.primaryLight : const Color(0xFFF3F4F6),
                          child: Icon(
                            Icons.handyman_rounded,
                            size: 16,
                            color: cat.active ? AppTheme.primaryColor : AppTheme.textHint,
                          ),
                        ),
                        title: Text(
                          cat.label,
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                            decoration: cat.active ? null : TextDecoration.lineThrough,
                            color: cat.active ? AppTheme.textPrimary : AppTheme.textHint,
                          ),
                        ),
                        subtitle: Text(
                          'Code: ${cat.code}',
                          style: const TextStyle(fontSize: 11, color: AppTheme.textHint),
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit_outlined, size: 18),
                              tooltip: 'Rename',
                              onPressed: () => _renameCategory(config, index),
                            ),
                            Switch(
                              value: cat.active,
                              onChanged: (val) => _toggleCategoryActive(config, index, val),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // ── Section 2: Platform Configuration ─────────────────────────
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
                  const Row(
                    children: [
                      Icon(Icons.tune_rounded, color: AppTheme.primaryColor, size: 22),
                      SizedBox(width: 8),
                      Text(
                        'Service & Operational Policies',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.textPrimary),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Configure customer support contact, Hyderabad serviceable areas, and doctor booking constraints.',
                    style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                  ),
                  const SizedBox(height: 16),

                  TextFormField(
                    controller: _supportPhoneController,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(
                      labelText: 'Operations Support Phone',
                      prefixIcon: Icon(Icons.phone_rounded),
                    ),
                  ),
                  const SizedBox(height: 12),

                  TextFormField(
                    controller: _pincodesController,
                    decoration: const InputDecoration(
                      labelText: 'Serviceable Pincode Prefixes (comma separated)',
                      prefixIcon: Icon(Icons.pin_drop_rounded),
                      hintText: 'e.g. 500, 501',
                    ),
                  ),
                  const SizedBox(height: 12),

                  TextFormField(
                    controller: _maxDaysController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Max Days Ahead for Booking',
                      prefixIcon: Icon(Icons.calendar_today_rounded),
                    ),
                  ),
                  const SizedBox(height: 12),

                  TextFormField(
                    controller: _maxOpenRequestsController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Max Open Requests Per Doctor',
                      prefixIcon: Icon(Icons.assignment_late_rounded),
                    ),
                  ),
                  const SizedBox(height: 20),

                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    onPressed: _isSavingSettings ? null : () => _savePlatformSettings(config),
                    icon: _isSavingSettings
                        ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Icon(Icons.save_rounded),
                    label: Text(_isSavingSettings ? 'Saving...' : 'Save Configuration'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
}
