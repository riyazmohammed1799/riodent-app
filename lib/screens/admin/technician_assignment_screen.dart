import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../models/technician_model.dart';
import '../../providers/request_providers.dart';
import '../../providers/technician_providers.dart';
import '../../theme/app_theme.dart';

/// Screen where the admin chooses a certified technician to assign to a service request.
class TechnicianAssignmentScreen extends ConsumerStatefulWidget {
  final String requestId;

  const TechnicianAssignmentScreen({
    super.key,
    required this.requestId,
  });

  @override
  ConsumerState<TechnicianAssignmentScreen> createState() => _TechnicianAssignmentScreenState();
}

class _TechnicianAssignmentScreenState extends ConsumerState<TechnicianAssignmentScreen> {
  TechnicianModel? _selectedTech;
  bool _isAssigning = false;

  Future<void> _handleAssign() async {
    if (_selectedTech == null) return;

    setState(() => _isAssigning = true);
    final repo = ref.read(requestRepositoryProvider);

    try {
      await repo.assignTechnician(
        requestId: widget.requestId,
        technicianId: _selectedTech!.id,
        technicianName: _selectedTech!.name,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Assigned to ${_selectedTech!.name}')),
      );
      context.pop();
    } catch (e) {
      if (!mounted) return;
      setState(() => _isAssigning = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Assignment failed: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final techAsync = ref.watch(activeTechniciansProvider);

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('Assign Technician'),
        leading: BackButton(onPressed: () => context.pop()),
      ),
      body: techAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (techs) {
          if (techs.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.people_outline_rounded, size: 56, color: AppTheme.textHint),
                    const SizedBox(height: 16),
                    Text('No Technicians Available', style: theme.textTheme.titleMedium),
                    const SizedBox(height: 8),
                    const Text('Please seed or add technicians to the roster first.'),
                  ],
                ),
              ),
            );
          }

          return Column(
            children: [
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.all(AppTheme.spacingMd),
                  itemCount: techs.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final tech = techs[index];
                    final isSelected = _selectedTech?.id == tech.id;

                    return Card(
                      margin: EdgeInsets.zero,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                        side: BorderSide(
                          color: isSelected ? AppTheme.primaryColor : const Color(0xFFEDF2F7),
                          width: isSelected ? 2 : 1,
                        ),
                      ),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: isSelected
                              ? AppTheme.primaryColor
                              : AppTheme.primaryColor.withValues(alpha: 0.1),
                          foregroundColor: isSelected ? Colors.white : AppTheme.primaryColor,
                          child: const Icon(Icons.person_rounded),
                        ),
                        title: Text(tech.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (tech.specialization != null)
                              Text('Specialization: ${tech.specialization}'),
                            Text('Phone: ${tech.phone}'),
                          ],
                        ),
                        trailing: Icon(
                          isSelected ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
                          color: isSelected ? AppTheme.primaryColor : AppTheme.textHint,
                        ),
                        onTap: () {
                          setState(() => _selectedTech = tech);
                        },
                      ),
                    );
                  },
                ),
              ),
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(AppTheme.spacingMd),
                  child: ElevatedButton(
                    onPressed: (_selectedTech == null || _isAssigning) ? null : _handleAssign,
                    child: _isAssigning
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : Text(_selectedTech == null
                            ? 'Select a Technician'
                            : 'Assign ${_selectedTech!.name}'),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
