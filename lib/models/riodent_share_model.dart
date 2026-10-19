import 'package:cloud_firestore/cloud_firestore.dart';

/// Financial record of RioDent's 10% share for an individual eligible completed bill.
class RioDentBillRecord {
  final String ticketId;
  final String displayTicketId;
  final String doctorId;
  final String doctorName;
  final String clinicName;
  final double doctorPaymentAmount;
  final double technicianPaymentAmount;
  final double shareRate; // 0.10
  final double calculatedShare; // doctorPaymentAmount * 0.10
  final String paymentStatus; // 'PAID'
  final DateTime billDate;
  final DateTime createdAt;
  final bool isSettled;
  final String? settlementId;
  final DateTime? settledAt;

  const RioDentBillRecord({
    required this.ticketId,
    required this.displayTicketId,
    required this.doctorId,
    required this.doctorName,
    required this.clinicName,
    required this.doctorPaymentAmount,
    required this.technicianPaymentAmount,
    this.shareRate = 0.10,
    required this.calculatedShare,
    required this.paymentStatus,
    required this.billDate,
    required this.createdAt,
    required this.isSettled,
    this.settlementId,
    this.settledAt,
  });
}

/// Settlement batch document stored in 'riodent_settlements' collection.
class RioDentSettlementModel {
  final String id;
  final double amountSettled;
  final int billCount;
  final List<String> requestIds;
  final String settledBy;
  final DateTime settledAt;
  final String? notes;

  const RioDentSettlementModel({
    required this.id,
    required this.amountSettled,
    required this.billCount,
    required this.requestIds,
    required this.settledBy,
    required this.settledAt,
    this.notes,
  });

  factory RioDentSettlementModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    DateTime parsedDate;
    final val = data['settledAt'];
    if (val is Timestamp) {
      parsedDate = val.toDate();
    } else if (val is String) {
      parsedDate = DateTime.tryParse(val) ?? DateTime.now();
    } else {
      parsedDate = DateTime.now();
    }

    return RioDentSettlementModel(
      id: doc.id,
      amountSettled: (data['amountSettled'] as num?)?.toDouble() ?? 0.0,
      billCount: (data['billCount'] as num?)?.toInt() ?? 0,
      requestIds: List<String>.from(data['requestIds'] ?? []),
      settledBy: data['settledBy'] as String? ?? '',
      settledAt: parsedDate,
      notes: data['notes'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'amountSettled': amountSettled,
      'billCount': billCount,
      'requestIds': requestIds,
      'settledBy': settledBy,
      'settledAt': Timestamp.fromDate(settledAt),
      if (notes != null) 'notes': notes,
    };
  }
}

/// Aggregated RioDent Share financial summary.
class RioDentShareSummary {
  final double totalDoctorPaid;
  final double totalShareEarned; // 10% of totalDoctorPaid
  final double totalShareSettled; // sum of settlements
  final double unsettledShare; // max(0, totalShareEarned - totalShareSettled)
  final int eligibleBillsCount;
  final RioDentSettlementModel? latestSettlement;
  final List<RioDentBillRecord> bills;

  const RioDentShareSummary({
    required this.totalDoctorPaid,
    required this.totalShareEarned,
    required this.totalShareSettled,
    required this.unsettledShare,
    required this.eligibleBillsCount,
    this.latestSettlement,
    this.bills = const [],
  });

  factory RioDentShareSummary.empty() {
    return const RioDentShareSummary(
      totalDoctorPaid: 0.0,
      totalShareEarned: 0.0,
      totalShareSettled: 0.0,
      unsettledShare: 0.0,
      eligibleBillsCount: 0,
      latestSettlement: null,
      bills: [],
    );
  }
}
