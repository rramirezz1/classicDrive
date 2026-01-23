import 'package:flutter_test/flutter_test.dart';
import 'package:classic_drive/models/booking_model.dart';

void main() {
  group('BookingModel', () {
    test('should create from map correctly', () {
      final map = {
        'id': 'booking-123',
        'vehicle_id': 'vehicle-456',
        'renter_id': 'renter-789',
        'owner_id': 'owner-012',
        'start_date': '2024-07-01T00:00:00.000Z',
        'end_date': '2024-07-05T00:00:00.000Z',
        'event_type': 'casamento',
        'total_price': 1000.0,
        'status': 'confirmed',
        'payment': {'method': 'card', 'status': 'paid', 'transaction_id': 'txn-123'},
        'special_requests': 'Decoração incluída',
        'created_at': '2024-06-01T00:00:00.000Z',
      };

      final booking = BookingModel.fromMap(map);

      expect(booking.bookingId, 'booking-123');
      expect(booking.vehicleId, 'vehicle-456');
      expect(booking.renterId, 'renter-789');
      expect(booking.ownerId, 'owner-012');
      expect(booking.eventType, 'casamento');
      expect(booking.totalPrice, 1000.0);
      expect(booking.status, 'confirmed');
      expect(booking.specialRequests, 'Decoração incluída');
    });

    test('numberOfDays should calculate correctly', () {
      final booking = BookingModel(
        vehicleId: 'v1',
        renterId: 'r1',
        ownerId: 'o1',
        startDate: DateTime(2024, 7, 1),
        endDate: DateTime(2024, 7, 5),
        eventType: 'evento',
        totalPrice: 500.0,
        status: 'pending',
        payment: PaymentInfo(method: 'card', status: 'pending'),
        createdAt: DateTime.now(),
      );

      expect(booking.numberOfDays, 5);
    });

    test('canBeCancelled should return true for pending bookings', () {
      final pendingBooking = BookingModel(
        vehicleId: 'v1',
        renterId: 'r1',
        ownerId: 'o1',
        startDate: DateTime.now().add(const Duration(days: 7)),
        endDate: DateTime.now().add(const Duration(days: 10)),
        eventType: 'evento',
        totalPrice: 500.0,
        status: 'pending',
        payment: PaymentInfo(method: 'card', status: 'pending'),
        createdAt: DateTime.now(),
      );

      expect(pendingBooking.canBeCancelled, true);
    });

    test('canBeCancelled should return true for confirmed future bookings', () {
      final confirmedFuture = BookingModel(
        vehicleId: 'v1',
        renterId: 'r1',
        ownerId: 'o1',
        startDate: DateTime.now().add(const Duration(days: 7)),
        endDate: DateTime.now().add(const Duration(days: 10)),
        eventType: 'evento',
        totalPrice: 500.0,
        status: 'confirmed',
        payment: PaymentInfo(method: 'card', status: 'paid'),
        createdAt: DateTime.now(),
      );

      expect(confirmedFuture.canBeCancelled, true);
    });

    test('canBeCancelled should return false for completed bookings', () {
      final completed = BookingModel(
        vehicleId: 'v1',
        renterId: 'r1',
        ownerId: 'o1',
        startDate: DateTime.now().subtract(const Duration(days: 10)),
        endDate: DateTime.now().subtract(const Duration(days: 5)),
        eventType: 'evento',
        totalPrice: 500.0,
        status: 'completed',
        payment: PaymentInfo(method: 'card', status: 'paid'),
        createdAt: DateTime.now().subtract(const Duration(days: 15)),
      );

      expect(completed.canBeCancelled, false);
    });

    test('toMap should convert correctly', () {
      final booking = BookingModel(
        vehicleId: 'v1',
        renterId: 'r1',
        ownerId: 'o1',
        startDate: DateTime(2024, 7, 1),
        endDate: DateTime(2024, 7, 3),
        eventType: 'casamento',
        totalPrice: 600.0,
        status: 'pending',
        payment: PaymentInfo(method: 'card', status: 'pending'),
        specialRequests: 'Nota especial',
        createdAt: DateTime(2024, 6, 1),
      );

      final map = booking.toMap();

      expect(map['vehicle_id'], 'v1');
      expect(map['event_type'], 'casamento');
      expect(map['total_price'], 600.0);
      expect(map['special_requests'], 'Nota especial');
    });
  });

  group('PaymentInfo', () {
    test('should create from map correctly', () {
      final map = {
        'method': 'card',
        'status': 'paid',
        'transaction_id': 'txn-456',
      };

      final payment = PaymentInfo.fromMap(map);

      expect(payment.method, 'card');
      expect(payment.status, 'paid');
      expect(payment.transactionId, 'txn-456');
    });

    test('should handle empty map with defaults', () {
      final payment = PaymentInfo.fromMap({});

      expect(payment.method, 'card');
      expect(payment.status, 'pending');
      expect(payment.transactionId, isNull);
    });
  });
}
