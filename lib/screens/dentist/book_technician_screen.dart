import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../models/booking_config_model.dart';
import '../../providers/auth_providers.dart';
import '../../providers/request_providers.dart';
import '../../providers/settings_providers.dart';
import '../../theme/app_theme.dart';
import '../../utils/validators.dart';

/// Screen where dentists specify equipment problem, clinic address, and time slot.
/// Implements 4-step workflow: Equipment, Contact & Address, Time slot, Review.
class BookTechnicianScreen extends ConsumerStatefulWidget {
  final String? initialCategory;

  const BookTechnicianScreen({super.key, this.initialCategory});

  @override
  ConsumerState<BookTechnicianScreen> createState() => _BookTechnicianScreenState();
}

class _BookTechnicianScreenState extends ConsumerState<BookTechnicianScreen> {
  final _formKey = GlobalKey<FormState>();

  // Contact & Address controllers
  final _doctorNameController = TextEditingController();
  final _clinicNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressLineController = TextEditingController();
  final _landmarkController = TextEditingController();
  final _areaController = TextEditingController();
  final _pincodeController = TextEditingController();
  final _descriptionController = TextEditingController();

  String? _selectedIssueCode;
  DateTime _selectedDate = DateTime.now();

  double? _detectedLat;
  double? _detectedLng;
  bool _isDetectingGps = false;
  bool _isInit = false;

  @override
  void initState() {
    super.initState();
    _selectedIssueCode = widget.initialCategory;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isInit) {
      final dentist = ref.read(currentUserProfileProvider).value;
      if (dentist != null) {
        if (_doctorNameController.text.isEmpty && dentist.displayName.isNotEmpty) {
          _doctorNameController.text = dentist.displayName;
        }
        if (_clinicNameController.text.isEmpty && dentist.clinicName != null) {
          _clinicNameController.text = dentist.clinicName!;
        }
        if (_phoneController.text.isEmpty && dentist.phone.isNotEmpty) {
          _phoneController.text = dentist.phone.replaceAll('+91', '').trim();
        }
        if (_addressLineController.text.isEmpty && dentist.clinicAddress != null) {
          _addressLineController.text = dentist.clinicAddress!;
        }
        _detectedLat = dentist.clinicLatitude;
        _detectedLng = dentist.clinicLongitude;
      }
      _isInit = true;
    }
  }

  @override
  void dispose() {
    _doctorNameController.dispose();
    _clinicNameController.dispose();
    _phoneController.dispose();
    _addressLineController.dispose();
    _landmarkController.dispose();
    _areaController.dispose();
    _pincodeController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _detectGps() async {
    setState(() => _isDetectingGps = true);
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
        setState(() => _isDetectingGps = false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Location permission was denied. Please enter your clinic address manually.')),
          );
        }
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 12),
        ),
      );

      _detectedLat = position.latitude;
      _detectedLng = position.longitude;

      // Reverse geocoding using device geocoder (free, no API key)
      try {
        final placemarks = await placemarkFromCoordinates(position.latitude, position.longitude);
        if (placemarks.isNotEmpty) {
          final place = placemarks.first;
          final street = place.street ?? '';
          final subLocality = place.subLocality ?? place.locality ?? '';
          final postal = place.postalCode ?? '';

          if (street.isNotEmpty && _addressLineController.text.isEmpty) {
            _addressLineController.text = street;
          }
          if (subLocality.isNotEmpty && _areaController.text.isEmpty) {
            _areaController.text = subLocality;
          }
          if (postal.isNotEmpty && _pincodeController.text.isEmpty) {
            _pincodeController.text = postal;
          }

          // Validate if location is in Hyderabad area
          final config = ref.read(bookingConfigProvider).value ?? BookingConfigModel.defaultConfig();
          final isValidPincode = config.serviceablePincodePrefixes.any((prefix) => postal.startsWith(prefix));
          if (postal.isNotEmpty && !isValidPincode) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Detected location appears to be outside our serviceable area. We currently serve Hyderabad only.')),
              );
            }
          } else {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  backgroundColor: AppTheme.successColor,
                  content: Text('Clinic location detected successfully.'),
                ),
              );
            }
          }
        }
      } catch (_) {
        // Geocoding error is non-fatal: GPS coords are still saved
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('GPS coordinates captured. Please enter street and pincode details.')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Location detection unavailable: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isDetectingGps = false);
    }
  }

  void _proceedToReview(BookingConfigModel config) async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedIssueCode == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select an equipment category')),
      );
      return;
    }

    // Check maximum open requests limit (config: default 3)
    final dentist = ref.read(currentUserProfileProvider).value;
    if (dentist != null) {
      final activeCount = await ref.read(requestRepositoryProvider).getActiveRequestsCount(dentist.uid);
      if (activeCount >= config.maxOpenRequests) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppTheme.errorColor,
            content: Text('You have $activeCount active service requests. Maximum allowed is ${config.maxOpenRequests}. Please wait until a pending request is completed.'),
          ),
        );
        return;
      }
    }

    final selectedIssueItem = config.issueTypes.firstWhere(
      (item) => item.code == _selectedIssueCode,
      orElse: () => IssueTypeItem(code: _selectedIssueCode!, label: _selectedIssueCode!, active: true),
    );

    final slotDateFormatted = DateFormat('yyyy-MM-dd').format(_selectedDate);
    final displayDate = DateFormat('EEE, MMM dd, yyyy').format(_selectedDate);

    if (!mounted) return;
    context.push('/dentist/review', extra: {
      'dentistId': dentist?.uid ?? '',
      'dentistName': _doctorNameController.text.trim(),
      'clinicName': _clinicNameController.text.trim(),
      'mobile': _phoneController.text.trim(),
      'addressLine': _addressLineController.text.trim(),
      'landmark': _landmarkController.text.trim(),
      'area': _areaController.text.trim(),
      'city': 'Hyderabad',
      'pincode': _pincodeController.text.trim(),
      'lat': _detectedLat ?? 0.0,
      'lng': _detectedLng ?? 0.0,
      'issueCode': selectedIssueItem.code,
      'issueLabel': selectedIssueItem.label,
      'issueDescription': _descriptionController.text.trim(),
      'slotDate': slotDateFormatted,
      'slotDisplayDate': displayDate,
      'slotKey': 'full_day',
      'slotLabel': '24h Coordination Window',
      'slotStart': _selectedDate,
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final configAsync = ref.watch(bookingConfigProvider);
    final config = configAsync.value ?? BookingConfigModel.defaultConfig();

    // 1. Issue Types: deduplicate by code, filter active
    final availableCategories = config.activeIssueTypes;
    final validCodes = availableCategories.map((c) => c.code).toSet();

    // Reset invalid selection if code not in active list
    if (_selectedIssueCode != null && !validCodes.contains(_selectedIssueCode)) {
      _selectedIssueCode = null;
    }

    // 2. Dates: Today to Today + maxDaysAhead
    final now = DateTime.now();
    final availableDates = List.generate(
      config.maxDaysAhead + 1,
      (index) => DateTime(now.year, now.month, now.day).add(Duration(days: index)),
    );

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('Book Technician'),
        leading: BackButton(onPressed: () => context.pop()),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppTheme.spacingMd),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Service Coverage Notice Banner (Section 9)
                Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0F9FF),
                    borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                    border: Border.all(color: const Color(0xFFBAE6FD)),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.location_on_rounded, size: 20, color: Color(0xFF0284C7)),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'We currently provide technician services in Hyderabad, including Rangareddy, Secunderabad, and Cyberabad.',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF1E293B),
                            height: 1.35,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // STEP 1: Equipment Details
                _buildSectionHeader('1. Equipment Details', Icons.build_rounded),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: _cardDecoration(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Equipment Category *',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                      const SizedBox(height: 8),

                      if (availableCategories.isEmpty) ...[
                        const Text('No equipment categories currently available. Please contact support.',
                            style: TextStyle(color: AppTheme.errorColor)),
                      ] else ...[
                        DropdownButtonFormField<String>(
                          initialValue: _selectedIssueCode,
                          isExpanded: true,
                          decoration: const InputDecoration(
                            hintText: 'Select Equipment Type',
                            prefixIcon: Icon(Icons.category_outlined),
                          ),
                          items: availableCategories.map((item) {
                            return DropdownMenuItem<String>(
                              value: item.code,
                              child: Text(item.label, maxLines: 1, overflow: TextOverflow.ellipsis),
                            );
                          }).toList(),
                          onChanged: (val) {
                            setState(() => _selectedIssueCode = val);
                          },
                          validator: (val) => val == null ? 'Please select equipment' : null,
                        ),
                      ],

                      const SizedBox(height: 16),
                      const Text(
                        'Describe the Issue *',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _descriptionController,
                        maxLines: 3,
                        maxLength: 500,
                        decoration: const InputDecoration(
                          hintText: 'e.g. Hydraulic lift stuck, foot switch not responding, unusual noise during operation...',
                        ),
                        validator: Validators.description,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // STEP 2: Contact & Clinic Address
                _buildSectionHeader('2. Clinic Address (Hyderabad Only)', Icons.location_on_rounded),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: _cardDecoration(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Doctor Name (Full width)
                      TextFormField(
                        controller: _doctorNameController,
                        decoration: const InputDecoration(
                          labelText: 'Doctor Name *',
                          prefixIcon: Icon(Icons.person_outline),
                        ),
                        validator: (val) => Validators.required(val, 'Doctor name'),
                      ),
                      const SizedBox(height: 14),

                      // Clinic Name on separate new line
                      TextFormField(
                        controller: _clinicNameController,
                        decoration: const InputDecoration(
                          labelText: 'Clinic Name *',
                          prefixIcon: Icon(Icons.local_hospital_outlined),
                        ),
                        validator: (val) => Validators.required(val, 'Clinic name'),
                      ),
                      const SizedBox(height: 14),

                      // Doctor Contact Mobile (Section 8: registered contact number of authenticated doctor)
                      TextFormField(
                        controller: _phoneController,
                        keyboardType: TextInputType.number,
                        maxLength: 10,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(10),
                        ],
                        decoration: const InputDecoration(
                          labelText: "Doctor's Contact Mobile *",
                          hintText: '10 digits (registered mobile for technician coordination)',
                          prefixIcon: Icon(Icons.phone_outlined),
                          counterText: '',
                        ),
                        validator: Validators.phoneNumber,
                      ),
                      const SizedBox(height: 14),

                      // Address Line
                      TextFormField(
                        controller: _addressLineController,
                        decoration: const InputDecoration(
                          labelText: 'Address Line / Building / Floor *',
                          hintText: 'e.g. Flat 302, Sai Towers, Road No 12',
                          prefixIcon: Icon(Icons.home_work_outlined),
                        ),
                        validator: (val) => Validators.required(val, 'Address line'),
                      ),
                      const SizedBox(height: 14),

                      // Landmark & Area
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _landmarkController,
                              decoration: const InputDecoration(
                                labelText: 'Landmark (Optional)',
                                hintText: 'Near Metro Station',
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextFormField(
                              controller: _areaController,
                              decoration: const InputDecoration(
                                labelText: 'Locality / Area',
                                hintText: 'e.g. Banjara Hills',
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),

                      // City (Hyderabad fixed read-only) & Pincode
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              initialValue: 'Hyderabad',
                              readOnly: true,
                              decoration: const InputDecoration(
                                labelText: 'City',
                                prefixIcon: Icon(Icons.location_city_outlined),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextFormField(
                              controller: _pincodeController,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                labelText: 'Pincode *',
                                hintText: 'e.g. 500034',
                              ),
                              validator: (val) => Validators.pincode(val, config.serviceablePincodePrefixes),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Detect Location Button
                      OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppTheme.primaryColor,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        onPressed: _isDetectingGps ? null : _detectGps,
                        icon: _isDetectingGps
                            ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                            : const Icon(Icons.my_location_rounded, size: 18),
                        label: Text(_isDetectingGps ? 'Detecting GPS...' : 'Detect My Clinic Location'),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // STEP 3: Preferred Visit Date & 24-Hour Commitment (Section 6)
                _buildSectionHeader('3. Preferred Visit Date', Icons.calendar_today_rounded),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: _cardDecoration(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Select Service Date *',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        height: 48,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: availableDates.length,
                          separatorBuilder: (_, i) => const SizedBox(width: 8),
                          itemBuilder: (context, index) {
                            final date = availableDates[index];
                            final isSelected = date.year == _selectedDate.year &&
                                date.month == _selectedDate.month &&
                                date.day == _selectedDate.day;
                            final isToday = index == 0;
                            final label = isToday ? 'Today' : DateFormat('EEE, MMM d').format(date);

                            return ChoiceChip(
                              label: Text(label),
                              selected: isSelected,
                              onSelected: (selected) {
                                if (selected) {
                                  setState(() {
                                    _selectedDate = date;
                                  });
                                }
                              },
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF0F9FF),
                          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                          border: Border.all(color: const Color(0xFFBAE6FD)),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.access_time_filled_rounded, size: 22, color: Color(0xFF0284C7)),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    '24-Hour Service Commitment',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                      color: Color(0xFF0369A1),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'We will contact you within 24 hours to coordinate the technician visit.',
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      color: const Color(0xFF334155),
                                      fontWeight: FontWeight.w500,
                                      height: 1.35,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Review Button
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  onPressed: () => _proceedToReview(config),
                  child: const Text(
                    'Review & Confirm Booking',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, left: 4),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppTheme.primaryColor),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppTheme.primaryDark),
            ),
          ),
        ],
      ),
    );
  }

  BoxDecoration _cardDecoration() {
    return BoxDecoration(
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
    );
  }
}
