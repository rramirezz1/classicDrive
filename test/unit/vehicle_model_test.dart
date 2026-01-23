import 'package:flutter_test/flutter_test.dart';
import 'package:classic_drive/models/vehicle_model.dart';

void main() {
  group('VehicleModel', () {
    test('should create from map correctly', () {
      final map = {
        'id': 'vehicle-123',
        'owner_id': 'owner-456',
        'brand': 'Mercedes-Benz',
        'model': '300SL',
        'year': 1955,
        'category': 'classic',
        'event_types': ['casamento', 'evento'],
        'description': 'Um clássico atemporal',
        'features': ['Interior em couro', 'Motor original'],
        'images': ['https://example.com/image.jpg'],
        'price_per_day': 250.0,
        'location': {'city': 'Lisboa', 'latitude': 38.7223, 'longitude': -9.1393},
        'availability': {'is_available': true, 'blocked_dates': []},
        'validation': {'status': 'approved'},
        'stats': {'total_bookings': 10, 'rating': 4.8, 'views': 100, 'total_reviews': 5},
        'created_at': '2024-01-01T00:00:00.000Z',
        'transmission': 'Manual',
        'seats': 2,
        'engine_type': 'Gasolina',
      };

      final vehicle = VehicleModel.fromMap(map);

      expect(vehicle.vehicleId, 'vehicle-123');
      expect(vehicle.ownerId, 'owner-456');
      expect(vehicle.brand, 'Mercedes-Benz');
      expect(vehicle.model, '300SL');
      expect(vehicle.year, 1955);
      expect(vehicle.category, 'classic');
      expect(vehicle.pricePerDay, 250.0);
      expect(vehicle.transmission, 'Manual');
      expect(vehicle.seats, 2);
      expect(vehicle.isAvailable, true);
      expect(vehicle.isApproved, true);
    });

    test('fullName should return formatted string', () {
      final vehicle = VehicleModel(
        ownerId: 'owner-1',
        brand: 'Porsche',
        model: '911',
        year: 1973,
        category: 'classic',
        eventTypes: [],
        description: 'Test',
        features: [],
        images: [],
        pricePerDay: 300.0,
        location: {},
        availability: {'is_available': true},
        validation: ValidationStatus(status: 'pending'),
        stats: VehicleStats(totalBookings: 0, rating: 0, views: 0),
        createdAt: DateTime.now(),
      );

      expect(vehicle.fullName, 'Porsche 911 (1973)');
    });

    test('isApproved should return correct status', () {
      final approved = ValidationStatus(status: 'approved');
      final pending = ValidationStatus(status: 'pending');

      expect(approved.status, 'approved');
      expect(pending.status, 'pending');
    });

    test('toMap should convert correctly', () {
      final vehicle = VehicleModel(
        ownerId: 'owner-1',
        brand: 'Ferrari',
        model: '250 GTO',
        year: 1962,
        category: 'exotic',
        eventTypes: ['evento'],
        description: 'Lendário',
        features: ['Motor V12'],
        images: [],
        pricePerDay: 500.0,
        location: {'city': 'Porto'},
        availability: {'is_available': true},
        validation: ValidationStatus(status: 'approved'),
        stats: VehicleStats(totalBookings: 5, rating: 5.0, views: 50),
        createdAt: DateTime(2024, 1, 1),
      );

      final map = vehicle.toMap();

      expect(map['brand'], 'Ferrari');
      expect(map['model'], '250 GTO');
      expect(map['year'], 1962);
      expect(map['price_per_day'], 500.0);
      expect(map['validation_status'], 'approved');
    });
  });

  group('VehicleStats', () {
    test('should create from map correctly', () {
      final map = {
        'total_bookings': 15,
        'rating': 4.5,
        'views': 200,
        'total_reviews': 8,
      };

      final stats = VehicleStats.fromMap(map);

      expect(stats.totalBookings, 15);
      expect(stats.rating, 4.5);
      expect(stats.views, 200);
      expect(stats.totalReviews, 8);
    });

    test('should handle empty map with defaults', () {
      final stats = VehicleStats.fromMap({});

      expect(stats.totalBookings, 0);
      expect(stats.rating, 0.0);
      expect(stats.views, 0);
    });
  });

  group('ValidationStatus', () {
    test('should create from map correctly', () {
      final map = {
        'status': 'approved',
        'validated_at': '2024-06-15T10:30:00.000Z',
        'validated_by': 'admin-1',
      };

      final validation = ValidationStatus.fromMap(map);

      expect(validation.status, 'approved');
      expect(validation.validatedBy, 'admin-1');
      expect(validation.validatedAt, isNotNull);
    });

    test('should default to pending status', () {
      final validation = ValidationStatus.fromMap({});

      expect(validation.status, 'pending');
    });
  });
}
