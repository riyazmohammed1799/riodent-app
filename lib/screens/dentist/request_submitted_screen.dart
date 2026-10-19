import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../theme/app_theme.dart';

/// Screen displayed after a technician request has been successfully created.
/// Per Section 3.3:
/// - Displays short request ID (e.g. REQ-XXXXXX)
/// - Confirmation: 'Our technician will call you at `mobile` during `slot` to understand the issue.'
/// - No misleading fee labels
class RequestSubmittedScreen extends StatelessWidget {
  final dynamic requestId; // can be String or Map<String, dynamic>

  const RequestSubmittedScreen({
    super.key,
    required this.requestId,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    String ticketId = 'REQ-SUBMITTED';

    if (requestId is Map<String, dynamic>) {
      final map = requestId as Map<String, dynamic>;
      ticketId = map['ticketNumber'] as String? ?? 'REQ-SUBMITTED';
    } else if (requestId is String && (requestId as String).isNotEmpty) {
      ticketId = requestId as String;
    }

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, _) {
          if (didPop) return;
          context.go('/dentist');
        },
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingLg, vertical: AppTheme.spacingMd),
            child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(),
              Center(
                child: Container(
                  width: 84,
                  height: 84,
                  decoration: BoxDecoration(
                    color: AppTheme.successColor.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check_circle_rounded,
                    color: AppTheme.successColor,
                    size: 58,
                  ),
                ),
              ),
              const SizedBox(height: 22),
              Text(
                'Booking Submitted!',
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: AppTheme.primaryDark,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                'We will contact you within 24 hours to coordinate the technician visit.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: AppTheme.textSecondary,
                  fontSize: 15,
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 28),
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                  border: Border.all(color: AppTheme.cardBorderColor),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.02),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Ticket Reference', style: theme.textTheme.bodySmall),
                        SelectableText(
                          ticketId,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppTheme.primaryDark),
                        ),
                      ],
                    ),
                    const Divider(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Initial Status', style: theme.textTheme.bodySmall),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppTheme.statusNew.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                          ),
                          child: const Text(
                            'Pending',
                            style: TextStyle(
                              color: AppTheme.statusNew,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Platform Fee', style: theme.textTheme.bodySmall),
                        const Text(
                          'Free to Use',
                          style: TextStyle(
                            color: AppTheme.successColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const Spacer(),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                onPressed: () => context.go('/dentist/requests'),
                icon: const Icon(Icons.assignment_turned_in_rounded, size: 18),
                label: const Text('View in My Requests'),
              ),
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: () => context.go('/dentist'),
                child: const Text('Back to Home'),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    ),
  );
}
}
