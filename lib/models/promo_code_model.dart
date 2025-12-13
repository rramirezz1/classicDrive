/// Modelo de código promocional.

enum PromoType { percentage, fixedAmount, freeDays }

class PromoCodeModel {
  final String? codeId;
  final String code;
  final PromoType type;
  final double value;
  final String? description;
  final DateTime? validFrom;
  final DateTime? validUntil;
  final int? maxUses;
  final int usedCount;
  final double? minBookingValue;
  final bool isActive;
  final String? createdBy;
  final DateTime createdAt;

  PromoCodeModel({
    this.codeId,
    required this.code,
    required this.type,
    required this.value,
    this.description,
    this.validFrom,
    this.validUntil,
    this.maxUses,
    this.usedCount = 0,
    this.minBookingValue,
    this.isActive = true,
    this.createdBy,
    required this.createdAt,
  });

  /// Verifica se o código é válido.
  bool get isValid {
    final now = DateTime.now();
    
    if (!isActive) return false;
    if (validFrom != null && now.isBefore(validFrom!)) return false;
    if (validUntil != null && now.isAfter(validUntil!)) return false;
    if (maxUses != null && usedCount >= maxUses!) return false;
    
    return true;
  }

  /// Calcula o desconto para um valor de reserva.
  double calculateDiscount(double bookingValue) {
    if (!isValid) return 0;
    if (minBookingValue != null && bookingValue < minBookingValue!) return 0;

    switch (type) {
      case PromoType.percentage:
        return bookingValue * (value / 100);
      case PromoType.fixedAmount:
        return value.clamp(0, bookingValue);
      case PromoType.freeDays:
        return 0; // Handled separately
    }
  }

  /// Nome do tipo em português.
  String get typeName {
    switch (type) {
      case PromoType.percentage:
        return 'Percentagem';
      case PromoType.fixedAmount:
        return 'Valor fixo';
      case PromoType.freeDays:
        return 'Dias grátis';
    }
  }

  /// Descrição do desconto.
  String get discountDescription {
    switch (type) {
      case PromoType.percentage:
        return '${value.toInt()}% de desconto';
      case PromoType.fixedAmount:
        return '€${value.toStringAsFixed(0)} de desconto';
      case PromoType.freeDays:
        return '${value.toInt()} dia(s) grátis';
    }
  }

  factory PromoCodeModel.fromMap(Map<String, dynamic> map) {
    return PromoCodeModel(
      codeId: map['id'],
      code: map['code'] ?? '',
      type: _parseType(map['type']),
      value: (map['value'] ?? 0).toDouble(),
      description: map['description'],
      validFrom: map['valid_from'] != null
          ? DateTime.parse(map['valid_from'])
          : null,
      validUntil: map['valid_until'] != null
          ? DateTime.parse(map['valid_until'])
          : null,
      maxUses: map['max_uses'],
      usedCount: map['used_count'] ?? 0,
      minBookingValue: map['min_booking_value']?.toDouble(),
      isActive: map['is_active'] ?? true,
      createdBy: map['created_by'],
      createdAt: map['created_at'] != null
          ? DateTime.parse(map['created_at'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'code': code.toUpperCase(),
      'type': type.name,
      'value': value,
      'description': description,
      'valid_from': validFrom?.toIso8601String(),
      'valid_until': validUntil?.toIso8601String(),
      'max_uses': maxUses,
      'used_count': usedCount,
      'min_booking_value': minBookingValue,
      'is_active': isActive,
      'created_by': createdBy,
      'created_at': createdAt.toIso8601String(),
    };
  }

  static PromoType _parseType(String? type) {
    switch (type) {
      case 'percentage':
        return PromoType.percentage;
      case 'fixedAmount':
        return PromoType.fixedAmount;
      case 'freeDays':
        return PromoType.freeDays;
      default:
        return PromoType.percentage;
    }
  }
}
