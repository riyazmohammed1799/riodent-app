import 'package:cloud_firestore/cloud_firestore.dart';
import '../utils/constants.dart';

/// Structured clinic address per Section 3.9 data model.
class RequestAddress {
  final String line;
  final String? landmark;
  final String? area;
  final String city;
  final String pincode;
  final double lat;
  final double lng;

  const RequestAddress({
    required this.line,
    this.landmark,
    this.area,
    this.city = 'Hyderabad',
    required this.pincode,
    this.lat = 0.0,
    this.lng = 0.0,
  });

  String get fullAddress {
    final parts = [
      line,
      if (landmark != null && landmark!.isNotEmpty) 'Near $landmark',
      if (area != null && area!.isNotEmpty) area,
      city,
      if (pincode.isNotEmpty) pincode,
    ];
    return parts.where((p) => p != null && p.trim().isNotEmpty).join(', ');
  }

  factory RequestAddress.fromMap(Map<String, dynamic> map) {
    return RequestAddress(
      line: map['line'] as String? ?? '',
      landmark: map['landmark'] as String?,
      area: map['area'] as String?,
      city: map['city'] as String? ?? 'Hyderabad',
      pincode: map['pincode'] as String? ?? '',
      lat: (map['lat'] as num?)?.toDouble() ?? 0.0,
      lng: (map['lng'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'line': line,
      if (landmark != null && landmark!.isNotEmpty) 'landmark': landmark,
      if (area != null && area!.isNotEmpty) 'area': area,
      'city': city,
      'pincode': pincode,
      'lat': lat,
      'lng': lng,
    };
  }
}

/// Event record appended to technicianRequests/{id}/events for audit and status history.
class RequestEvent {
  final String status;
  final String by; // 'dentist' | 'admin'
  final DateTime at;
  final String? note;

  const RequestEvent({
    required this.status,
    required this.by,
    required this.at,
    this.note,
  });

  factory RequestEvent.fromMap(Map<String, dynamic> map) {
    DateTime parsedAt;
    final atVal = map['at'];
    if (atVal is Timestamp) {
      parsedAt = atVal.toDate();
    } else if (atVal is String) {
      parsedAt = DateTime.tryParse(atVal) ?? DateTime.now();
    } else if (atVal is int) {
      parsedAt = DateTime.fromMillisecondsSinceEpoch(atVal);
    } else {
      parsedAt = DateTime.now();
    }
    return RequestEvent(
      status: map['status'] as String? ?? '',
      by: map['by'] as String? ?? '',
      at: parsedAt,
      note: map['note'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'status': status,
      'by': by,
      'at': Timestamp.fromDate(at),
      if (note != null) 'note': note,
    };
  }
}

/// Service request submitted by a dental doctor for equipment repair.
class TechnicianRequestModel {
  final String id;
  final String ticketNumber; // e.g. REQ-784210
  final String dentistId;
  final String dentistName;
  final String clinicName;
  final String mobile;
  final RequestAddress address;

  // Equipment & Issue details
  final String issueCode;
  final String issueLabel;
  final String issueDescription;

  // Time slot (future IST slot)
  final String slotDate; // e.g. '2026-10-14'
  final String slotKey; // e.g. '09_12'
  final DateTime slotStart;

  // Status & Assignment
  final String status; // NEW, ASSIGNED, IN_PROGRESS, COMPLETED, CANCELLED
  final String? assignedTechnicianId;
  final String? assignedTechnicianName;
  final String? assignedTechnicianPhone;
  final DateTime? assignedAt;
  final DateTime? startedAt;

  // Completion
  final DateTime? completedAt;
  final String? completedBy; // 'dentist' | 'admin'
  final double? amountPaid; // Whole rupees paid to technician

  // Cancellation / Denial
  final DateTime? cancelledAt;
  final String? cancelledBy; // 'dentist' | 'admin'
  final String? reasonCode;
  final String? reasonText;

  // Legacy / convenience fields
  final String? adminNotes;
  final DateTime createdAt;
  final DateTime updatedAt;

  const TechnicianRequestModel({
    required this.id,
    this.ticketNumber = '',
    required this.dentistId,
    required this.dentistName,
    required this.clinicName,
    required this.mobile,
    required this.address,
    required this.issueCode,
    required this.issueLabel,
    required this.issueDescription,
    required this.slotDate,
    required this.slotKey,
    required this.slotStart,
    required this.status,
    this.assignedTechnicianId,
    this.assignedTechnicianName,
    this.assignedTechnicianPhone,
    this.assignedAt,
    this.startedAt,
    this.completedAt,
    this.completedBy,
    this.amountPaid,
    this.cancelledAt,
    this.cancelledBy,
    this.reasonCode,
    this.reasonText,
    this.adminNotes,
    required this.createdAt,
    required this.updatedAt,
  });

  // ── Status Helpers ──────────────────────────────────────────
  bool get isNew => status == AppConstants.statusNew;
  bool get isAssigned => status == AppConstants.statusAssigned;
  bool get isInProgress => status == AppConstants.statusInProgress;
  bool get isCompleted => status == AppConstants.statusCompleted;
  bool get isCancelled => status == AppConstants.statusCancelled;

  bool get isActive => !isCompleted && !isCancelled;

  static bool isTerminal(String status) =>
      status == AppConstants.statusCompleted || status == AppConstants.statusCancelled;

  static bool canDoctorCancel(String status) =>
      status == AppConstants.statusNew || status == AppConstants.statusAssigned;

  static bool canDoctorComplete(String status) =>
      status == AppConstants.statusAssigned || status == AppConstants.statusInProgress;

  static bool canAdminAssign(String status) =>
      status == AppConstants.statusNew || status == AppConstants.statusAssigned;

  static bool canAdminSetInProgress({required String status, required bool hasTechnician}) =>
      status == AppConstants.statusAssigned && hasTechnician;

  static bool canAdminCloseOnBehalf(String status) =>
      status == AppConstants.statusAssigned || status == AppConstants.statusInProgress;

  static bool canAdminCancel(String status) =>
      status == AppConstants.statusNew ||
      status == AppConstants.statusAssigned ||
      status == AppConstants.statusInProgress;

  String get displayTicketId {
    if (ticketNumber.isNotEmpty) return ticketNumber;
    if (id.isNotEmpty) {
      final clean = id.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '');
      final short = clean.length >= 6 ? clean.substring(0, 6).toUpperCase() : clean.toUpperCase();
      return 'REQ-$short';
    }
    return 'REQ-PENDING';
  }

  // Backward compatibility getters
  String get issueType => issueLabel.isNotEmpty ? issueLabel : issueCode;
  String get dentistPhone => mobile;
  String get clinicAddress => address.fullAddress;
  String? get locality => address.area;
  String get city => address.city;
  double get clinicLatitude => address.lat;
  double get clinicLongitude => address.lng;
  String? get cancellationReason => reasonText ?? reasonCode;

  factory TechnicianRequestModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return TechnicianRequestModel.fromMap(data, doc.id);
  }

  factory TechnicianRequestModel.fromMap(Map<String, dynamic> data, [String id = '']) {
    // Address extraction (handles nested map and flat legacy fields)
    RequestAddress parsedAddress;
    if (data['address'] is Map) {
      parsedAddress = RequestAddress.fromMap(Map<String, dynamic>.from(data['address'] as Map));
    } else if (data['address'] is String && (data['address'] as String).isNotEmpty) {
      parsedAddress = RequestAddress(
        line: data['address'] as String,
        landmark: data['landmark'] as String?,
        area: data['locality'] as String? ?? data['area'] as String?,
        city: data['city'] as String? ?? 'Hyderabad',
        pincode: (data['pincode'] ?? '500001').toString(),
        lat: (data['clinicLatitude'] as num?)?.toDouble() ?? (data['lat'] as num?)?.toDouble() ?? 0.0,
        lng: (data['clinicLongitude'] as num?)?.toDouble() ?? (data['lng'] as num?)?.toDouble() ?? 0.0,
      );
    } else {
      parsedAddress = RequestAddress(
        line: data['clinicAddress'] as String? ?? data['addressLine'] as String? ?? '',
        landmark: data['landmark'] as String?,
        area: data['locality'] as String? ?? data['area'] as String?,
        city: data['city'] as String? ?? 'Hyderabad',
        pincode: (data['pincode'] ?? '500001').toString(),
        lat: (data['clinicLatitude'] as num?)?.toDouble() ?? (data['lat'] as num?)?.toDouble() ?? 0.0,
        lng: (data['clinicLongitude'] as num?)?.toDouble() ?? (data['lng'] as num?)?.toDouble() ?? 0.0,
      );
    }

    final now = DateTime.now();

    DateTime parseDate(dynamic val, [DateTime? fallback]) {
      if (val is Timestamp) return val.toDate();
      if (val is String) return DateTime.tryParse(val) ?? fallback ?? now;
      if (val is int) return DateTime.fromMillisecondsSinceEpoch(val);
      return fallback ?? now;
    }

    DateTime? parseNullableDate(dynamic val) {
      if (val == null) return null;
      if (val is Timestamp) return val.toDate();
      if (val is String) return DateTime.tryParse(val);
      if (val is int) return DateTime.fromMillisecondsSinceEpoch(val);
      return null;
    }

    final parsedSlotStart = parseDate(data['slotStart'], parseDate(data['createdAt']));

    return TechnicianRequestModel(
      id: id.isNotEmpty ? id : (data['id'] as String? ?? ''),
      ticketNumber: data['ticketNumber'] as String? ?? '',
      dentistId: data['dentistId'] as String? ?? '',
      dentistName: data['dentistName'] as String? ?? '',
      clinicName: data['clinicName'] as String? ?? '',
      mobile: data['mobile'] as String? ?? data['dentistPhone'] as String? ?? '',
      address: parsedAddress,
      issueCode: data['issueCode'] as String? ?? data['issueType'] as String? ?? '',
      issueLabel: data['issueLabel'] as String? ?? data['issueType'] as String? ?? '',
      issueDescription: data['issueDescription'] as String? ?? '',
      slotDate: data['slotDate'] as String? ?? '',
      slotKey: data['slotKey'] as String? ?? '',
      slotStart: parsedSlotStart,
      status: data['status'] as String? ?? AppConstants.statusNew,
      assignedTechnicianId: data['assignedTechnicianId'] as String?,
      assignedTechnicianName: data['assignedTechnicianName'] as String?,
      assignedTechnicianPhone: data['assignedTechnicianPhone'] as String?,
      assignedAt: parseNullableDate(data['assignedAt']),
      startedAt: parseNullableDate(data['startedAt']),
      completedAt: parseNullableDate(data['completedAt']),
      completedBy: data['completedBy'] as String?,
      amountPaid: (data['amountPaid'] as num?)?.toDouble(),
      cancelledAt: parseNullableDate(data['cancelledAt']),
      cancelledBy: data['cancelledBy'] as String?,
      reasonCode: data['reasonCode'] as String?,
      reasonText: data['reasonText'] as String? ?? data['cancellationReason'] as String?,
      adminNotes: data['adminNotes'] as String?,
      createdAt: parseDate(data['createdAt']),
      updatedAt: parseDate(data['updatedAt']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'dentistId': dentistId,
      if (ticketNumber.isNotEmpty) 'ticketNumber': ticketNumber,
      'dentistName': dentistName,
      'clinicName': clinicName,
      'mobile': mobile,
      'address': address.toMap(),
      // Top-level mirrors for legacy queries & indexing if needed
      'city': address.city,
      'locality': address.area,
      'clinicAddress': address.fullAddress,
      'clinicLatitude': address.lat,
      'clinicLongitude': address.lng,
      'issueCode': issueCode,
      'issueLabel': issueLabel,
      'issueType': issueLabel,
      'issueDescription': issueDescription,
      'slotDate': slotDate,
      'slotKey': slotKey,
      'slotStart': Timestamp.fromDate(slotStart),
      'status': status,
      if (assignedTechnicianId != null) 'assignedTechnicianId': assignedTechnicianId,
      if (assignedTechnicianName != null) 'assignedTechnicianName': assignedTechnicianName,
      if (assignedTechnicianPhone != null) 'assignedTechnicianPhone': assignedTechnicianPhone,
      if (assignedAt != null) 'assignedAt': Timestamp.fromDate(assignedAt!),
      if (startedAt != null) 'startedAt': Timestamp.fromDate(startedAt!),
      if (completedAt != null) 'completedAt': Timestamp.fromDate(completedAt!),
      if (completedBy != null) 'completedBy': completedBy,
      if (amountPaid != null) 'amountPaid': amountPaid,
      if (cancelledAt != null) 'cancelledAt': Timestamp.fromDate(cancelledAt!),
      if (cancelledBy != null) 'cancelledBy': cancelledBy,
      if (reasonCode != null) 'reasonCode': reasonCode,
      if (reasonText != null) 'reasonText': reasonText,
      if (adminNotes != null) 'adminNotes': adminNotes,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  TechnicianRequestModel copyWith({
    String? ticketNumber,
    String? status,
    String? issueCode,
    String? issueLabel,
    String? issueDescription,
    String? slotDate,
    String? slotKey,
    DateTime? slotStart,
    RequestAddress? address,
    String? assignedTechnicianId,
    String? assignedTechnicianName,
    String? assignedTechnicianPhone,
    DateTime? assignedAt,
    DateTime? startedAt,
    DateTime? completedAt,
    String? completedBy,
    double? amountPaid,
    DateTime? cancelledAt,
    String? cancelledBy,
    String? reasonCode,
    String? reasonText,
    String? adminNotes,
    DateTime? updatedAt,
  }) {
    return TechnicianRequestModel(
      id: id,
      ticketNumber: ticketNumber ?? this.ticketNumber,
      dentistId: dentistId,
      dentistName: dentistName,
      clinicName: clinicName,
      mobile: mobile,
      address: address ?? this.address,
      issueCode: issueCode ?? this.issueCode,
      issueLabel: issueLabel ?? this.issueLabel,
      issueDescription: issueDescription ?? this.issueDescription,
      slotDate: slotDate ?? this.slotDate,
      slotKey: slotKey ?? this.slotKey,
      slotStart: slotStart ?? this.slotStart,
      status: status ?? this.status,
      assignedTechnicianId: assignedTechnicianId ?? this.assignedTechnicianId,
      assignedTechnicianName: assignedTechnicianName ?? this.assignedTechnicianName,
      assignedTechnicianPhone: assignedTechnicianPhone ?? this.assignedTechnicianPhone,
      assignedAt: assignedAt ?? this.assignedAt,
      startedAt: startedAt ?? this.startedAt,
      completedAt: completedAt ?? this.completedAt,
      completedBy: completedBy ?? this.completedBy,
      amountPaid: amountPaid ?? this.amountPaid,
      cancelledAt: cancelledAt ?? this.cancelledAt,
      cancelledBy: cancelledBy ?? this.cancelledBy,
      reasonCode: reasonCode ?? this.reasonCode,
      reasonText: reasonText ?? this.reasonText,
      adminNotes: adminNotes ?? this.adminNotes,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
