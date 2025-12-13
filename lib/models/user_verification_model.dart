/// Modelo de verificação de utilizador.

enum VerificationType { email, phone, document, address }

class UserVerification {
  final String oderId;
  final bool emailVerified;
  final bool phoneVerified;
  final bool documentVerified;
  final bool addressVerified;
  final DateTime? emailVerifiedAt;
  final DateTime? phoneVerifiedAt;
  final DateTime? documentVerifiedAt;
  final DateTime? addressVerifiedAt;
  final String? documentType;
  final String? documentStatus;

  UserVerification({
    required this.oderId,
    this.emailVerified = false,
    this.phoneVerified = false,
    this.documentVerified = false,
    this.addressVerified = false,
    this.emailVerifiedAt,
    this.phoneVerifiedAt,
    this.documentVerifiedAt,
    this.addressVerifiedAt,
    this.documentType,
    this.documentStatus,
  });

  /// Nível de verificação (0-4).
  int get verificationLevel {
    int level = 0;
    if (emailVerified) level++;
    if (phoneVerified) level++;
    if (documentVerified) level++;
    if (addressVerified) level++;
    return level;
  }

  /// Percentagem de verificação.
  double get verificationPercentage => verificationLevel / 4;

  /// Status textual.
  String get verificationStatus {
    switch (verificationLevel) {
      case 0:
        return 'Não verificado';
      case 1:
        return 'Básico';
      case 2:
        return 'Verificado';
      case 3:
        return 'Avançado';
      case 4:
        return 'Totalmente verificado';
      default:
        return 'Desconhecido';
    }
  }

  /// Verifica se tem verificação mínima (email + telefone).
  bool get hasMinimumVerification => emailVerified && phoneVerified;

  /// Verifica se é proprietário verificado (documento também).
  bool get isVerifiedOwner => hasMinimumVerification && documentVerified;

  factory UserVerification.fromMap(Map<String, dynamic> map) {
    return UserVerification(
      oderId: map['user_id'] ?? '',
      emailVerified: map['email_verified'] ?? false,
      phoneVerified: map['phone_verified'] ?? false,
      documentVerified: map['document_verified'] ?? false,
      addressVerified: map['address_verified'] ?? false,
      emailVerifiedAt: map['email_verified_at'] != null
          ? DateTime.parse(map['email_verified_at'])
          : null,
      phoneVerifiedAt: map['phone_verified_at'] != null
          ? DateTime.parse(map['phone_verified_at'])
          : null,
      documentVerifiedAt: map['document_verified_at'] != null
          ? DateTime.parse(map['document_verified_at'])
          : null,
      addressVerifiedAt: map['address_verified_at'] != null
          ? DateTime.parse(map['address_verified_at'])
          : null,
      documentType: map['document_type'],
      documentStatus: map['document_status'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'user_id': oderId,
      'email_verified': emailVerified,
      'phone_verified': phoneVerified,
      'document_verified': documentVerified,
      'address_verified': addressVerified,
      'email_verified_at': emailVerifiedAt?.toIso8601String(),
      'phone_verified_at': phoneVerifiedAt?.toIso8601String(),
      'document_verified_at': documentVerifiedAt?.toIso8601String(),
      'address_verified_at': addressVerifiedAt?.toIso8601String(),
      'document_type': documentType,
      'document_status': documentStatus,
    };
  }

  UserVerification copyWith({
    bool? emailVerified,
    bool? phoneVerified,
    bool? documentVerified,
    bool? addressVerified,
    DateTime? emailVerifiedAt,
    DateTime? phoneVerifiedAt,
    DateTime? documentVerifiedAt,
    DateTime? addressVerifiedAt,
  }) {
    return UserVerification(
      oderId: oderId,
      emailVerified: emailVerified ?? this.emailVerified,
      phoneVerified: phoneVerified ?? this.phoneVerified,
      documentVerified: documentVerified ?? this.documentVerified,
      addressVerified: addressVerified ?? this.addressVerified,
      emailVerifiedAt: emailVerifiedAt ?? this.emailVerifiedAt,
      phoneVerifiedAt: phoneVerifiedAt ?? this.phoneVerifiedAt,
      documentVerifiedAt: documentVerifiedAt ?? this.documentVerifiedAt,
      addressVerifiedAt: addressVerifiedAt ?? this.addressVerifiedAt,
      documentType: documentType,
      documentStatus: documentStatus,
    );
  }
}
