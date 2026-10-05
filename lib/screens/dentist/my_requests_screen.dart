import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../providers/request_providers.dart';
import '../../theme/app_theme.dart';
import '../../utils/constants.dart';

/// Screen listing all technician requests submitted by the logged-in dentist.
class MyRequestsScreen extends ConsumerStatefulWidget {
  const MyRequestsScreen({super.key});

  @override
  ConsumerState<MyRequestsScreen> createState() => _MyRequestsScreenState();
}

class _MyRequestsScreenState extends ConsumerState<MyRequestsScreen> {
  String _filter = 'ALL';

  @override
  Widget build(BuildContext context) {
    final requestsAsync = ref.watch(dentistRequestsProvider);
    final theme = Theme.of(context);
    final dateFormat = DateFormat('MMM dd, yyyy • hh:mm a');

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('My Service Requests'),
        leading: BackButton(
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/dentist');
            }
          },
        ),
      ),
      body: Column(
        children: [
          // Filter Tabs
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildFilterChip('ALL', 'All Requests'),
                  const SizedBox(width: 8),
                  _buildFilterChip(AppConstants.statusNew, 'Received'),
                  const SizedBox(width: 8),
                  _buildFilterChip(AppConstants.statusAssigned, 'Assigned'),
                  const SizedBox(width: 8),
                  _buildFilterChip(AppConstants.statusInProgress, 'In Progress'),
                  const SizedBox(width: 8),
                  _buildFilterChip(AppConstants.statusCompleted, 'Completed'),
                ],
              ),
            ),
          ),
          const Divider(height: 1),

          Expanded(
            child: requestsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Error loading requests: $e')),
              data: (requests) {
                final filtered = _filter == 'ALL'
                    ? requests
                    : requests.where((r) => r.status.toUpperCase() == _filter.toUpperCase()).toList();

                if (filtered.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.history_rounded,
                            size: 60,
                            color: AppTheme.textHint,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            requests.isEmpty ? 'No Requests Yet' : 'No requests in this status',
                            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            requests.isEmpty
                                ? 'Book a certified dental technician in under a minute.'
                                : 'Try switching the filter above to see all requests.',
                            style: theme.textTheme.bodySmall,
                            textAlign: TextAlign.center,
                          ),
                          if (requests.isEmpty) ...[
                            const SizedBox(height: 20),
                            ElevatedButton.icon(
                              onPressed: () => context.push('/dentist/book'),
                              icon: const Icon(Icons.add, size: 18),
                              label: const Text('Book a Technician'),
                            ),
                          ],
                        ],
                      ),
                    ),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.all(AppTheme.spacingMd),
                  itemCount: filtered.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final req = filtered[index];
                    final statusColor = AppTheme.getStatusColor(req.status);

                    return Card(
                      margin: EdgeInsets.zero,
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
                                      req.issueType,
                                      style: theme.textTheme.titleMedium?.copyWith(
                                        fontWeight: FontWeight.bold,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
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
                              const SizedBox(height: 6),
                              Text(
                                req.issueDescription,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: theme.textTheme.bodyMedium,
                              ),
                              const SizedBox(height: 12),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    dateFormat.format(req.createdAt),
                                    style: theme.textTheme.labelSmall,
                                  ),
                                  Row(
                                    children: [
                                      const Icon(Icons.verified_rounded, size: 14, color: AppTheme.successColor),
                                      const SizedBox(width: 4),
                                      Text(
                                        'FREE (₹0)',
                                        style: theme.textTheme.labelSmall?.copyWith(
                                          color: AppTheme.successColor,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              if (req.assignedTechnicianName != null) ...[
                                const Divider(height: 16),
                                Row(
                                  children: [
                                    const Icon(Icons.engineering_rounded, size: 16, color: AppTheme.primaryColor),
                                    const SizedBox(width: 6),
                                    Text(
                                      'Technician: ${req.assignedTechnicianName}',
                                      style: TextStyle(
                                        color: AppTheme.primaryColor,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
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

  Widget _buildFilterChip(String filterKey, String label) {
    final isSelected = _filter == filterKey;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => setState(() => _filter = filterKey),
      selectedColor: AppTheme.primaryLight,
      labelStyle: TextStyle(
        color: isSelected ? AppTheme.primaryColor : AppTheme.textSecondary,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        fontSize: 12,
      ),
      side: BorderSide(
        color: isSelected ? AppTheme.primaryColor : AppTheme.cardBorderColor,
      ),
    );
  }
}
