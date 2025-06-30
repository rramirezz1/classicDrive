import 'package:cloud_firestore/cloud_firestore.dart';

// Cotação de seguro
class InsuranceQuote {
  final String id;
  final String bookingId;
  final String vehicleId;
  final String partnerId;
  final String partnerName;
  final String coverageType;
  final Map<String, dynamic> coverageDetails;
  final double vehicleValue;
  final double dailyRate;
  final double totalPremium;
  final double deductible;
  final DateTime validUntil;
  final DateTime createdAt;

  InsuranceQuote({
    required this.id,
    required this.bookingId,
    required this.vehicleId,
    required this.partnerId,
    required this.partnerName,
    required this.coverageType,
    required this.coverageDetails,
    required this.vehicleValue,
    required this.dailyRate,
    required this.totalPremium,
    required this.deductible,
    required this.validUntil,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'bookingId': bookingId,
      'vehicleId': vehicleId,
      'partnerId': partnerId,
      'partnerName': partnerName,
      'coverageType': coverageType,
      'coverageDetails': coverageDetails,
      'vehicleValue': vehicleValue,
      'dailyRate': dailyRate,
      'totalPremium': totalPremium,
      'deductible': deductible,
      'validUntil': Timestamp.fromDate(validUntil),
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  factory InsuranceQuote.fromMap(Map<String, dynamic> map) {
    return InsuranceQuote(
      id: map['id'] ?? '',
      bookingId: map['bookingId'] ?? '',
      vehicleId: map['vehicleId'] ?? '',
      partnerId: map['partnerId'] ?? '',
      partnerName: map['partnerName'] ?? '',
      coverageType: map['coverageType'] ?? '',
      coverageDetails: Map<String, dynamic>.from(map['coverageDetails'] ?? {}),
      vehicleValue: (map['vehicleValue'] ?? 0).toDouble(),
      dailyRate: (map['dailyRate'] ?? 0).toDouble(),
      totalPremium: (map['totalPremium'] ?? 0).toDouble(),
      deductible: (map['deductible'] ?? 0).toDouble(),
      validUntil: (map['validUntil'] as Timestamp).toDate(),
      createdAt: (map['createdAt'] as Timestamp).toDate(),
    );
  }
}

// Apólice de seguro
class InsurancePolicy {
  final String policyNumber;
  final String quoteId;
  final String bookingId;
  final String vehicleId;
  final String partnerId;
  final String partnerName;
  final String coverageType;
  final Map<String, dynamic> coverageDetails;
  final DateTime startDate;
  final DateTime endDate;
  final double premium;
  final double deductible;
  final String status; // active, expired, cancelled
  final String paymentMethod;
  final String paymentStatus;
  final DateTime createdAt;
  final DateTime? cancelledAt;
  final String? cancellationReason;

  InsurancePolicy({
    required this.policyNumber,
    required this.quoteId,
    required this.bookingId,
    required this.vehicleId,
    required this.partnerId,
    required this.partnerName,
    required this.coverageType,
    required this.coverageDetails,
    required this.startDate,
    required this.endDate,
    required this.premium,
    required this.deductible,
    required this.status,
    required this.paymentMethod,
    required this.paymentStatus,
    required this.createdAt,
    this.cancelledAt,
    this.cancellationReason,
  });

  Map<String, dynamic> toMap() {
    return {
      'policyNumber': policyNumber,
      'quoteId': quoteId,
      'bookingId': bookingId,
      'vehicleId': vehicleId,
      'partnerId': partnerId,
      'partnerName': partnerName,
      'coverageType': coverageType,
      'coverageDetails': coverageDetails,
      'startDate': Timestamp.fromDate(startDate),
      'endDate': Timestamp.fromDate(endDate),
      'premium': premium,
      'deductible': deductible,
      'status': status,
      'paymentMethod': paymentMethod,
      'paymentStatus': paymentStatus,
      'createdAt': Timestamp.fromDate(createdAt),
      'cancelledAt':
          cancelledAt != null ? Timestamp.fromDate(cancelledAt!) : null,
      'cancellationReason': cancellationReason,
    };
  }

  factory InsurancePolicy.fromMap(Map<String, dynamic> map) {
    return InsurancePolicy(
      policyNumber: map['policyNumber'] ?? '',
      quoteId: map['quoteId'] ?? '',
      bookingId: map['bookingId'] ?? '',
      vehicleId: map['vehicleId'] ?? '',
      partnerId: map['partnerId'] ?? '',
      partnerName: map['partnerName'] ?? '',
      coverageType: map['coverageType'] ?? '',
      coverageDetails: Map<String, dynamic>.from(map['coverageDetails'] ?? {}),
      startDate: (map['startDate'] as Timestamp).toDate(),
      endDate: (map['endDate'] as Timestamp).toDate(),
      premium: (map['premium'] ?? 0).toDouble(),
      deductible: (map['deductible'] ?? 0).toDouble(),
      status: map['status'] ?? '',
      paymentMethod: map['paymentMethod'] ?? '',
      paymentStatus: map['paymentStatus'] ?? '',
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      cancelledAt: map['cancelledAt'] != null
          ? (map['cancelledAt'] as Timestamp).toDate()
          : null,
      cancellationReason: map['cancellationReason'],
    );
  }

  bool get isActive => status == 'active' && endDate.isAfter(DateTime.now());
}

// Sinistro/Claim
class InsuranceClaim {
  final String claimNumber;
  final String policyNumber;
  final String type; // accident, theft, damage
  final String description;
  final List<String> photos;
  final String status; // submitted, in_review, approved, rejected, paid
  final double estimatedAmount;
  final double? approvedAmount;
  final double deductible;
  final DateTime submittedAt;
  final DateTime? reviewedAt;
  final DateTime? resolvedAt;
  final String? reviewNotes;
  final Map<String, dynamic> additionalInfo;

  InsuranceClaim({
    required this.claimNumber,
    required this.policyNumber,
    required this.type,
    required this.description,
    required this.photos,
    required this.status,
    required this.estimatedAmount,
    this.approvedAmount,
    required this.deductible,
    required this.submittedAt,
    this.reviewedAt,
    this.resolvedAt,
    this.reviewNotes,
    required this.additionalInfo,
  });

  Map<String, dynamic> toMap() {
    return {
      'claimNumber': claimNumber,
      'policyNumber': policyNumber,
      'type': type,
      'description': description,
      'photos': photos,
      'status': status,
      'estimatedAmount': estimatedAmount,
      'approvedAmount': approvedAmount,
      'deductible': deductible,
      'submittedAt': Timestamp.fromDate(submittedAt),
      'reviewedAt': reviewedAt != null ? Timestamp.fromDate(reviewedAt!) : null,
      'resolvedAt': resolvedAt != null ? Timestamp.fromDate(resolvedAt!) : null,
      'reviewNotes': reviewNotes,
      'additionalInfo': additionalInfo,
    };
  }

  factory InsuranceClaim.fromMap(Map<String, dynamic> map) {
    return InsuranceClaim(
      claimNumber: map['claimNumber'] ?? '',
      policyNumber: map['policyNumber'] ?? '',
      type: map['type'] ?? '',
      description: map['description'] ?? '',
      photos: List<String>.from(map['photos'] ?? []),
      status: map['status'] ?? '',
      estimatedAmount: (map['estimatedAmount'] ?? 0).toDouble(),
      approvedAmount: map['approvedAmount']?.toDouble(),
      deductible: (map['deductible'] ?? 0).toDouble(),
      submittedAt: (map['submittedAt'] as Timestamp).toDate(),
      reviewedAt: map['reviewedAt'] != null
          ? (map['reviewedAt'] as Timestamp).toDate()
          : null,
      resolvedAt: map['resolvedAt'] != null
          ? (map['resolvedAt'] as Timestamp).toDate()
          : null,
      reviewNotes: map['reviewNotes'],
      additionalInfo: Map<String, dynamic>.from(map['additionalInfo'] ?? {}),
    );
  }
}
