import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../models/booking_config_model.dart';
import '../../models/technician_request_model.dart';
import '../../providers/request_providers.dart';
import '../../theme/app_theme.dart';
import '../../utils/validators.dart';

/// Modal dialog allowing a doctor to edit ticket details (e.g. wrong slot or wrong issue)
/// while the request is in NEW or ASSIGNED status.
class EditRequestDialog extends ConsumerStatefulWidget {
  final TechnicianRequestModel request;
  final BookingConfigModel config;

  const EditRequestDialog({
    super.key,
    required this.request,
    required this.config,
  });

  @override
  ConsumerState<EditRequestDialog> createState() => _EditRequestDialogState();
}

class _EditRequestDialogState extends ConsumerState<EditRequestDialog> {
  final _formKey = GlobalKey<FormState>();
  late String _selectedCategoryCode;
  late TextEditingController _descController;
  late DateTime _selectedDate;
  TimeSlotItem? _selectedSlot;
  bool _isSaving = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _selectedCategoryCode = widget.request.issueCode;
    _descController = TextEditingController(text: widget.request.issueDescription);

    // Initial date
    final parsedDate = DateTime.tryParse(widget.request.slotDate);
    _selectedDate = parsedDate ?? widget.request.slotStart;

    // Initial slot
    final found = widget.config.slots.where((s) => s.key == widget.request.slotKey);
    _selectedSlot = found.isNotEmpty ? found.first : (widget.config.slots.isNotEmpty ? widget.config.slots.first : null);
  }

  @override
  void dispose() {
    _descController.dispose();
    super.dispose();
  }

  List<DateTime> get _availableDates {
    final now = DateTime.now();
    return List.generate(
      widget.config.maxDaysAhead + 1,
      (i) => DateTime(now.year, now.month, now.day).add(Duration(days: i)),
    );
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedSlot == null) {
      setState(() => _errorMessage = 'Please select a visit time slot.');
      return;
    }

    final slotStart = _selectedSlot!.getStartDateTime(_selectedDate);
    final isBookable = BookingConfigModel.isSlotBookable(
      slotStart: slotStart,
      now: DateTime.now(),
      minLeadMinutes: widget.config.minLeadMinutes,
    );

    if (!isBookable) {
      setState(() => _errorMessage = 'Selected slot is in the past or starts too soon (minimum ${widget.config.minLeadMinutes} mins lead time).');
      return;
    }

    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    try {
      final activeCategories = widget.config.activeIssueTypes;
      final cat = activeCategories.firstWhere(
        (c) => c.code == _selectedCategoryCode,
        orElse: () => IssueTypeItem(code: _selectedCategoryCode, label: widget.request.issueLabel),
      );

      final dateStr = DateFormat('yyyy-MM-dd').format(_selectedDate);

      await ref.read(requestRepositoryProvider).updateDoctorRequest(
        requestId: widget.request.id,
        issueCode: cat.code,
        issueLabel: cat.label,
        issueDescription: _descController.text.trim(),
        slotDate: dateStr,
        slotKey: _selectedSlot!.key,
        slotStart: slotStart,
      );

      ref.invalidate(requestDetailProvider(widget.request.id));
      ref.invalidate(dentistRequestsProvider);

      if (mounted) {
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSaving = false;
          _errorMessage = 'Failed to update request: $e';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final categories = widget.config.activeIssueTypes;
    final dates = _availableDates;

    return AlertDialog(
      title: const Row(
        children: [
          Icon(Icons.edit_note_rounded, color: AppTheme.primaryColor),
          SizedBox(width: 8),
          Text('Edit Service Request'),
        ],
      ),
      content: SizedBox(
        width: double.maxFinite,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Ticket ${widget.request.displayTicketId} • ${widget.request.clinicName}',
                  style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                ),
                const SizedBox(height: 16),

                // 1. Category Dropdown
                const Text('Equipment Category *', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                const SizedBox(height: 6),
                DropdownButtonFormField<String>(
                  initialValue: categories.any((c) => c.code == _selectedCategoryCode)
                      ? _selectedCategoryCode
                      : (categories.isNotEmpty ? categories.first.code : null),
                  isExpanded: true,
                  decoration: const InputDecoration(
                    contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                  ),
                  items: categories.map((c) => DropdownMenuItem(value: c.code, child: Text(c.label))).toList(),
                  onChanged: (val) {
                    if (val != null) setState(() => _selectedCategoryCode = val);
                  },
                ),
                const SizedBox(height: 14),

                // 2. Problem Description
                const Text('Problem Description *', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _descController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    hintText: 'Describe issue (1-500 chars)',
                  ),
                  validator: (val) => Validators.required(val, 'Problem description'),
                ),
                const SizedBox(height: 14),

                // 3. Preferred Date
                const Text('Preferred Visit Date *', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                const SizedBox(height: 8),
                SizedBox(
                  height: 42,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: dates.length,
                    separatorBuilder: (_, i) => const SizedBox(width: 6),
                    itemBuilder: (context, index) {
                      final date = dates[index];
                      final isSelected = date.year == _selectedDate.year &&
                          date.month == _selectedDate.month &&
                          date.day == _selectedDate.day;
                      final isToday = index == 0;
                      final label = isToday ? 'Today' : DateFormat('EEE d').format(date);

                      return ChoiceChip(
                        label: Text(label, style: const TextStyle(fontSize: 12)),
                        selected: isSelected,
                        onSelected: (selected) {
                          if (selected) {
                            setState(() {
                              _selectedDate = date;
                              _errorMessage = null;
                            });
                          }
                        },
                      );
                    },
                  ),
                ),
                const SizedBox(height: 14),

                // 4. Preferred Slot
                const Text('Preferred Time Slot *', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: widget.config.slots.map((slot) {
                    final slotStart = slot.getStartDateTime(_selectedDate);
                    final isBookable = BookingConfigModel.isSlotBookable(
                      slotStart: slotStart,
                      now: DateTime.now(),
                      minLeadMinutes: widget.config.minLeadMinutes,
                    );
                    final isSelected = _selectedSlot?.key == slot.key;

                    return ChoiceChip(
                      label: Text(slot.label, style: const TextStyle(fontSize: 12)),
                      selected: isSelected,
                      onSelected: isBookable
                          ? (selected) {
                              setState(() {
                                _selectedSlot = selected ? slot : null;
                                _errorMessage = null;
                              });
                            }
                          : null,
                    );
                  }).toList(),
                ),

                if (_errorMessage != null) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppTheme.errorColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.error_outline_rounded, color: AppTheme.errorColor, size: 16),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            _errorMessage!,
                            style: const TextStyle(color: AppTheme.errorColor, fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSaving ? null : () => Navigator.of(context).pop(false),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.primaryColor,
            foregroundColor: Colors.white,
          ),
          onPressed: _isSaving ? null : _handleSave,
          child: _isSaving
              ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : const Text('Save Changes'),
        ),
      ],
    );
  }
}
