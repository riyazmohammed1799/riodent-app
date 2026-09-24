import 'package:cloud_firestore/cloud_firestore.dart';
import '../utils/constants.dart';

/// Application-wide booking configuration loaded from appSettings/bookingConfig in Firestore.
class BookingConfigModel {
  final double listedFee;
  final double payableFee;
  final String currency;
  final bool offerEnabled;
  final String offerLabel;
  final int maxPhotos;
  final int maxPhotoSizeMB;
  final int maxVideoSizeMB;
  final int maxVideoDurationSec;
  final List<String> issueTypes;
  final DateTime? updatedAt;

  const BookingConfigModel({
    required this.listedFee,
    required this.payableFee,
    required this.currency,
    required this.offerEnabled,
    required this.offerLabel,
    required this.maxPhotos,
    required this.maxPhotoSizeMB,
    required this.maxVideoSizeMB,
    required this.maxVideoDurationSec,
    required this.issueTypes,
    this.updatedAt,
  });

  /// Default configuration used if Firestore is unreachable or not yet initialized.
  factory BookingConfigModel.defaultConfig() {
    return const BookingConfigModel(
      listedFee: 99.0,
      payableFee: 0.0,
      currency: 'INR',
      offerEnabled: true,
      offerLabel: 'Limited Launch Offer',
      maxPhotos: AppConstants.defaultMaxPhotos,
      maxPhotoSizeMB: AppConstants.defaultMaxPhotoSizeMB,
      maxVideoSizeMB: AppConstants.defaultMaxVideoSizeMB,
      maxVideoDurationSec: AppConstants.defaultMaxVideoDurationSec,
      issueTypes: [
        'Dental Chair Malfunction',
        'Handpiece Repair',
        'Compressor / Suction Issue',
        'Autoclave / Sterilization Failure',
        'X-Ray / Sensor Problem',
        'Scalers & Curing Light',
        'Periodic Maintenance Check',
        'Other Equipment Issue',
      ],
    );
  }

  factory BookingConfigModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    if (!doc.exists || doc.data() == null) {
      return BookingConfigModel.defaultConfig();
    }
    final data = doc.data()!;
    final defaultCfg = BookingConfigModel.defaultConfig();

    return BookingConfigModel(
      listedFee: (data['listedFee'] as num?)?.toDouble() ?? defaultCfg.listedFee,
      payableFee: (data['payableFee'] as num?)?.toDouble() ?? defaultCfg.payableFee,
      currency: data['currency'] as String? ?? defaultCfg.currency,
      offerEnabled: data['offerEnabled'] as bool? ?? defaultCfg.offerEnabled,
      offerLabel: data['offerLabel'] as String? ?? defaultCfg.offerLabel,
      maxPhotos: (data['maxPhotos'] as num?)?.toInt() ?? defaultCfg.maxPhotos,
      maxPhotoSizeMB: (data['maxPhotoSizeMB'] as num?)?.toInt() ?? defaultCfg.maxPhotoSizeMB,
      maxVideoSizeMB: (data['maxVideoSizeMB'] as num?)?.toInt() ?? defaultCfg.maxVideoSizeMB,
      maxVideoDurationSec: (data['maxVideoDurationSec'] as num?)?.toInt() ?? defaultCfg.maxVideoDurationSec,
      issueTypes: (data['issueTypes'] as List<dynamic>?)?.map((e) => e.toString()).toList() ??
          defaultCfg.issueTypes,
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'listedFee': listedFee,
      'payableFee': payableFee,
      'currency': currency,
      'offerEnabled': offerEnabled,
      'offerLabel': offerLabel,
      'maxPhotos': maxPhotos,
      'maxPhotoSizeMB': maxPhotoSizeMB,
      'maxVideoSizeMB': maxVideoSizeMB,
      'maxVideoDurationSec': maxVideoDurationSec,
      'issueTypes': issueTypes,
      'updatedAt': Timestamp.now(),
    };
  }
}
