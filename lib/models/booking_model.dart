import 'package:cloud_firestore/cloud_firestore.dart';

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

  factory BookingModel.fromMap(Map<String, dynamic> map, String id) {
    return BookingModel(
      bookingId: id,
      vehicleId: map['vehicleId'] ?? '',
      renterId: map['renterId'] ?? '',
      ownerId: map['ownerId'] ?? '',
      startDate: (map['startDate'] as Timestamp).toDate(),
      endDate: (map['endDate'] as Timestamp).toDate(),
      eventType: map['eventType'] ?? '',
      totalPrice: (map['totalPrice'] ?? 0).toDouble(),
      status: map['status'] ?? 'pending',
      payment: PaymentInfo.fromMap(map['payment'] ?? {}),
      specialRequests: map['specialRequests'],
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      updatedAt: map['updatedAt'] != null
          ? (map['updatedAt'] as Timestamp).toDate()
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'vehicleId': vehicleId,
      'renterId': renterId,
      'ownerId': ownerId,
      'startDate': Timestamp.fromDate(startDate),
      'endDate': Timestamp.fromDate(endDate),
      'eventType': eventType,
      'totalPrice': totalPrice,
      'status': status,
      'payment': payment.toMap(),
      'specialRequests': specialRequests,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
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
      transactionId: map['transactionId'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'method': method,
      'status': status,
      'transactionId': transactionId,
    };
  }
}
