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
  final _cityController = TextEditingController(text: 'Hyderabad');
  final _stateController = TextEditingController(text: 'Telangana');
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
        if (_clinicNameController.text.isEmpty &&
            dentist.clinicName != null &&
            dentist.clinicName!.trim().isNotEmpty &&
            dentist.clinicName != 'Dental Clinic') {
          _clinicNameController.text = dentist.clinicName!;
        }
        if (_phoneController.text.isEmpty && dentist.phone.isNotEmpty) {
          _phoneController.text = dentist.phone.replaceAll('+91', '').trim();
        }
        if (_addressLineController.text.isEmpty &&
            dentist.clinicAddress != null &&
            dentist.clinicAddress!.trim().isNotEmpty &&
            dentist.clinicAddress != 'Hyderabad, Telangana' &&
            dentist.clinicAddress != 'Hyderabad') {
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
    _cityController.dispose();
    _stateController.dispose();
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
          String detectedArea = '';
          String detectedPostal = '';
          String detectedCity = '';
          String detectedState = '';

          // Iterate all returned placemarks to find the best locality/area, city, state and 6-digit pincode
          for (final place in placemarks) {
            if (detectedArea.isEmpty) {
              if (place.subLocality != null && place.subLocality!.trim().isNotEmpty) {
                detectedArea = place.subLocality!.trim();
              } else if (place.locality != null &&
                  place.locality!.trim().isNotEmpty &&
                  place.locality!.trim() != 'Hyderabad') {
                detectedArea = place.locality!.trim();
              } else if (place.subAdministrativeArea != null &&
                  place.subAdministrativeArea!.trim().isNotEmpty &&
                  place.subAdministrativeArea!.trim() != 'Hyderabad') {
                detectedArea = place.subAdministrativeArea!.trim();
              }
            }

            if (detectedCity.isEmpty) {
              if (place.locality != null && place.locality!.trim().isNotEmpty) {
                detectedCity = place.locality!.trim();
              } else if (place.subAdministrativeArea != null && place.subAdministrativeArea!.trim().isNotEmpty) {
                detectedCity = place.subAdministrativeArea!.trim();
              }
            }

            if (detectedState.isEmpty) {
              if (place.administrativeArea != null && place.administrativeArea!.trim().isNotEmpty) {
                detectedState = place.administrativeArea!.trim();
              }
            }

            if (detectedPostal.isEmpty) {
              if (place.postalCode != null && place.postalCode!.trim().isNotEmpty) {
                final match = RegExp(r'\b500\d{3}\b|\b[1-9][0-9]{5}\b').firstMatch(place.postalCode!);
                if (match != null) {
                  detectedPostal = match.group(0)!;
                } else if (place.postalCode!.trim().length == 6) {
                  detectedPostal = place.postalCode!.trim();
                }
              }
            }

            // Search street, name, thoroughfare if postal code was not in postalCode field
            if (detectedPostal.isEmpty) {
              for (final field in [place.street, place.name, place.thoroughfare]) {
                if (field != null) {
                  final match = RegExp(r'\b500\d{3}\b|\b[1-9][0-9]{5}\b').firstMatch(field);
                  if (match != null) {
                    detectedPostal = match.group(0)!;
                    break;
                  }
                }
              }
            }
          }

          final first = placemarks.first;
          if (detectedArea.isEmpty) {
            detectedArea = first.subLocality ?? first.locality ?? first.name ?? '';
            if (detectedArea == 'Hyderabad') detectedArea = '';
          }
          if (detectedCity.isEmpty) {
            detectedCity = first.locality ?? first.subAdministrativeArea ?? 'Hyderabad';
          }
          if (detectedState.isEmpty) {
            detectedState = first.administrativeArea ?? 'Telangana';
          }

          // Autofill area, pincode, city, state per requirement
          if (detectedArea.isNotEmpty) {
            _areaController.text = detectedArea;
          }
          if (detectedPostal.isNotEmpty) {
            _pincodeController.text = detectedPostal;
          }
          if (detectedCity.isNotEmpty) {
            _cityController.text = detectedCity;
          }
          if (detectedState.isNotEmpty) {
            _stateController.text = detectedState;
          }

          // 1st line address is left explicitly empty for the doctor to mention their flat/shop/room/floor
          _addressLineController.clear();

          // Validate if location is in Hyderabad area
          final config = ref.read(bookingConfigProvider).value ?? BookingConfigModel.defaultConfig();
          final isValidPincode = detectedPostal.isEmpty ||
              config.serviceablePincodePrefixes.any((prefix) => detectedPostal.startsWith(prefix));
          if (detectedPostal.isNotEmpty && !isValidPincode) {
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
                  content: Text('GPS detected: Pincode, Area, City & State autofilled. Please enter your 1st line address.'),
                ),
              );
            }
          }
        }
      } catch (_) {
        // Geocoding error is non-fatal: GPS coords are still saved
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('GPS coordinates captured. Please enter your address, area, and pincode.')),
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
      'city': _cityController.text.trim().isNotEmpty ? _cityController.text.trim() : 'Hyderabad',
      'state': _stateController.text.trim().isNotEmpty ? _stateController.text.trim() : 'Telangana',
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
                        const Text(
                          'No equipment categories currently available. Please contact support.',
                          style: TextStyle(color: AppTheme.errorColor),
                        ),
                      ] else ...[
                        // Visual Equipment Quick-Picker Carousel
                        SizedBox(
                          height: 82,
                          child: ListView.separated(
                            scrollDirection: Axis.horizontal,
                            itemCount: availableCategories.length,
                            separatorBuilder: (context, index) => const SizedBox(width: 8),
                            itemBuilder: (context, idx) {
                              final cat = availableCategories[idx];
                              final isSelected = _selectedIssueCode == cat.code;
                              return InkWell(
                                onTap: () => setState(() => _selectedIssueCode = cat.code),
                                borderRadius: BorderRadius.circular(10),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  width: 88,
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: isSelected ? const Color(0xFFE0F2FE) : Colors.white,
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                      color: isSelected ? const Color(0xFF0284C7) : AppTheme.cardBorderColor,
                                      width: isSelected ? 2 : 1,
                                    ),
                                    boxShadow: isSelected
                                        ? [
                                            BoxShadow(
                                              color: const Color(0xFF0284C7).withValues(alpha: 0.15),
                                              blurRadius: 4,
                                              offset: const Offset(0, 2),
                                            ),
                                          ]
                                        : null,
                                  ),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(6),
                                        child: Image.asset(
                                          cat.effectiveImageAsset,
                                          width: 38,
                                          height: 38,
                                          fit: BoxFit.cover,
                                          errorBuilder: (context, error, stackTrace) => const Icon(
                                            Icons.build_rounded,
                                            size: 24,
                                            color: AppTheme.primaryColor,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        cat.label,
                                        style: TextStyle(
                                          fontSize: 9.5,
                                          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                                          color: isSelected ? const Color(0xFF0284C7) : AppTheme.textPrimary,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        textAlign: TextAlign.center,
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Dropdown with equipment image thumbnails
                        DropdownButtonFormField<String>(
                          key: ValueKey(_selectedIssueCode),
                          initialValue: _selectedIssueCode,
                          isExpanded: true,
                          decoration: const InputDecoration(
                            hintText: 'Select Equipment Type',
                            prefixIcon: Icon(Icons.category_outlined),
                          ),
                          items: availableCategories.map((item) {
                            return DropdownMenuItem<String>(
                              value: item.code,
                              child: Row(
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(4),
                                    child: Image.asset(
                                      item.effectiveImageAsset,
                                      width: 24,
                                      height: 24,
                                      fit: BoxFit.cover,
                                      errorBuilder: (context, error, stackTrace) => const Icon(
                                        Icons.build_rounded,
                                        size: 16,
                                        color: AppTheme.primaryColor,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      item.label,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                          onChanged: (val) {
                            setState(() => _selectedIssueCode = val);
                          },
                          validator: (val) => val == null ? 'Please select equipment' : null,
                        ),

                        // Selected equipment preview highlight banner
                        if (_selectedIssueCode != null) ...[
                          Builder(
                            builder: (context) {
                              final sel = availableCategories
                                  .where((c) => c.code == _selectedIssueCode)
                                  .firstOrNull;
                              if (sel == null) return const SizedBox.shrink();

                              return Container(
                                margin: const EdgeInsets.only(top: 10),
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF1F5F9),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: const Color(0xFFCBD5E1)),
                                ),
                                child: Row(
                                  children: [
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: Image.asset(
                                        sel.effectiveImageAsset,
                                        width: 48,
                                        height: 48,
                                        fit: BoxFit.cover,
                                        errorBuilder: (context, error, stackTrace) => const Icon(
                                          Icons.build_rounded,
                                          size: 24,
                                          color: AppTheme.primaryColor,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                decoration: BoxDecoration(
                                                  color: const Color(0xFFE0F2FE),
                                                  borderRadius: BorderRadius.circular(4),
                                                ),
                                                child: const Text(
                                                  'SELECTED FOR SERVICE',
                                                  style: TextStyle(
                                                    fontSize: 9.5,
                                                    fontWeight: FontWeight.w700,
                                                    color: Color(0xFF0284C7),
                                                    letterSpacing: 0.3,
                                                  ),
                                                ),
                                              ),
                                              const Spacer(),
                                              const Icon(
                                                Icons.check_circle_rounded,
                                                size: 16,
                                                color: Color(0xFF10B981),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            sel.label,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w700,
                                              fontSize: 13,
                                              color: AppTheme.textPrimary,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ],
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

                      // Address Line 1
                      TextFormField(
                        controller: _addressLineController,
                        decoration: const InputDecoration(
                          labelText: 'Address Line 1 / Flat / Building / Room *',
                          hintText: 'Enter clinic building, door, room or floor no.',
                          prefixIcon: Icon(Icons.home_work_outlined),
                        ),
                        validator: (val) => Validators.required(val, '1st line address'),
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
                                labelText: 'Locality / Area *',
                                hintText: 'e.g. Banjara Hills',
                              ),
                              validator: (val) => Validators.required(val, 'Area'),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),

                      // City & State
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _cityController,
                              decoration: const InputDecoration(
                                labelText: 'City *',
                                prefixIcon: Icon(Icons.location_city_outlined),
                              ),
                              validator: (val) => Validators.required(val, 'City'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextFormField(
                              controller: _stateController,
                              decoration: const InputDecoration(
                                labelText: 'State *',
                                prefixIcon: Icon(Icons.map_outlined),
                              ),
                              validator: (val) => Validators.required(val, 'State'),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),

                      // Pincode
                      TextFormField(
                        controller: _pincodeController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Pincode *',
                          hintText: 'e.g. 500034',
                          prefixIcon: Icon(Icons.pin_drop_outlined),
                        ),
                        validator: (val) => Validators.pincode(val, config.serviceablePincodePrefixes),
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
