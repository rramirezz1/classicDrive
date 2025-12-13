import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import '../models/insurance_model.dart';
import '../models/booking_model.dart';
import '../models/vehicle_model.dart';

/// Serviço de gestão de seguros.
class InsuranceService {
  final SupabaseClient _supabase = Supabase.instance.client;
  final _uuid = const Uuid();

  static const List<InsurancePartner> partners = [
    InsurancePartner(
      id: 'liberty',
      name: 'Liberty Seguros',
      logo: 'assets/images/liberty_logo.png',
      baseRate: 0.05,
    ),
    InsurancePartner(
      id: 'allianz',
      name: 'Allianz',
      logo: 'assets/images/allianz_logo.png',
      baseRate: 0.06,
    ),
    InsurancePartner(
      id: 'fidelidade',
      name: 'Fidelidade',
      logo: 'assets/images/fidelidade_logo.png',
      baseRate: 0.045,
    ),
  ];

  /// Calcula o seguro para uma reserva.
  Future<InsuranceQuote> calculateInsurance({
    required BookingModel booking,
    required VehicleModel vehicle,
    required String coverageType,
    String partnerId = 'liberty',
  }) async {
    try {
      final partner = partners.firstWhere((p) => p.id == partnerId);
      final days = booking.endDate.difference(booking.startDate).inDays + 1;
      final vehicleValue = _estimateVehicleValue(vehicle);
      double basePremium = booking.totalPrice * partner.baseRate;

      double coverageMultiplier = 1.0;
      switch (coverageType) {
        case 'basic':
          coverageMultiplier = 1.0;
          break;
        case 'standard':
          coverageMultiplier = 1.5;
          break;
        case 'premium':
          coverageMultiplier = 2.0;
          break;
      }

      final premium = basePremium * coverageMultiplier;

      final quote = InsuranceQuote(
        id: _uuid.v4(),
        bookingId: booking.bookingId ?? '',
        vehicleId: vehicle.vehicleId!,
        partnerId: partnerId,
        partnerName: partner.name,
        coverageType: coverageType,
        coverageDetails: _getCoverageDetails(coverageType),
        vehicleValue: vehicleValue,
        dailyRate: premium / days,
        totalPremium: premium,
        deductible: _getDeductible(coverageType, vehicleValue),
        validUntil: DateTime.now().add(const Duration(hours: 24)),
        createdAt: DateTime.now(),
      );

      if (booking.bookingId != null && booking.bookingId!.isNotEmpty) {
        await _supabase.from('insurance_quotes').insert({
          'id': quote.id,
          'booking_id': quote.bookingId,
          'vehicle_id': quote.vehicleId,
          'partner_id': quote.partnerId,
          'partner_name': quote.partnerName,
          'coverage_type': quote.coverageType,
          'coverage_details': quote.coverageDetails,
          'vehicle_value': quote.vehicleValue,
          'daily_rate': quote.dailyRate,
          'total_premium': quote.totalPremium,
          'deductible': quote.deductible,
          'valid_until': quote.validUntil.toIso8601String(),
          'created_at': quote.createdAt.toIso8601String(),
        });
      }

      return quote;
    } catch (e) {
      throw Exception('Falha ao calcular seguro');
    }
  }

  /// Ativa o seguro para uma reserva.
  Future<InsurancePolicy> activateInsurance({
    required InsuranceQuote quote,
    required String paymentMethod,
    String? bookingId,
  }) async {
    try {
      if (quote.validUntil.isBefore(DateTime.now())) {
        throw Exception('Cotação expirada');
      }

      final effectiveBookingId = bookingId ?? quote.bookingId;

      if (effectiveBookingId.isEmpty) {
        throw Exception('ID da reserva inválido para ativar seguro');
      }

      await _supabase.from('insurance_quotes').upsert({
        'id': quote.id,
        'booking_id': effectiveBookingId,
        'vehicle_id': quote.vehicleId,
        'partner_id': quote.partnerId,
        'partner_name': quote.partnerName,
        'coverage_type': quote.coverageType,
        'coverage_details': quote.coverageDetails,
        'vehicle_value': quote.vehicleValue,
        'daily_rate': quote.dailyRate,
        'total_premium': quote.totalPremium,
        'deductible': quote.deductible,
        'valid_until': quote.validUntil.toIso8601String(),
        'created_at': quote.createdAt.toIso8601String(),
      });

      final policy = InsurancePolicy(
        policyNumber: _generatePolicyNumber(),
        quoteId: quote.id,
        bookingId: effectiveBookingId,
        vehicleId: quote.vehicleId,
        partnerId: quote.partnerId,
        partnerName: quote.partnerName,
        coverageType: quote.coverageType,
        coverageDetails: quote.coverageDetails,
        startDate: DateTime.now(),
        endDate: DateTime.now().add(const Duration(days: 30)),
        premium: quote.totalPremium,
        deductible: quote.deductible,
        status: 'active',
        paymentMethod: paymentMethod,
        paymentStatus: 'paid',
        createdAt: DateTime.now(),
      );

      await _supabase.from('insurance_policies').insert({
        'policy_number': policy.policyNumber,
        'quote_id': policy.quoteId,
        'booking_id': policy.bookingId,
        'vehicle_id': policy.vehicleId,
        'partner_id': policy.partnerId,
        'partner_name': policy.partnerName,
        'coverage_type': policy.coverageType,
        'coverage_details': policy.coverageDetails,
        'start_date': policy.startDate.toIso8601String(),
        'end_date': policy.endDate.toIso8601String(),
        'premium': policy.premium,
        'deductible': policy.deductible,
        'status': policy.status,
        'payment_method': policy.paymentMethod,
        'payment_status': policy.paymentStatus,
        'created_at': policy.createdAt.toIso8601String(),
      });

      await _supabase.from('bookings').update({
        'has_insurance': true,
        'insurance_policy_number': policy.policyNumber,
        'insurance_provider': policy.partnerName,
        'insurance_coverage_type': policy.coverageType,
      }).eq('id', effectiveBookingId);

      return policy;
    } catch (e) {
      throw Exception('Falha ao ativar seguro');
    }
  }

  /// Submete um sinistro.
  Future<InsuranceClaim> submitClaim({
    required String policyNumber,
    required String type,
    required String description,
    required List<String> photos,
    Map<String, dynamic>? additionalInfo,
  }) async {
    try {
      final policyData = await _supabase
          .from('insurance_policies')
          .select()
          .eq('policy_number', policyNumber)
          .maybeSingle();

      if (policyData == null) {
        throw Exception('Apólice não encontrada');
      }

      final policy = InsurancePolicy.fromMap(policyData);

      if (policy.status != 'active') {
        throw Exception('Apólice não está ativa');
      }

      final claim = InsuranceClaim(
        claimNumber: _generateClaimNumber(),
        policyNumber: policyNumber,
        type: type,
        description: description,
        photos: photos,
        status: 'submitted',
        estimatedAmount: 0,
        approvedAmount: null,
        deductible: policy.deductible,
        submittedAt: DateTime.now(),
        additionalInfo: additionalInfo ?? {},
      );

      await _supabase.from('insurance_claims').insert({
        'claim_number': claim.claimNumber,
        'policy_number': claim.policyNumber,
        'type': claim.type,
        'description': claim.description,
        'photos': claim.photos,
        'status': claim.status,
        'estimated_amount': claim.estimatedAmount,
        'approved_amount': claim.approvedAmount,
        'deductible': claim.deductible,
        'submitted_at': claim.submittedAt.toIso8601String(),
        'additional_info': claim.additionalInfo,
      });

      await _notifyPartnerOfClaim(policy.partnerId, claim);

      return claim;
    } catch (e) {
      throw Exception('Falha ao submeter claim');
    }
  }

  /// Obtém as apólices de um utilizador.
  Stream<List<InsurancePolicy>> getUserPolicies(String userId) {
    return _supabase
        .from('bookings')
        .stream(primaryKey: ['id']).asyncMap((bookings) async {
      List<InsurancePolicy> policies = [];

      final userBookings = bookings.where((booking) =>
          booking['renter_id'] == userId && booking['has_insurance'] == true);

      for (var booking in userBookings) {
        final policyNumber = booking['insurance_policy_number'];
        if (policyNumber != null) {
          final policyData = await _supabase
              .from('insurance_policies')
              .select()
              .eq('policy_number', policyNumber)
              .maybeSingle();

          if (policyData != null) {
            policies.add(InsurancePolicy.fromMap(policyData));
          }
        }
      }

      return policies;
    });
  }

  /// Obtém os sinistros de um utilizador.
  Stream<List<InsuranceClaim>> getUserClaims(String userId) {
    return _supabase
        .from('insurance_policies')
        .stream(primaryKey: ['policy_number']).asyncMap((policies) async {
      List<InsuranceClaim> claims = [];

      for (var policy in policies) {
        final bookingId = policy['booking_id'];

        final booking = await _supabase
            .from('bookings')
            .select('renter_id')
            .eq('id', bookingId)
            .maybeSingle();

        if (booking != null && booking['renter_id'] == userId) {
          final claimsData = await _supabase
              .from('insurance_claims')
              .select()
              .eq('policy_number', policy['policy_number']);

          claims.addAll(
            claimsData.map((data) => InsuranceClaim.fromMap(data)),
          );
        }
      }

      return claims;
    });
  }

  double _estimateVehicleValue(VehicleModel vehicle) {
    double baseValue = 20000;

    switch (vehicle.category) {
      case 'classic':
        baseValue = 30000;
        break;
      case 'vintage':
        baseValue = 40000;
        break;
      case 'luxury':
        baseValue = 50000;
        break;
    }

    final age = DateTime.now().year - vehicle.year;
    if (age > 30) {
      baseValue *= 1.5;
    } else if (age > 20) {
      baseValue *= 1.2;
    }

    return baseValue;
  }

  Map<String, dynamic> _getCoverageDetails(String coverageType) {
    switch (coverageType) {
      case 'basic':
        return {
          'liability': true,
          'collision': false,
          'comprehensive': false,
          'personalInjury': false,
          'roadsideAssistance': false,
          'maxCoverage': 50000,
        };
      case 'standard':
        return {
          'liability': true,
          'collision': true,
          'comprehensive': false,
          'personalInjury': true,
          'roadsideAssistance': true,
          'maxCoverage': 100000,
        };
      case 'premium':
        return {
          'liability': true,
          'collision': true,
          'comprehensive': true,
          'personalInjury': true,
          'roadsideAssistance': true,
          'replacementVehicle': true,
          'maxCoverage': 250000,
        };
      default:
        return {};
    }
  }

  double _getDeductible(String coverageType, double vehicleValue) {
    switch (coverageType) {
      case 'basic':
        return vehicleValue * 0.10;
      case 'standard':
        return vehicleValue * 0.05;
      case 'premium':
        return vehicleValue * 0.02;
      default:
        return 0;
    }
  }

  String _generatePolicyNumber() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    return 'POL-${timestamp.toString().substring(6)}';
  }

  String _generateClaimNumber() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    return 'CLM-${timestamp.toString().substring(6)}';
  }

  Future<void> _notifyPartnerOfClaim(
      String partnerId, InsuranceClaim claim) async {
    await _supabase.from('partner_notifications').insert({
      'partner_id': partnerId,
      'type': 'new_claim',
      'claim_number': claim.claimNumber,
      'message': 'Novo sinistro submetido',
    });
  }
}

/// Modelo de parceiro de seguro.
class InsurancePartner {
  final String id;
  final String name;
  final String logo;
  final double baseRate;

  const InsurancePartner({
    required this.id,
    required this.name,
    required this.logo,
    required this.baseRate,
  });
}
