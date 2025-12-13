/// Cotação de seguro para uma reserva.
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
      'booking_id': bookingId,
      'vehicle_id': vehicleId,
      'partner_id': partnerId,
      'partner_name': partnerName,
      'coverage_type': coverageType,
      'coverage_details': coverageDetails,
      'vehicle_value': vehicleValue,
      'daily_rate': dailyRate,
      'total_premium': totalPremium,
      'deductible': deductible,
      'valid_until': validUntil.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory InsuranceQuote.fromMap(Map<String, dynamic> map) {
    return InsuranceQuote(
      id: map['id'] ?? '',
      bookingId: map['booking_id'] ?? '',
      vehicleId: map['vehicle_id'] ?? '',
      partnerId: map['partner_id'] ?? '',
      partnerName: map['partner_name'] ?? '',
      coverageType: map['coverage_type'] ?? '',
      coverageDetails: Map<String, dynamic>.from(map['coverage_details'] ?? {}),
      vehicleValue: (map['vehicle_value'] ?? 0).toDouble(),
      dailyRate: (map['daily_rate'] ?? 0).toDouble(),
      totalPremium: (map['total_premium'] ?? 0).toDouble(),
      deductible: (map['deductible'] ?? 0).toDouble(),
      validUntil: DateTime.parse(map['valid_until']),
      createdAt: DateTime.parse(map['created_at']),
    );
  }
}

/// Apólice de seguro ativa.
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
  final String status;
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
      'policy_number': policyNumber,
      'quote_id': quoteId,
      'booking_id': bookingId,
      'vehicle_id': vehicleId,
      'partner_id': partnerId,
      'partner_name': partnerName,
      'coverage_type': coverageType,
      'coverage_details': coverageDetails,
      'start_date': startDate.toIso8601String(),
      'end_date': endDate.toIso8601String(),
      'premium': premium,
      'deductible': deductible,
      'status': status,
      'payment_method': paymentMethod,
      'payment_status': paymentStatus,
      'created_at': createdAt.toIso8601String(),
      'cancelled_at': cancelledAt?.toIso8601String(),
      'cancellation_reason': cancellationReason,
    };
  }

  factory InsurancePolicy.fromMap(Map<String, dynamic> map) {
    return InsurancePolicy(
      policyNumber: map['policy_number'] ?? '',
      quoteId: map['quote_id'] ?? '',
      bookingId: map['booking_id'] ?? '',
      vehicleId: map['vehicle_id'] ?? '',
      partnerId: map['partner_id'] ?? '',
      partnerName: map['partner_name'] ?? '',
      coverageType: map['coverage_type'] ?? '',
      coverageDetails: Map<String, dynamic>.from(map['coverage_details'] ?? {}),
      startDate: DateTime.parse(map['start_date']),
      endDate: DateTime.parse(map['end_date']),
      premium: (map['premium'] ?? 0).toDouble(),
      deductible: (map['deductible'] ?? 0).toDouble(),
      status: map['status'] ?? '',
      paymentMethod: map['payment_method'] ?? '',
      paymentStatus: map['payment_status'] ?? '',
      createdAt: DateTime.parse(map['created_at']),
      cancelledAt: map['cancelled_at'] != null
          ? DateTime.parse(map['cancelled_at'])
          : null,
      cancellationReason: map['cancellation_reason'],
    );
  }

  bool get isActive => status == 'active' && endDate.isAfter(DateTime.now());
}

/// Sinistro de seguro.
class InsuranceClaim {
  final String claimNumber;
  final String policyNumber;
  final String type;
  final String description;
  final List<String> photos;
  final String status;
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
      'claim_number': claimNumber,
      'policy_number': policyNumber,
      'type': type,
      'description': description,
      'photos': photos,
      'status': status,
      'estimated_amount': estimatedAmount,
      'approved_amount': approvedAmount,
      'deductible': deductible,
      'submitted_at': submittedAt.toIso8601String(),
      'reviewed_at': reviewedAt?.toIso8601String(),
      'resolved_at': resolvedAt?.toIso8601String(),
      'review_notes': reviewNotes,
      'additional_info': additionalInfo,
    };
  }

  factory InsuranceClaim.fromMap(Map<String, dynamic> map) {
    return InsuranceClaim(
      claimNumber: map['claim_number'] ?? '',
      policyNumber: map['policy_number'] ?? '',
      type: map['type'] ?? '',
      description: map['description'] ?? '',
      photos: List<String>.from(map['photos'] ?? []),
      status: map['status'] ?? '',
      estimatedAmount: (map['estimated_amount'] ?? 0).toDouble(),
      approvedAmount: map['approved_amount']?.toDouble(),
      deductible: (map['deductible'] ?? 0).toDouble(),
      submittedAt: DateTime.parse(map['submitted_at']),
      reviewedAt: map['reviewed_at'] != null
          ? DateTime.parse(map['reviewed_at'])
          : null,
      resolvedAt: map['resolved_at'] != null
          ? DateTime.parse(map['resolved_at'])
          : null,
      reviewNotes: map['review_notes'],
      additionalInfo: Map<String, dynamic>.from(map['additional_info'] ?? {}),
    );
  }
}
