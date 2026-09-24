import 'package:cloud_firestore/cloud_firestore.dart';
import '../utils/constants.dart';

/// Photo attached to a technician request.
class RequestPhoto {
  final String storagePath;
  final String downloadUrl;
  final DateTime uploadedAt;

  const RequestPhoto({
    required this.storagePath,
    required this.downloadUrl,
    required this.uploadedAt,
  });

  factory RequestPhoto.fromMap(Map<String, dynamic> map) {
    return RequestPhoto(
      storagePath: map['storagePath'] as String? ?? '',
      downloadUrl: map['downloadUrl'] as String? ?? '',
      uploadedAt: (map['uploadedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'storagePath': storagePath,
      'downloadUrl': downloadUrl,
      'uploadedAt': Timestamp.fromDate(uploadedAt),
    };
  }
}

/// Optional single video attached to a technician request.
class RequestVideo {
  final String storagePath;
  final String downloadUrl;
  final DateTime uploadedAt;

  const RequestVideo({
    required this.storagePath,
    required this.downloadUrl,
    required this.uploadedAt,
  });

  factory RequestVideo.fromMap(Map<String, dynamic> map) {
    return RequestVideo(
      storagePath: map['storagePath'] as String? ?? '',
      downloadUrl: map['downloadUrl'] as String? ?? '',
      uploadedAt: (map['uploadedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'storagePath': storagePath,
      'downloadUrl': downloadUrl,
      'uploadedAt': Timestamp.fromDate(uploadedAt),
    };
  }
}

/// Service request submitted by a dentist.
class TechnicianRequestModel {
  final String id;
  final String dentistId;

  // Snapshot fields of dentist at time of submission
  final String dentistName;
  final String dentistPhone;
  final String clinicName;
  final String clinicAddress;
  final double clinicLatitude;
  final double clinicLongitude;

  // Request details
  final String issueType;
  final String issueDescription;
  final List<RequestPhoto> photos;
  final RequestVideo? video;

  // Status and assignment
  final String status; // NEW, ASSIGNED, IN_PROGRESS, COMPLETED, CANCELLED
  final String? assignedTechnicianId;
  final String? assignedTechnicianName;

  // Pricing snapshot at time of booking
  final double listedFee;
  final double payableFee;
  final String currency;
  final String? offerLabel;

  // Internal admin notes
  final String? adminNotes;

  final DateTime createdAt;
  final DateTime updatedAt;

  const TechnicianRequestModel({
    required this.id,
    required this.dentistId,
    required this.dentistName,
    required this.dentistPhone,
    required this.clinicName,
    required this.clinicAddress,
    required this.clinicLatitude,
    required this.clinicLongitude,
    required this.issueType,
    required this.issueDescription,
    required this.photos,
    this.video,
    required this.status,
    this.assignedTechnicianId,
    this.assignedTechnicianName,
    required this.listedFee,
    required this.payableFee,
    required this.currency,
    this.offerLabel,
    this.adminNotes,
    required this.createdAt,
    required this.updatedAt,
  });

  bool get isNew => status == AppConstants.statusNew;
  bool get isAssigned => status == AppConstants.statusAssigned;
  bool get isInProgress => status == AppConstants.statusInProgress;
  bool get isCompleted => status == AppConstants.statusCompleted;
  bool get isCancelled => status == AppConstants.statusCancelled;

  factory TechnicianRequestModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return TechnicianRequestModel(
      id: doc.id,
      dentistId: data['dentistId'] as String? ?? '',
      dentistName: data['dentistName'] as String? ?? '',
      dentistPhone: data['dentistPhone'] as String? ?? '',
      clinicName: data['clinicName'] as String? ?? '',
      clinicAddress: data['clinicAddress'] as String? ?? '',
      clinicLatitude: (data['clinicLatitude'] as num?)?.toDouble() ?? 0.0,
      clinicLongitude: (data['clinicLongitude'] as num?)?.toDouble() ?? 0.0,
      issueType: data['issueType'] as String? ?? '',
      issueDescription: data['issueDescription'] as String? ?? '',
      photos: (data['photos'] as List<dynamic>?)
              ?.map((item) => RequestPhoto.fromMap(Map<String, dynamic>.from(item as Map)))
              .toList() ??
          [],
      video: data['video'] != null
          ? RequestVideo.fromMap(Map<String, dynamic>.from(data['video'] as Map))
          : null,
      status: data['status'] as String? ?? AppConstants.statusNew,
      assignedTechnicianId: data['assignedTechnicianId'] as String?,
      assignedTechnicianName: data['assignedTechnicianName'] as String?,
      listedFee: (data['listedFee'] as num?)?.toDouble() ?? 99.0,
      payableFee: (data['payableFee'] as num?)?.toDouble() ?? 0.0,
      currency: data['currency'] as String? ?? 'INR',
      offerLabel: data['offerLabel'] as String?,
      adminNotes: data['adminNotes'] as String?,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'dentistId': dentistId,
      'dentistName': dentistName,
      'dentistPhone': dentistPhone,
      'clinicName': clinicName,
      'clinicAddress': clinicAddress,
      'clinicLatitude': clinicLatitude,
      'clinicLongitude': clinicLongitude,
      'issueType': issueType,
      'issueDescription': issueDescription,
      'photos': photos.map((p) => p.toMap()).toList(),
      if (video != null) 'video': video!.toMap(),
      'status': status,
      if (assignedTechnicianId != null) 'assignedTechnicianId': assignedTechnicianId,
      if (assignedTechnicianName != null) 'assignedTechnicianName': assignedTechnicianName,
      'listedFee': listedFee,
      'payableFee': payableFee,
      'currency': currency,
      if (offerLabel != null) 'offerLabel': offerLabel,
      if (adminNotes != null) 'adminNotes': adminNotes,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  TechnicianRequestModel copyWith({
    String? status,
    String? assignedTechnicianId,
    String? assignedTechnicianName,
    String? adminNotes,
    DateTime? updatedAt,
  }) {
    return TechnicianRequestModel(
      id: id,
      dentistId: dentistId,
      dentistName: dentistName,
      dentistPhone: dentistPhone,
      clinicName: clinicName,
      clinicAddress: clinicAddress,
      clinicLatitude: clinicLatitude,
      clinicLongitude: clinicLongitude,
      issueType: issueType,
      issueDescription: issueDescription,
      photos: photos,
      video: video,
      status: status ?? this.status,
      assignedTechnicianId: assignedTechnicianId ?? this.assignedTechnicianId,
      assignedTechnicianName: assignedTechnicianName ?? this.assignedTechnicianName,
      listedFee: listedFee,
      payableFee: payableFee,
      currency: currency,
      offerLabel: offerLabel,
      adminNotes: adminNotes ?? this.adminNotes,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
