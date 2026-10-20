import 'package:cloud_firestore/cloud_firestore.dart';

/// Individual equipment category item configured in appSettings/bookingConfig.
class IssueTypeItem {
  final String code;
  final String label;
  final bool active;
  final String? imageAsset;

  const IssueTypeItem({
    required this.code,
    required this.label,
    this.active = true,
    this.imageAsset,
  });

  factory IssueTypeItem.fromMap(Map<String, dynamic> map) {
    return IssueTypeItem(
      code: map['code'] as String? ?? '',
      label: map['label'] as String? ?? '',
      active: map['active'] as bool? ?? true,
      imageAsset: map['imageAsset'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{
      'code': code,
      'label': label,
      'active': active,
    };
    if (imageAsset != null && imageAsset!.isNotEmpty) {
      map['imageAsset'] = imageAsset;
    }
    return map;
  }

  /// Default asset fallback by equipment code
  static String defaultImageAssetForCode(String code) {
    switch (code) {
      case 'dental_chair':
        return 'assets/images/equipment/dental_chair.jpg';
      case 'autoclave':
        return 'assets/images/equipment/autoclave.jpg';
      case 'xray_rvg':
        return 'assets/images/equipment/xray_rvg.jpg';
      case 'air_compressor':
        return 'assets/images/equipment/air_compressor.jpg';
      case 'handpieces':
        return 'assets/images/equipment/handpieces.jpg';
      case 'suction_piping':
        return 'assets/images/equipment/suction_piping.jpg';
      case 'scalers_lightcure':
        return 'assets/images/equipment/scalers_lightcure.jpg';
      case 'intraoral_scanner':
        return 'assets/images/equipment/intraoral_scanner.jpg';
      case 'dental_laser':
        return 'assets/images/equipment/dental_laser.jpg';
      case 'endomotor':
        return 'assets/images/equipment/endomotor.jpg';
      case 'other':
      default:
        return 'assets/images/equipment/other.jpg';
    }
  }

  /// Resolves the effective image asset path, falling back to default mapping if null or empty.
  String get effectiveImageAsset {
    if (imageAsset != null && imageAsset!.trim().isNotEmpty) {
      return imageAsset!;
    }
    return defaultImageAssetForCode(code);
  }

  /// Available equipment image presets for Admin Settings category creation/editing.
  static const List<Map<String, String>> availableEquipmentImages = [
    {'name': 'Dental Chair', 'path': 'assets/images/equipment/dental_chair.jpg'},
    {'name': 'Autoclave', 'path': 'assets/images/equipment/autoclave.jpg'},
    {'name': 'X-Ray & RVG', 'path': 'assets/images/equipment/xray_rvg.jpg'},
    {'name': 'Air Compressor', 'path': 'assets/images/equipment/air_compressor.jpg'},
    {'name': 'Handpieces & Micromotors', 'path': 'assets/images/equipment/handpieces.jpg'},
    {'name': 'Suction & Piping', 'path': 'assets/images/equipment/suction_piping.jpg'},
    {'name': 'Scalers & Light Cure', 'path': 'assets/images/equipment/scalers_lightcure.jpg'},
    {'name': 'Intraoral Scanner', 'path': 'assets/images/equipment/intraoral_scanner.jpg'},
    {'name': 'Dental Laser', 'path': 'assets/images/equipment/dental_laser.jpg'},
    {'name': 'Endomotor & Apex Locator', 'path': 'assets/images/equipment/endomotor.jpg'},
    {'name': 'General Maintenance / Other', 'path': 'assets/images/equipment/other.jpg'},
  ];

  /// Deduplicates a list of issue types preserving first-seen order for each unique code.
  static List<IssueTypeItem> deduplicateByCode(List<IssueTypeItem> items) {
    final seen = <String>{};
    final result = <IssueTypeItem>[];
    for (final item in items) {
      if (item.code.isNotEmpty && seen.add(item.code)) {
        result.add(item);
      }
    }
    return result;
  }
}

/// Time slot definition configured in appSettings/bookingConfig.
class TimeSlotItem {
  final String key;
  final String label;
  final int startHour;
  final int startMinute;
  final int endHour;
  final int endMinute;

  const TimeSlotItem({
    required this.key,
    required this.label,
    required this.startHour,
    this.startMinute = 0,
    required this.endHour,
    this.endMinute = 0,
  });

  factory TimeSlotItem.fromMap(Map<String, dynamic> map) {
    return TimeSlotItem(
      key: map['key'] as String? ?? '',
      label: map['label'] as String? ?? '',
      startHour: (map['startHour'] as num?)?.toInt() ?? 9,
      startMinute: (map['startMinute'] as num?)?.toInt() ?? 0,
      endHour: (map['endHour'] as num?)?.toInt() ?? 12,
      endMinute: (map['endMinute'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'key': key,
      'label': label,
      'startHour': startHour,
      'startMinute': startMinute,
      'endHour': endHour,
      'endMinute': endMinute,
    };
  }

  /// Constructs a DateTime representing the start of this slot on the given [date].
  DateTime getStartDateTime(DateTime date) {
    return DateTime(date.year, date.month, date.day, startHour, startMinute);
  }

  /// Constructs a DateTime representing the end of this slot on the given [date].
  DateTime getEndDateTime(DateTime date) {
    return DateTime(date.year, date.month, date.day, endHour, endMinute);
  }
}

/// Application-wide booking configuration loaded from appSettings/bookingConfig in Firestore.
class BookingConfigModel {
  final List<IssueTypeItem> issueTypes;
  final List<TimeSlotItem> slots;
  final int maxDaysAhead;
  final int minLeadMinutes;
  final List<String> serviceablePincodePrefixes;
  final List<String> doctorCancelReasons;
  final List<String> adminCancelReasons;
  final String supportPhone;
  final int maxOpenRequests;
  final DateTime? updatedAt;

  const BookingConfigModel({
    required this.issueTypes,
    required this.slots,
    required this.maxDaysAhead,
    required this.minLeadMinutes,
    required this.serviceablePincodePrefixes,
    required this.doctorCancelReasons,
    required this.adminCancelReasons,
    required this.supportPhone,
    required this.maxOpenRequests,
    this.updatedAt,
  });

  BookingConfigModel copyWith({
    List<IssueTypeItem>? issueTypes,
    List<TimeSlotItem>? slots,
    int? maxDaysAhead,
    int? minLeadMinutes,
    List<String>? serviceablePincodePrefixes,
    List<String>? doctorCancelReasons,
    List<String>? adminCancelReasons,
    String? supportPhone,
    int? maxOpenRequests,
    DateTime? updatedAt,
  }) {
    return BookingConfigModel(
      issueTypes: issueTypes ?? this.issueTypes,
      slots: slots ?? this.slots,
      maxDaysAhead: maxDaysAhead ?? this.maxDaysAhead,
      minLeadMinutes: minLeadMinutes ?? this.minLeadMinutes,
      serviceablePincodePrefixes: serviceablePincodePrefixes ?? this.serviceablePincodePrefixes,
      doctorCancelReasons: doctorCancelReasons ?? this.doctorCancelReasons,
      adminCancelReasons: adminCancelReasons ?? this.adminCancelReasons,
      supportPhone: supportPhone ?? this.supportPhone,
      maxOpenRequests: maxOpenRequests ?? this.maxOpenRequests,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  List<IssueTypeItem> get activeIssueTypes =>
      issueTypes.where((item) => item.active).toList();

  /// Default configuration per RioDent MVP Brief.
  factory BookingConfigModel.defaultConfig() {
    return BookingConfigModel(
      issueTypes: [
        const IssueTypeItem(code: 'dental_chair', label: 'Dental Chair', active: true),
        const IssueTypeItem(code: 'autoclave', label: 'Autoclave', active: true),
        const IssueTypeItem(code: 'xray_rvg', label: 'X-Ray & RVG', active: true),
        const IssueTypeItem(code: 'air_compressor', label: 'Air Compressor', active: true),
        const IssueTypeItem(code: 'handpieces', label: 'Handpieces & Micromotors', active: true),
        const IssueTypeItem(code: 'suction_piping', label: 'Suction & Piping', active: true),
        const IssueTypeItem(code: 'scalers_lightcure', label: 'Scalers & Light Cure', active: true),
        const IssueTypeItem(code: 'other', label: 'Other Equipment Issue', active: true),
      ],
      slots: const [
        TimeSlotItem(
          key: '09_12',
          label: '9 AM to 12 PM',
          startHour: 9,
          startMinute: 0,
          endHour: 12,
          endMinute: 0,
        ),
        TimeSlotItem(
          key: '14_17',
          label: '2 PM to 5 PM',
          startHour: 14,
          startMinute: 0,
          endHour: 17,
          endMinute: 0,
        ),
        TimeSlotItem(
          key: '18_21',
          label: '6 PM to 9 PM',
          startHour: 18,
          startMinute: 0,
          endHour: 21,
          endMinute: 0,
        ),
      ],
      maxDaysAhead: 7,
      minLeadMinutes: 30,
      serviceablePincodePrefixes: const ['500', '501', '502'],
      doctorCancelReasons: const [
        'Issue resolved on its own',
        'Booked by mistake or wrong details',
        'Found another technician',
        'Technician did not call',
        'No longer needed',
        'Other',
      ],
      adminCancelReasons: const [
        'Outside service area',
        'No technician available',
        'Equipment type not supported',
        'Doctor not reachable',
        'Duplicate request',
        'Doctor asked to cancel',
        'Technician unable to attend',
        'Other',
      ],
      supportPhone: '+91 98765 43210',
      maxOpenRequests: 3,
    );
  }

  /// Determines if a time slot can be booked relative to [now].
  static bool isSlotBookable({
    required DateTime slotStart,
    required DateTime now,
    int minLeadMinutes = 30,
  }) {
    // Must be in future and at least minLeadMinutes ahead of now
    final earliestAllowed = now.add(Duration(minutes: minLeadMinutes));
    return slotStart.isAfter(earliestAllowed);
  }

  factory BookingConfigModel.fromMap(Map<String, dynamic> data) {
    final defaultCfg = BookingConfigModel.defaultConfig();

    // Parse issue types (support both Object maps and legacy String list)
    List<IssueTypeItem> parsedIssueTypes = [];
    final rawIssueTypes = data['issueTypes'];
    if (rawIssueTypes is List) {
      for (final item in rawIssueTypes) {
        if (item is Map) {
          parsedIssueTypes.add(IssueTypeItem.fromMap(Map<String, dynamic>.from(item)));
        } else if (item is String) {
          final code = item.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '_');
          parsedIssueTypes.add(IssueTypeItem(code: code, label: item, active: true));
        }
      }
    }
    if (parsedIssueTypes.isEmpty) {
      parsedIssueTypes = defaultCfg.issueTypes;
    }
    parsedIssueTypes = IssueTypeItem.deduplicateByCode(parsedIssueTypes);

    // Parse slots
    List<TimeSlotItem> parsedSlots = [];
    final rawSlots = data['slots'];
    if (rawSlots is List) {
      for (final item in rawSlots) {
        if (item is Map) {
          parsedSlots.add(TimeSlotItem.fromMap(Map<String, dynamic>.from(item)));
        }
      }
    }
    if (parsedSlots.isEmpty) {
      parsedSlots = defaultCfg.slots;
    }

    return BookingConfigModel(
      issueTypes: parsedIssueTypes,
      slots: parsedSlots,
      maxDaysAhead: (data['maxDaysAhead'] as num?)?.toInt() ?? defaultCfg.maxDaysAhead,
      minLeadMinutes: (data['minLeadMinutes'] as num?)?.toInt() ?? defaultCfg.minLeadMinutes,
      serviceablePincodePrefixes: (data['serviceablePincodePrefixes'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          defaultCfg.serviceablePincodePrefixes,
      doctorCancelReasons: (data['doctorCancelReasons'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          defaultCfg.doctorCancelReasons,
      adminCancelReasons: (data['adminCancelReasons'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          defaultCfg.adminCancelReasons,
      supportPhone: data['supportPhone'] as String? ?? defaultCfg.supportPhone,
      maxOpenRequests: (data['maxOpenRequests'] as num?)?.toInt() ?? defaultCfg.maxOpenRequests,
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
    );
  }

  factory BookingConfigModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    if (!doc.exists || doc.data() == null) {
      return BookingConfigModel.defaultConfig();
    }
    return BookingConfigModel.fromMap(doc.data()!);
  }

  Map<String, dynamic> toMap() {
    return {
      'issueTypes': issueTypes.map((e) => e.toMap()).toList(),
      'slots': slots.map((e) => e.toMap()).toList(),
      'maxDaysAhead': maxDaysAhead,
      'minLeadMinutes': minLeadMinutes,
      'serviceablePincodePrefixes': serviceablePincodePrefixes,
      'doctorCancelReasons': doctorCancelReasons,
      'adminCancelReasons': adminCancelReasons,
      'supportPhone': supportPhone,
      'maxOpenRequests': maxOpenRequests,
      'updatedAt': Timestamp.now(),
    };
  }
}
