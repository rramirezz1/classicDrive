import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/insurance_model.dart';
import '../models/booking_model.dart';
import '../models/vehicle_model.dart';

class InsuranceService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Parceiros de seguro (simulado)
  static const List<InsurancePartner> partners = [
    InsurancePartner(
      id: 'liberty',
      name: 'Liberty Seguros',
      logo: 'assets/images/liberty_logo.png',
      baseRate: 0.05, // 5% do valor do aluguer
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

  // Calcular seguro para uma reserva
  Future<InsuranceQuote> calculateInsurance({
    required BookingModel booking,
    required VehicleModel vehicle,
    required String coverageType,
    String partnerId = 'liberty',
  }) async {
    try {
      // Obter parceiro
      final partner = partners.firstWhere((p) => p.id == partnerId);

      // Calcular número de dias
      final days = booking.endDate.difference(booking.startDate).inDays + 1;

      // Valor base do veículo (estimado)
      final vehicleValue = _estimateVehicleValue(vehicle);

      // Calcular prémio base
      double basePremium = booking.totalPrice * partner.baseRate;

      // Ajustar por tipo de cobertura
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

      // Criar quote
      final quote = InsuranceQuote(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        bookingId: booking.bookingId!,
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

      // Salvar quote
      await _firestore
          .collection('insurance_quotes')
          .doc(quote.id)
          .set(quote.toMap());

      return quote;
    } catch (e) {
      print('Erro ao calcular seguro: $e');
      throw Exception('Falha ao calcular seguro');
    }
  }

  // Ativar seguro
  Future<InsurancePolicy> activateInsurance({
    required InsuranceQuote quote,
    required String paymentMethod,
  }) async {
    try {
      // Verificar se quote ainda é válida
      if (quote.validUntil.isBefore(DateTime.now())) {
        throw Exception('Cotação expirada');
      }

      // Criar apólice
      final policy = InsurancePolicy(
        policyNumber: _generatePolicyNumber(),
        quoteId: quote.id,
        bookingId: quote.bookingId,
        vehicleId: quote.vehicleId,
        partnerId: quote.partnerId,
        partnerName: quote.partnerName,
        coverageType: quote.coverageType,
        coverageDetails: quote.coverageDetails,
        startDate: DateTime.now(),
        endDate: DateTime.now()
            .add(const Duration(days: 30)), // Ajustar conforme reserva
        premium: quote.totalPremium,
        deductible: quote.deductible,
        status: 'active',
        paymentMethod: paymentMethod,
        paymentStatus: 'paid',
        createdAt: DateTime.now(),
      );

      // Salvar apólice
      await _firestore
          .collection('insurance_policies')
          .doc(policy.policyNumber)
          .set(policy.toMap());

      // Atualizar reserva
      await _firestore.collection('bookings').doc(quote.bookingId).update({
        'insurance': {
          'hasInsurance': true,
          'policyNumber': policy.policyNumber,
          'provider': policy.partnerName,
          'coverageType': policy.coverageType,
        },
      });

      return policy;
    } catch (e) {
      print('Erro ao ativar seguro: $e');
      throw Exception('Falha ao ativar seguro');
    }
  }

  // Submeter claim
  Future<InsuranceClaim> submitClaim({
    required String policyNumber,
    required String type,
    required String description,
    required List<String> photos,
    Map<String, dynamic>? additionalInfo,
  }) async {
    try {
      // Obter apólice
      final policyDoc = await _firestore
          .collection('insurance_policies')
          .doc(policyNumber)
          .get();

      if (!policyDoc.exists) {
        throw Exception('Apólice não encontrada');
      }

      final policy = InsurancePolicy.fromMap(policyDoc.data()!);

      // Verificar se apólice está ativa
      if (policy.status != 'active') {
        throw Exception('Apólice não está ativa');
      }

      // Criar claim
      final claim = InsuranceClaim(
        claimNumber: _generateClaimNumber(),
        policyNumber: policyNumber,
        type: type,
        description: description,
        photos: photos,
        status: 'submitted',
        estimatedAmount: 0, // Será calculado após análise
        approvedAmount: null,
        deductible: policy.deductible,
        submittedAt: DateTime.now(),
        additionalInfo: additionalInfo ?? {},
      );

      // Salvar claim
      await _firestore
          .collection('insurance_claims')
          .doc(claim.claimNumber)
          .set(claim.toMap());

      // Notificar parceiro
      await _notifyPartnerOfClaim(policy.partnerId, claim);

      return claim;
    } catch (e) {
      print('Erro ao submeter claim: $e');
      throw Exception('Falha ao submeter claim');
    }
  }

  // Obter apólices do utilizador
  Stream<List<InsurancePolicy>> getUserPolicies(String userId) {
    return _firestore
        .collection('bookings')
        .where('renterId', isEqualTo: userId)
        .where('insurance.hasInsurance', isEqualTo: true)
        .snapshots()
        .asyncMap((bookingSnapshot) async {
      List<InsurancePolicy> policies = [];

      for (var bookingDoc in bookingSnapshot.docs) {
        final insuranceData = bookingDoc.data()['insurance'];
        if (insuranceData != null && insuranceData['policyNumber'] != null) {
          final policyDoc = await _firestore
              .collection('insurance_policies')
              .doc(insuranceData['policyNumber'])
              .get();

          if (policyDoc.exists) {
            policies.add(InsurancePolicy.fromMap(policyDoc.data()!));
          }
        }
      }

      return policies;
    });
  }

  // Obter claims do utilizador
  Stream<List<InsuranceClaim>> getUserClaims(String userId) {
    return _firestore
        .collection('insurance_policies')
        .where('userId', isEqualTo: userId)
        .snapshots()
        .asyncMap((policySnapshot) async {
      List<InsuranceClaim> claims = [];

      for (var policyDoc in policySnapshot.docs) {
        final claimsSnapshot = await _firestore
            .collection('insurance_claims')
            .where('policyNumber', isEqualTo: policyDoc.id)
            .get();

        claims.addAll(
          claimsSnapshot.docs.map((doc) => InsuranceClaim.fromMap(doc.data())),
        );
      }

      return claims;
    });
  }

  // Métodos auxiliares
  double _estimateVehicleValue(VehicleModel vehicle) {
    // Estimativa baseada no ano e categoria
    double baseValue = 20000;

    // Ajustar por categoria
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

    // Ajustar por idade (carros clássicos podem valorizar)
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
        return vehicleValue * 0.10; // 10% do valor
      case 'standard':
        return vehicleValue * 0.05; // 5% do valor
      case 'premium':
        return vehicleValue * 0.02; // 2% do valor
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
    
    await _firestore.collection('partner_notifications').add({
      'partnerId': partnerId,
      'type': 'new_claim',
      'claimNumber': claim.claimNumber,
      'message': 'Novo sinistro submetido',
      'createdAt': FieldValue.serverTimestamp(),
    });
  }
}

// Modelo de parceiro de seguro
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
