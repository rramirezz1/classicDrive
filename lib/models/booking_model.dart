/// Modelo de reserva de veículo.
class BookingModel {
  final String? bookingId;
  final String vehicleId;
  final String renterId;
  final String ownerId;
  final DateTime startDate;
  final DateTime endDate;
  final String eventType;
  final double totalPrice;
  final String status;
  final PaymentInfo payment;
  final String? specialRequests;
  final DateTime createdAt;
  final DateTime? updatedAt;

  BookingModel({
    this.bookingId,
    required this.vehicleId,
    required this.renterId,
    required this.ownerId,
    required this.startDate,
    required this.endDate,
    required this.eventType,
    required this.totalPrice,
    required this.status,
    required this.payment,
    this.specialRequests,
    required this.createdAt,
    this.updatedAt,
  });

  /// Cria um BookingModel a partir de um Map da base de dados.
  factory BookingModel.fromMap(Map<String, dynamic> map) {
    return BookingModel(
      bookingId: map['id'],
      vehicleId: map['vehicle_id'] ?? '',
      renterId: map['renter_id'] ?? '',
      ownerId: map['owner_id'] ?? '',
      startDate: DateTime.parse(map['start_date']),
      endDate: DateTime.parse(map['end_date']),
      eventType: map['event_type'] ?? '',
      totalPrice: (map['total_price'] ?? 0).toDouble(),
      status: map['status'] ?? 'pending',
      payment: PaymentInfo.fromMap(map['payment'] ?? {}),
      specialRequests: map['special_requests'],
      createdAt: map['created_at'] != null
          ? DateTime.parse(map['created_at'])
          : DateTime.now(),
      updatedAt: map['updated_at'] != null
          ? DateTime.parse(map['updated_at'])
          : null,
    );
  }

  /// Converte o modelo para Map para guardar na base de dados.
  Map<String, dynamic> toMap() {
    return {
      'vehicle_id': vehicleId,
      'renter_id': renterId,
      'owner_id': ownerId,
      'start_date': startDate.toIso8601String(),
      'end_date': endDate.toIso8601String(),
      'event_type': eventType,
      'total_price': totalPrice,
      'status': status,
      'payment': payment.toMap(),
      'special_requests': specialRequests,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  int get numberOfDays {
    return endDate.difference(startDate).inDays + 1;
  }

  bool get canBeCancelled {
    return status == 'pending' ||
        (status == 'confirmed' && startDate.isAfter(DateTime.now()));
  }
}

/// Informação de pagamento de uma reserva.
class PaymentInfo {
  final String method;
  final String status;
  final String? transactionId;

  PaymentInfo({
    required this.method,
    required this.status,
    this.transactionId,
  });

  factory PaymentInfo.fromMap(Map<String, dynamic> map) {
    return PaymentInfo(
      method: map['method'] ?? 'card',
      status: map['status'] ?? 'pending',
      transactionId: map['transaction_id'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'method': method,
      'status': status,
      'transaction_id': transactionId,
    };
  }
}
